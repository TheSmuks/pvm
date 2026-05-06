# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-05-06

### Fixed

- `pvm ls` now shows `(current)` and `(default)` markers for installed versions
- `pvm ls <pattern>` correctly matches partial version strings (e.g., `1732` matches `8.0.1732`)

### Changed

- `pvm ls-remote <pattern>` pattern matching consistency with `pvm ls`


### Added

- Fish shell support via `pvm.fish` (delegates state-mutating commands to bash subshell, handles `use` and `deactivate` natively)
- `pvm _fish use <version>` — outputs key=value pairs for Fish to consume
- `pvm _fish deactivate` — outputs variables to unset
- `install.sh` detects Fish shell and writes to `~/.config/fish/config.fish`

## [0.1.0] - 2026-05-03

### Fixed

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

### Changed

- Pike environment transparency: `pvm use` now exports `PIKE_MODULE_PATH`, `PIKE_INCLUDE_PATH`, `PIKE_MASTER`, `PVM_PIKE_HOME`, `PVM_PIKE_VERSION` for Pike module resolution and pmp integration
