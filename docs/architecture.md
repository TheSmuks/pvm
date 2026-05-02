# Architecture

## Overview

PVM (`pvm`) is a POSIX-compliant shell script that manages multiple Pike installations per-user. It is modeled after [nvm](https://github.com/nvm-sh/nvm) and follows the same sourced-script architecture.

## Core Design: Sourced Shell Script

The main script (`pvm.sh`) is **sourced** into the shell, not executed. This allows it to:

1. Export a `pvm()` shell function that persists in the user's shell session
2. Manipulate PATH directly (subshells cannot modify the parent's PATH)
3. Set environment variables (`PVM_DIR`, `PVM_BIN`, `PVM_PIKE`) that persist

Internal helpers are prefixed with `pvm_` and are defined as shell functions within the sourced script.

## Directory Layout

```
~/.pvm/
├── pvm.sh                  # main sourced script
├── pvm-exec                # subshell exec helper
├── bash_completion         # tab completion
├── alias/                  # named version aliases
│   └── default             # file containing version string
├── versions/               # installed Pike versions
│   └── 8.0.1116/
│       ├── bin/pike        # symlink to build/pike
│       ├── build/          # Pike build tree
│       │   ├── pike        # actual binary
│       │   └── lib/
│       └── master.pike
└── .cache/                 # downloaded tarballs
    └── bin/
```

## Version Resolution

For `pvm use` / `pvm install` with no explicit version:

1. `.pikerc` file (walk up from `$PWD`)
2. `default` alias
3. Latest installed version

## PATH Manipulation

`pvm use` prepends `$PVM_DIR/versions/{VER}/bin` to PATH and removes any previous pvm version path. It exports `PVM_BIN` and `PVM_PIKE` and runs `hash -r` to clear the command hash table.

## Binary Download

Pike distributes prebuilt binaries as self-extracting tar archives from `pike.lysator.liu.se/pub/pike/all/{VERSION}/`. PVM detects the platform (OS + arch), matches the best binary slug, downloads to cache, and extracts.

## Source Build

When no prebuilt binary is available, PVM can download the source tarball and build Pike with `make && make install prefix=~/.pvm/versions/{VERSION}`.

## Shell Integration

```sh
export PVM_DIR="$HOME/.pvm"
[ -s "$PVM_DIR/pvm.sh" ] && . "$PVM_DIR/pvm.sh"
```

Supported shells: bash, zsh. Fish via community wrappers (documented, not shipped).
