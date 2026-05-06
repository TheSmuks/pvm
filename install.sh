#!/usr/bin/env bash
# install.sh — Bootstrap installer for pvm (Pike Version Manager)
# Usage: curl -o- https://raw.githubusercontent.com/TheSmuks/pvm/main/install.sh | bash
#    or: wget -qO- https://raw.githubusercontent.com/TheSmuks/pvm/main/install.sh | bash

set -euo pipefail

PVM_REPO_URL="https://github.com/TheSmuks/pvm.git"
PVM_DIR="${PVM_DIR:-$HOME/.pvm}"

info() { printf '\033[0;34mpvm:\033[0m %s\n' "$*"; }
err()  { printf '\033[0;31mpvm:\033[0m %s\n' "$*" >&2; }

# Check for git
if ! command -v git >/dev/null 2>&1; then
	err "git is required. Please install git first."
	exit 1
fi

# Check for curl or wget
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
	err "curl or wget is required. Please install one of them first."
	exit 1
fi

info "Installing pvm to ${PVM_DIR}..."

# Clone or update
if [ -d "${PVM_DIR}/.git" ]; then
	info "Updating existing pvm installation..."
	(cd "$PVM_DIR" && git fetch --tags && git reset --hard origin/main) || {
		err "failed to update pvm"
		exit 1
	}
else
	if [ -d "$PVM_DIR" ]; then
		err "${PVM_DIR} exists but is not a git repository. Remove it and re-run."
		exit 1
	fi
	git clone "$PVM_REPO_URL" "$PVM_DIR" || {
		err "failed to clone pvm repository"
		exit 1
	}
fi

# Detect shell profile
detect_profile() {
	local shell_name
	shell_name="$(basename "${SHELL:-bash}")"
	local home="$HOME"

	case "$shell_name" in
		bash)
			# On macOS, bash reads .bash_profile; on Linux, .bashrc
			if [ -f "${home}/.bashrc" ]; then
				printf '%s' "${home}/.bashrc"
			elif [ -f "${home}/.bash_profile" ]; then
				printf '%s' "${home}/.bash_profile"
			fi
			;;
		zsh)
			if [ -f "${home}/.zshrc" ]; then
				printf '%s' "${home}/.zshrc"
			fi
			;;
		fish)
			if [ -f "${home}/.config/fish/config.fish" ]; then
				printf '%s' "${home}/.config/fish/config.fish"
			fi
			;;
		*)
			if [ -f "${home}/.profile" ]; then
				printf '%s' "${home}/.profile"
			fi
			;;
	esac
}

# Add sourcing lines to profile
add_to_profile() {
	local profile="$1"

	# Detect shell from profile path
	local is_fish=false
	case "$profile" in
		*.fish)
			is_fish=true
			;;
	esac

	local marker="# pvm"
	local lines
	if [ "$is_fish" = true ]; then
		lines=$(printf '%s\n%s\n%s\n' \
			"${marker}" \
			"set -gx PVM_DIR ${PVM_DIR}" \
			"[ -s \"$PVM_DIR/pvm.fish\" ]; and source \"$PVM_DIR/pvm.fish\"")
	else
		lines=$(printf '%s\n%s\n%s\n' \
			"${marker}" \
			"export PVM_DIR=\"${PVM_DIR}\"" \
			"[ -s \"\$PVM_DIR/pvm.sh\" ] && . \"\$PVM_DIR/pvm.sh\"")
	fi

	# Check if already present
	if grep -q "PVM_DIR" "$profile" 2>/dev/null; then
		info "Shell profile already configured: ${profile}"
		return 0
	fi

	printf '\n%s\n' "$lines" >> "$profile"
	info "Added pvm to ${profile}"
}

PROFILE="$(detect_profile)"
if [ -n "$PROFILE" ]; then
	add_to_profile "$PROFILE"
else
	info "Could not detect shell profile. Add these lines to your shell config:"
	printf '\n  export PVM_DIR="%s"\n' "$PVM_DIR"
	printf '  [ -s "$PVM_DIR/pvm.sh" ] && . "$PVM_DIR/pvm.sh"\n\n'
fi

# Make pvm-exec executable
chmod +x "${PVM_DIR}/pvm-exec" 2>/dev/null || true

info ""
info "pvm installed! Restart your shell or run:"

# Detect current shell for correct source instruction
case "$(basename "${SHELL:-bash}")" in
    fish)
        info "  source ${PVM_DIR}/pvm.fish"
        ;;
    *)
        info "  source ${PVM_DIR}/pvm.sh"
        ;;
esac

info ""
info "Then install Pike:"
info "  pvm install --latest"
