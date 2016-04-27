require 'bodepd/simple/installer'
require 'bodepd/simple/iterator'
require 'fileutils'

module Bodepd
    module Simple
      class CLI < Thor

        include Bodepd::Simple::Util
        include Bodepd::Simple::Installer
        include Bodepd::Simple::Iterator

        class_option :verbose, :type => :boolean,
                     :desc => 'verbose output for executed commands'

        class_option :path, :type => :string,
                     :desc => "overrides target directory, default is ./modules"
        class_option :depfile, :type => :string,
                     :desc => "overrides used Depfile",
                     :default => './Depfile'


        def self.bin!
          start
        end

        desc 'install', 'installs all git sources from your Depfile'
        method_option :clean, :type => :boolean, :desc => "calls clean before executing install"
        def install
          @verbose = options[:verbose]
          clean if options[:clean]
          @custom_module_path = options[:path]
          # evaluate the file to populate @modules
          eval(File.read(File.expand_path(options[:depfile])))
          install!
        end

        desc 'update', 'updates all git sources from your Depfile'
        method_option :update, :type => :boolean, :desc => "Updates git sources"
        def update
          @verbose = options[:verbose]
          @custom_module_path = options[:path]
          eval(File.read(File.expand_path(options[:depfile])))
          each_module_of_type(:git) do |repo|
            if Dir.exists?(File.join(module_path, repo[:name]))
              Dir.chdir(File.join(module_path, repo[:name])) do
                remote = repo[:git]
                # if no ref is given, assume master
                branch = repo[:ref] || 'master'
                if branch =~ /^origin\/(.*)$/
                  branch = $1
                end
                co_cmd     = 'git checkout FETCH_HEAD'
                update_cmd = "git fetch #{repo[:git]} #{branch} && #{co_cmd}"
                print_verbose "\n\n#{repo[:name]} -- #{update_cmd}"
                git_pull_cmd = system_cmd(update_cmd)
              end
            else
              install_git module_path, repo[:name], repo[:git], repo[:ref]
            end
          end
        end

        desc 'clean', 'clean modules directory'
        def clean
          target_directory = options[:path] || File.expand_path("./modules")
          puts "Target Directory: #{target_directory}" if options[:verbose]
          FileUtils.rm_rf target_directory
        end

        desc 'git_status', 'determine the current status of checked out git repos'
        def git_status
          @custom_module_path = options[:path]
          # populate @modules
          eval(File.read(File.expand_path(options[:depfile])))
          each_module_of_type(:git) do |repo|
            Dir.chdir(File.join(module_path, repo[:name])) do
              status = system_cmd('git status')
              if status.include?('nothing to commit (working directory clean)')
                puts "Module #{repo[:name]} has not changed" if options[:verbose]
              else
                puts "Uncommitted changes for: #{repo[:name]}"
                puts "  #{status.join("\n  ")}"
              end
            end
          end
        end

        desc 'dev_setup', 'adds development r/w remotes to each repo (assumes remote has the same name as current repo)'
        def dev_setup(remote_name)
          @custom_module_path = options[:path]
          # populate @modules
          eval(File.read(File.expand_path(options[:depfile])))
          each_module_of_type(:git) do |repo|
            Dir.chdir(File.join((options[:path] || 'modules'), repo[:name])) do
              print_verbose "Adding development remote for git repo #{repo[:name]}"
              remotes = system_cmd('git remote')
              if remotes.include?(remote_name)
                puts "Did not have to add remote #{remote_name} to #{repo[:name]}"
              elsif ! remotes.include?('origin')
                raise(TestException, "Repo #{repo[:name]} has no remote called origin, failing")
              else
                remote_url = system_cmd('git remote show origin').detect {|x| x =~ /\s+Push\s+URL: / }
                if remote_url =~ /(git|https?):\/\/(.+)\/(.+)?\/(.+)/
                  url = "git@#{$2}:#{remote_name}/#{$4}"
                  puts "Adding remote #{remote_name} as #{url}"
                  system_cmd("git remote add #{remote_name} #{url}")
                elsif remote_url =~ /^git@/
                  puts "Origin is already a read/write remote, skipping b/c this is unexpected"
                else
                  puts "remote_url #{remote_url} did not have the expected format. weird..."
                end
              end
            end
          end
        end

        desc 'generate_depfile', 'generates a static version of the Depfile'
        method_option :out_file,
          :desc => 'output file where static depfile should be written to'
        def generate_depfile
          eval(File.read(File.expand_path(options[:depfile])))
          if options[:out_file]
            File.open(options[:out_file], 'w') do |fh|
              print_puppet_file(fh)
            end
          else
            print_puppet_file(STDOUT)
          end
        end

        private

          def print_dep_file(stream)
            each_module do |repo|
              repo.delete(:name)
              out_str = repo.delete(:full_name)
              repo.each do |k,v|
                out_str << ", :#{k} => #{v}"
              end
              stream.puts(out_str)
            end
          end

          # builds out a certain type of repo
          def build_depfile(name, perform_installation=false)
            repo_hash = {}
            # set environment variable to determine what version of modules to install
            # this assumes that the environment variable repos_to_use has been coded in
            # your Depfile to allow installation of different versions of modules
            ENV['repos_to_use'] = name
            # parse Depfile and install modules in our tmp directory.
            eval(File.read(File.expand_path(options[:depfile])))
            # install modules if desired
            install! if perform_installation

            # iterate through all git modules
            each_module_of_type(:git) do |git_repo|
              abort("Module git_repo[:name] was defined multiple times in same Depfile") if repo_hash[git_repo[:name]]
              repo_hash[git_repo[:name]] = git_repo
            end
            # clear out the modules once finished
            clear_modules
            repo_hash
          end

      end
    end
end
