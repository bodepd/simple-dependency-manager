# simple-dependency-manager

Simple-dependency-manager allows you to speify a list of `modules` that are
dependency of your software projects. These modules are stored in a Depfile
that allows you to specify what to install (via a git repo and revision) and
where it should be installed.

It is intended to be tooling agnostic, and can be used to install anything.

# Usage

This project has a few commands that can be executed across your list of modules:

## Install
Iterates through your Depfile and installs git sources. At the moment the supported options are:
* `--verbose` display progress messages
* `--clean` remove the directory before installing modules
* `--path` override the default `./modules` where modules will be installed
* `--depfile` override the default `./Depfile` used to find the modules

```
  simple-dependency-manager install [--verbose] [--clean] [--path] [--depfile]
```

## Update
Iterates through your depfile and updates git sources. If a SHA-1 hash is specified in the `:ref`, the module will not be updated.

Supported options are:<br/>
<li>`--verbose` display progress messages</li>
<li>`--path` override the default `./modules` where modules will be installed</li>
<li> `--depfile` override the default `./Depfile` used to find the modules</li>

```
  simple-dependency-manager update [--verbose] [--path] [--depfile]
```

## Clean
Remove the directory where the modules will be installed. At the moment the supported options are:
* `--verbose` display progress messages
* `--path` override the default `./modules` where modules will be installed

```
  simple-dependency-manager clean [--verbose] [--path]
```

## Depfile

The processed Depfile may contain two different types of modules, `git` and `tarball`. The `git` option accepts an optional `ref` parameter.

The module names can be namespaced, but the created directory will only contain the last part of the name. For example, a module named `puppetlabs/ntp` will generate a directory `ntp`, and so will a module simply named `ntp`.

Here's an example of a valid Depfile showcasing all valid options:

```
mod "puppetlabs/ntp",
    :git => "git://github.com/puppetlabs/puppetlabs-ntp.git",
    :ref => "99bae40f225db0dd052efbf1d4078a21f0333331"

mod "apache",
    :tarball => "https://forge.puppetlabs.com/puppetlabs/apache/0.6.0.tar.gz"
```

## Setting up for development and running the specs
Just clone the repo and run the following commands:
```
bundle exec install --path=vendor
bundle exec rspec
```

Beware that the functional tests will download files from GitHub and PuppetForge and will break if either is unavailable.

## License

See [LICENSE](/LICENSE)

## Credits

This is a fork on librarian-puppet-simple, which is based on librarian-puppet
which is based on librarian (which is probably based on something else :) )

The untar and ungzip methods came from https://gist.github.com/sinisterchipmunk/1335041
