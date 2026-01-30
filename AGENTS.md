# appenv Agent Guidelines

Per-application & per-directory shell environment management tool supporting Bash.

## Build Commands

- `make` or `make install` - Install appenv to `~/.local` (or `$PREFIX`)
- `make uninstall` - Remove appenv from `~/.local`
- `make link` - Symlink appenv from current directory to `~/.local` (for development)

## Test Commands

- **No test suite implemented yet** - Tests should follow shell script best practices
- Test files should be named `*.test.bash` or placed in a `tests/` directory
- Use `bash -n` for syntax checking: `bash -n bin/appenv.bash`
- Use shellcheck if available: `shellcheck bin/appenv.bash`

## Lint Commands

- `bash -n <file>` - Syntax check bash scripts
- `shellcheck <file>` - Static analysis (recommended but not enforced)
- Check for trailing whitespace and ensure tabs for indentation

## Code Style Guidelines

### Shell Script Conventions

**File Headers:**
- Use `#!/usr/bin/env bash` shebang
- Include ASCII art banner with project name
- Add short docstring describing the file purpose
- Example:
```bash
#!/usr/bin/env bash
#
#    __     _____   _____      __    ___   __  __
#  ...
#
# -----------------------------------------------------------------------------
# filename.bash -- Short description of the file
```

**Indentation:**
- Use tabs (indent_size = 4) per .editorconfig
- Section headers use `=== NAME ===` format

**Naming Conventions:**
- Global variables: `UPPER_CASE` (e.g., `APPENV_BASE`, `APPENV_LIB`)
- Local variables: `local lower_case` or `local camelCase`
- Functions: `snake_case` with prefixes:
  - Public API: `appenv_<name>` (e.g., `appenv_declare`, `appenv_prepend`)
  - Private/internal: `_appenv_<name>` (e.g., `_appenv_log`, `_appenv_error`)

**Function Structure:**
```bash
function function_name {
	local param1=$1
	local param2=$2
	# implementation
}
```

**Error Handling:**
- Use `>&2` for error output: `>&2 echo "error message"`
- Check command existence: `if [ ! -z "$(which python)" ]; then`
- Validate required variables are set

**Comments:**
- Use comments only to clarify intent
- Section headers with `=== SECTION NAME ===`
- End files with `# EOF` marker

### Project Structure

```
appenv/
├── bin/                    # Executable scripts
│   └── appenv.bash        # Bash implementation
├── share/appenv/          # Library files
│   ├── api.bash          # Public API functions
│   ├── commands.bash     # Command implementations
│   ├── merge.bash        # Environment merging utilities
│   └── run.bash          # Runtime utilities
├── example/               # Example .appenv.sh files
├── install.sh            # Installation script
├── Makefile              # Build automation
└── deps/sdk/             # LittleSDK submodule
```

### API Functions

Core API functions (from `share/appenv/api.bash`):
- `appenv_declare NAME VALUE?` - Declare environment variable
- `appenv_append NAME VALUE SEP?` - Append to environment variable
- `appenv_prepend NAME VALUE` - Prepend to environment variable
- `appenv_remove NAME VALUE` - Remove value from environment
- `appenv_set NAME VALUE` - Set environment variable
- `appenv_clear NAME` - Unset environment variable
- `appenv_log MESSAGE` - Log message with yellow color
- `appenv_error MESSAGE` - Output error to stderr
- `appenv_name NAME` - Set status name
- `appenv_module NAME VALUE?` - Declare module (combines name + declare)
- `appenv_load PATH` - Load appenv file
- `appenv_post COMMAND` - Set post-load command

## Development Workflow

1. Edit files in `bin/` or `share/appenv/`
2. Test locally: `bash -n <file>` for syntax checking
3. Use `make link` for development (symlinks instead of copy)
4. Reload shell to test changes

## Dependencies

- **bash** - Shell interpreter
- **python** or **python3** - Used for environment processing
- Optional: **shellcheck** - For static analysis

## Related Documentation

- See `deps/sdk/AGENTS.md` for LittleSDK-specific guidelines
- See `README.md` for user-facing documentation
- Example usage in `example/simple.appenv.sh`

## Environment Variables

Key variables used by appenv:
- `APPENV_LOADED` - Colon-separated list of loaded scripts
- `APPENV_STATUS` - Colon-separated list of loaded named environments
- `APPENV_SHELL` - Current shell
- `APPENV_FILE` - Path to currently loading appenv file
- `APPENV_DIR` - Directory of currently loading appenv file
- `APPENV_POST` - Commands to run after loading
