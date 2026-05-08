# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]





### Fixed
- Source build now passes targeted `-Wno-*` flags to configure for GCC 14+ compatibility (suppresses implicit-function-declaration, implicit-int, int-conversion, alloc-size-larger-than, and free-nonheap-object warnings in Pike's code)
- Source build error output now shows the first error from the build log with context, instead of the last 20 lines which often only show trailing warnings
- `pvm install --source` now retries with `-j1` when a parallel build fails, working around Pike's Makefile race conditions on multi-core machines (e.g. concurrent mkdir of 'lib/')
- `pvm_show_build_error` grep pattern now matches `Error N`, `no such file`, `cannot create directory`, and `No rule to make target` in addition to `error:`, surfacing actual build failures instead of falling through to trailing noise








### Added

- `pvm install` now validates that the requested version exists remotely before downloading, and rejects invalid versions early with helpful suggestions
- `pvm install --source` now checks that gcc/g++/make are available before downloading source, and reports missing prerequisites with platform-specific install instructions
- `pvm install` detects and skips when a version is already installed (via version validation)

## [0.2.2] - 2026-05-07

### Fixed

- Fixed source build to `cd src/` before running configure

### Fixed

	- Fixed `pvm install` by correcting URL paths:
	  - Binary download: `https://pike.lysator.liu.se/pub/pike/all/{version}/`
	  - Listing directory: `https://pike.lysator.liu.se/download/pub/pike/all/{version}/`
	- Fixed version parsing regex to handle full-path hrefs from lysator listing
	- Rewrote source install to download tarball from lysator instead of git clone
	- Replaced the dead `if/fi` Fish detection block in `pvm.sh` with a compatible one-liner
	- Fixed 4 shellcheck warnings in `pvm.sh` (SC2155, SC2164, SC2115)
	- `install.sh` shows the correct source command for Fish shell users

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
