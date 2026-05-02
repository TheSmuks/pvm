# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Fixed all 36 pre-existing shellcheck findings (warnings + info) across the project
### Added

- Initial implementation of pvm (Pike Version Manager)
- `pvm install <ver>` — download and install Pike binaries from pike.lysator.liu.se
- `pvm install <ver> --source` — build Pike from source
- `pvm use [ver]` — switch active Pike version via PATH manipulation
- `pvm current` — print currently active version
- `pvm ls` — list locally installed versions
- `pvm ls-remote [pattern]` — list available versions from pike.lysator.liu.se
- `pvm uninstall <ver>` — remove an installed version
- `pvm alias <name> <ver>` / `pvm unalias <name>` / `pvm alias` — named version aliases
- `pvm default [ver]` — set default version
- `pvm run <ver> [args]` — run pike with specific version in subshell
- `pvm exec <ver> <cmd>` — run arbitrary command with specific Pike on PATH
- `pvm which [ver]` — print path to pike binary
- `pvm deactivate` — remove pvm paths from PATH
- `pvm cache dir` / `pvm cache clear` — manage download cache
- `pvm debug` — print diagnostic information
- `pvm unload` — remove pvm from current shell
- `.pikerc` file support for per-project version pinning
- Shell startup auto-use (default or .pikerc version)
- Bash tab completion
- Bootstrap installer (`install.sh`)
- POSIX shell script architecture (sourced, not executed)

- Pike environment transparency: `pvm use` now exports `PIKE_MODULE_PATH`, `PIKE_INCLUDE_PATH`, `PIKE_MASTER`, `PVM_PIKE_HOME`, `PVM_PIKE_VERSION` for Pike module resolution and pmp integration
