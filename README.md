appenv ― per-application & per-directory shell environments
===========================================================

```
                __     _____   _____      __    ___   __  __
              /'__`\  /\ '__`\/\ '__`\  /'__`\/' _ `\/\ \/\ \
             /\ \L\.\_\ \ \L\ \ \ \L\ \/\  __//\ \/\ \ \ \_/ |
             \ \__/.\_\\ \ ,__/\ \ ,__/\ \____\ \_\ \_\ \___/
              \/__/\/_/ \ \ \/  \ \ \/  \/____/\/_/\/_/\/__/
                         \ \_\   \ \_\
                          \/_/    \/_/
```

*appenv* is a shell utility supporting *bash* and *fish* that allows you
to update your shell environment on a per-application basis. It is similar in functionality
to tools such as [`autoenv`](https://github.com/kennethreitz/autoenv) or [`direnv`](http://direnv.net/), the main difference being that `appenv` is
more portable (and has a slightly different feature set).

```
$ mkdir dir ; echo "export PATH=`pwd`/dir" > dir/.appenv
$ cd dir
$ appenv
$ echo $PATH
/home/use/dir
```

*appenv* scripts should be written in *bash*, and do not have any specific requirement
besides updating environment variables.

Here's a [typical example](example/simple.appenv.sh):

```shell
#!/usr/bin/bash
if test -z $APP_EXAMPLE; then
	export APP_EXAMPLE=$HOME/.local/share/example
	export PATH=$APP_EXAMPLE/bin:$PATH
	export MANPATH=$APP_EXAMPLE/share/man:$MANPATH
fi
```

or using the *appenv* [shell API](#API) functions:

```shell
appenv_name    example
appenv_declare APP_EXAMPLE $HOME/.local/share/example
appenv_prepend PATH        $APP_EXAMPLE/bin
appenv_prepend MANPATH     $APP_EXAMPLE/share/man
appenv_log     "Example environment loaded at $APP_EXAMPLE"
```

Installing
==========

Download
--------

*appenv* requires *bash* and *python* to run, both of these
commands are likely already available. To automatically install *appenv* from
github, do the following:

```shell
curl https://raw.githubusercontent.com/sebastien/appenv/install.sh | bash
```

this will install the *appenv* scripts under `~/.local/bin`, you can also specify an
alternative location by setting the `APPENV_HOME` variable before
running the install script.

```shell
curl https://raw.githubusercontent.com/sebastien/appenv/install.sh\
| export APPENV_HOME=~/local && bash
```

Shell configuration
-------------------

To load these commands from your shell, do the following in **bash**:

```shell
source ~/.local/bin/appenv.bash
```

in **fish**:

```shell
. ~/.local/bin/appenv.fish
```


Usage
=====

System-wide environments
------------------------

The typical usage would be to create an `~/.appenv` directory and populate
it with `*.appenv.sh` files, one for each application environment that you would
like to be available.

Example:

```
/home/user/.appenv/
├── prod.appenv.sh
├── staging.appenv.sh
└── dev.appenv.sh
```

and then do 

```
appenv dev
```

to load the `~/.append/dev.appenv.sh` environment from anywhere on the filesystem.

It is also possible to prefix appenv script names with `auto-NNN` where *NNN*
are digits. This features allows you to make the difference between scripts
you can load on demand and those loaded automatically.

```
appenv-load ~/.appenv/auto-*.appenv.sh
```

The `appenv-load` command will be able to resolve `auto-000-name.appenv.sh` 
from just the `name`.


Directory-specific environments
-------------------------------

Another usage is to create directory-specific environments, in which case
you would add an `.appenv` file at the root of your project directory and 
then add `appenv-autoload` to your prompt in order to automatically load
the `.appenv` when it is in scope.

```shell
$ cd myproject
$ cat <<EOT >> .autoenv
appenv_declare MYPROJECT
appenv_prepend PATH $MYPROJECT/bin
appenv_prepend PYTHONPATH $MYPROJECT/lib/python
EOT
$ cd myproject ; autoenv
$ echo $MYPROJECT
/home/user/myproject
```

Available commands
==================

Once loaded in you shell, *appenv* offers the following commands:

- `appenv-list DIR?`

	lists the *appenv* scripts available in the current (or given) directory and
	all its ancestors.

- `appenv(-autoload) DIR?`

	automatically loads the `.appenv` file or the `.append/*.appenv.sh` files
	in the current (or given) directory, making sure the same environment is not
	loaded twice.

	*Tip: execute `appenv(-autoload)` in your prompt to automatically
	load an environment on directory change.*

- `appenv-load FILE‥|NAME‥`

	loads the application environemnt scripts(s) identified by the given
	*NAME* (resolved in `~/.appenv/<NAME>.appenv.sh`) or *FILE*.

- `appenv-unload FILE‥|NAME‥`

	unloads a preset environment, reverting the changes
	made by `appenv-load`.

- `appenv-loaded`

	lists the loaded appenv environments

- `appenv-export`
	
	exports the current environment as a script that can be loaded
	to restore the environment to what it was.

- `appenv-import FILE?` 

	imports an environment saved from a previous export, if
	not *FILE* is given, will load the directives from *stdin*.

- `appenv-capture command`
	
	captures the changes made to the environment of the given command,
	returning the update script in the same format as `appenv-export`.

<a name="api">Shell API
=======================

Application environment scripts (`*.appenv.sh`) have the following API already available,
defined in [_appenv.api.bash](bin/_appenv.api.bash):

- **_appenv_declare** *NAME* *VALUE?*

	exits the script if the environment variable *NAME* is defined (and
	equal to *VALUE* if specified), effectively guarding the execution of
	the rest of the script if the variable has already been defined. 

	```shell
	appenv_declare MYAPP
	# The following code will only be executed if MYAPP` is not defined.
	# The `MYAPP` variable will be set to `true` by default.
	‥
	```

- **_appenv_append** *NAME* *VALUE*

	adds the given *VALUE* at the end of the given environment
	variable with the given *NAME*, ensuring that *VALUE* does not occurs twice.

	```shell
	appenv_append PATH ~/.local/share/example/bin
	```

- **_appenv_prepend** *NAME* *VALUE*

	adds the given *VALUE* at the beginning of the given environment
	variable with the given *NAME*, ensuring that *VALUE* does not occurs twice.

	```shell
	appenv_append PATH ~/.local/share/example/bin
	```

- **_appenv_remove** *NAME* *VALUE*

	removes the given `VALUE` from the given environment variable.

	```shell
	appenv_remove PATH ~/.local/share/example/bin
	```

- **_appenv_set** *NAME* *VALUE*

	sets the given environment variable to the given `VALUE`

	```shell
	appenv_set APP_EXAMPLE_HOME ~/.local/share/example
	```

- **_appenv_clear** *NAME*

	unsets the given environment variable

	```
	appenv_clear APP_EXAMPLE_HOME
	```

Appenv also defines environment variables:

- **APPENV_LOADED**

	The list of scripts (by path) current loaded in the environment, separated by colons ':'

- **APPENV_STATUS**

	The list of scripts (by name0 with an `appenv_name` directive, currently loaded in the environment, separated by colons ':'

- **APPENV_FILE**

	The normalzied path to the appenv file currently being loaded.

These API calls (implemented as Bash functions) are not required, but
are offered to have cleaner more consistent API in writing the env files. You
can find the implementation of these files in the [`_appenv.api.bash`](bin/_appenv.api.bash) 
source.

