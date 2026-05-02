# pvm — Pike Version Manager

[![CI](https://github.com/TheSmuks/pvm/actions/workflows/ci.yml/badge.svg)](https://github.com/TheSmuks/pvm/actions/workflows/ci.yml)
[![Commit Lint](https://github.com/TheSmuks/pvm/actions/workflows/commit-lint.yml/badge.svg)](https://github.com/TheSmuks/pvm/actions/workflows/commit-lint.yml)
[![License](https://img.shields.io/badge/license-MPL%2FLGPL%2FGPL-blue)](https://github.com/TheSmuks/pvm/blob/main/LICENSE)
![Shell](https://img.shields.io/badge/shell-bash%2Fzsh-4EAA25?logo=gnubash&logoColor=white)

A version manager for [Pike](https://pike.lysator.liu.se/), modeled after [nvm](https://github.com/nvm-sh/nvm).

## What it does

pvm manages multiple Pike installations per-user. It downloads prebuilt Pike binaries from `pike.lysator.liu.se`, installs them under `~/.pvm/versions/`, and manipulates PATH to select the active version.

## Install

```bash
curl -o- https://raw.githubusercontent.com/TheSmuks/pvm/main/install.sh | bash
```

Or:

```bash
wget -qO- https://raw.githubusercontent.com/TheSmuks/pvm/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/TheSmuks/pvm.git ~/.pvm
```

Then add to your shell config (`~/.bashrc`, `~/.zshrc`, etc.):

```sh
export PVM_DIR="$HOME/.pvm"
[ -s "$PVM_DIR/pvm.sh" ] && . "$PVM_DIR/pvm.sh"
```

## Usage

```bash
# Install the latest Pike
pvm install --latest

# Install a specific version
pvm install 8.0.1116

# Build from source (when no binary is available)
pvm install 8.0.1116 --source

# Switch to a version
pvm use 8.0.1116

# Check current version
pvm current

# List installed versions
pvm ls

# List available versions
pvm ls-remote

# Set default version
pvm default 8.0.1116

# Run with a specific version
pvm run 8.0.1116 script.pike

# Execute a command with Pike on PATH
pvm exec 8.0.1116 pike --version
```

## .pikerc

Create a `.pikerc` file in your project root to pin the Pike version:

```
# Use Pike 8.0.1116
8.0.1116
```

Then `pvm use` (with no arguments) will read and use the version from `.pikerc`.

pvm walks up from `$PWD` to find `.pikerc`, just like nvm's `.nvmrc`.

## Commands

| Command | Description |
|---------|-------------|
| `pvm install <ver>` | Install a Pike version |
| `pvm use [ver]` | Switch active version |
| `pvm current` | Print active version |
| `pvm ls [pattern]` | List installed versions |
| `pvm ls-remote [pattern]` | List available versions |
| `pvm uninstall <ver>` | Remove a version |
| `pvm alias <name> <ver>` | Create named alias |
| `pvm unalias <name>` | Remove alias |
| `pvm default [ver]` | Set/show default version |
| `pvm run <ver> [args]` | Run pike with specific version |
| `pvm exec <ver> <cmd>` | Run command with Pike on PATH |
| `pvm which [ver]` | Print path to pike binary |
| `pvm deactivate` | Remove pvm from PATH |
| `pvm cache dir` | Show cache directory |
| `pvm cache clear` | Clear download cache |
| `pvm debug` | Print diagnostic info |
| `pvm unload` | Remove pvm from shell |
| `pvm version` | Print pvm version |

## Tab Completion

Add to your `~/.bashrc`:

```sh
[ -s "$PVM_DIR/bash_completion" ] && . "$PVM_DIR/bash_completion"
```

## Requirements

- Bash or Zsh
- `curl` or `wget`
- For source builds: GCC, GNU Make

## License

Triple-licensed under MPL 2.0 / LGPL 2.1 / GPL 2.0 (same as Pike).
