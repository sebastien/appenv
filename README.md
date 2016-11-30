appenv ― Per-application shell environments
===========================================

*appenv* is a shell utility supporting *bash*, *zsh*, *fish* and *xonsh* that allows you
to update your shell environment on per-application basis. It is similar in functionality
to tools such as `autoenv` or `direnv`, the main difference being that `appenv` is
more portable (and has a slightly different feature set).

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

or using the API functions:

```shell
#!/usr/bin/bash
appenv_declare APP_EXAMPLE $HOME/.local/share/example
appenv_prepend PATH        $APP_EXAMPLE/bin
appenv_prepend MANPATH     $APP_EXAMPLE/share/man
```

Installing
==========

*appenv* requires *bash* and *python3* to run, both of these commands are
likely already available.

To automatically install *autoenv* from github, do the following:

```
curl https://raw.githubusercontent.com/sebastien/appenv/install.sh | bash
```

this will install `.autoenv` in `~/.local/bin`, you can also specify an
alternative location by setting the `APPENV_HOME` variable before
running the install script.

```
curl https://raw.githubusercontent.com/sebastien/appenv/install.sh\
| export APPENV_HOME=~/local && bash
```

This will install the `appenv-{run,load,unload,export}` commands, which
will automatically detect your shell and setup the appropriate functions.

Available commands
==================

- `appenv-load FILE‥|NAME‥`

	loads the application environemnt scripts(s) identified by the given
	*NAME* (resolved in `~/.appenv/<NAME>.appenv.sh`) or *FILE*.

- `appenv-unload FILE‥|NAME‥`

	unloads a preset environment, reverting the changes
	made by `appenv-load`.

- `appenv-export`
	
	exports the current environment as a script that can be loaded
	to restore the environment to what it was.

- `appenv-import FILE?` 

	imports an environment saved from a previous export, if
	not *FILE* is given, will load the directives from *stdin*.

Shell API
=========

Application environment scripts (`.appenv.sh`) have the following API already available:

- **appenv_declare** *NAME* *VALUE?*

	exits the script if the environment variable *NAME* is defined (and
	equal to *VALUE* if specified), effectively guarding the execution of
	the rest of the script if the variable has already been defined. 

	```shell
	appenv_declare APP_EXAMPLE
	# The following code will only be executed if `APP_EXAMPLE` is not defined.
	# The `APP_EXAMPLE` variable will be set to `true` by default.
	‥
	```

- **appenv_append** *NAME* *VALUE*

	adds the given *VALUE* at the end of the given environment
	variable with the given *NAME*, ensuring that *VALUE* does not occurs twice.

	```shell
	appenv_append PATH ~/.local/share/example/bin
	```

- **appenv_prepend** *NAME* *VALUE*

	adds the given *VALUE* at the beginning of the given environment
	variable with the given *NAME*, ensuring that *VALUE* does not occurs twice.

	```shell
	appenv_append PATH ~/.local/share/example/bin
	```

- **appenv_remove** *NAME* *VALUE*

	removes the given `VALUE` from the given environment variable.

	```shell
	appenv_remove PATH ~/.local/share/example/bin
	```

- **appenv_set** *NAME* *VALUE*

	sets the given environment variable to the given `VALUE`

	```shell
	appenv_set APP_EXAMPLE_HOME ~/.local/share/example
	```

- **appenv_clear** *NAME*

	unsets the given environment variable

	```
	appenv_clear APP_EXAMPLE_HOME
	```


These API calls (implemented as Bash functions) are not required, but
are offered to have cleaner more consistent API in writing the env files. You
can find the implementation of these files in the [`_appenv.api.bash`](bin/_appenv.api.bash) 
source.

