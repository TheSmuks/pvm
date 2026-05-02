# shellcheck shell=bash
# PVM — Pike Version Manager
# Sourced shell script. Do not execute directly.
# Usage: source pvm.sh
#
# Modeled after nvm (https://github.com/nvm-sh/nvm)

# Guard against double-sourcing
if [ -n "${_PVM_LOADED:-}" ]; then

	# shellcheck disable=SC2317
	return 0 2>/dev/null || :
fi
_PVM_LOADED=1

# Resolve PVM_DIR
if [ -z "${PVM_DIR:-}" ]; then
	PVM_DIR="$HOME/.pvm"
fi
export PVM_DIR

# PVM version
_PVM_VERSION="0.1.0"

# Base URL for Pike downloads
_PVM_PIKE_BASE_URL="https://pike.lysator.liu.se/pub/pike/all"

# Default self-extracting archive extension
_PVM_ARCHIVE_EXT=""

# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------

pvm_err() {
	printf 'pvm: %s\n' "$*" >&2
}

pvm_info() {
	printf 'pvm: %s\n' "$*"
}

# Check if a command exists
pvm_has() {
	command -v "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

pvm_get_os() {
	local uname_out
	uname_out="$(uname -s)"
	case "${uname_out}" in
		Linux*)   printf '%s' "Linux" ;;
		Darwin*)  printf '%s' "MacOSX" ;;
		MINGW*|MSYS*|CYGWIN*) printf '%s' "Windows" ;;
		FreeBSD*) printf '%s' "FreeBSD" ;;
		*)        printf '%s' "${uname_out}" ;;
	esac
}

pvm_get_arch() {
	local uname_m
	uname_m="$(uname -m)"
	case "${uname_m}" in
		x86_64|amd64)  printf '%s' "x86_64" ;;
		aarch64|arm64) printf '%s' "arm64" ;;
		ppc64|ppc64le) printf '%s' "${uname_m}" ;;
		riscv64)       printf '%s' "riscv64" ;;
		i386|i686)     printf '%s' "i386" ;;
		*)             printf '%s' "${uname_m}" ;;
	esac
}

# ---------------------------------------------------------------------------
# Version parsing and comparison
# ---------------------------------------------------------------------------

# Extract major.minor from version string (e.g., "8.0" from "8.0.1116")
pvm_version_major_minor() {
	local version="$1"
	# "8.0.1116" → major=8, rest=0.1116
	local major="${version%%.*}"
	local rest="${version#*.}"
	# rest="0.1116" → minor=0 (everything before first .)
	local minor="${rest%%.*}"
	printf '%s.%s' "$major" "$minor"
}

# Parse a version string into its components
# Outputs: major minor build (space-separated)
pvm_parse_version() {
	local version="$1"
	local major minor build rest

	# Strip leading 'v' if present
	version="${version#v}"

	IFS='.' read -r major minor build rest <<-EOF
		${version}
	EOF

	printf '%s %s %s' "${major:-0}" "${minor:-0}" "${build:-0}"
}

# Compare two version strings. Returns:
# 0 if $1 == $2
# 1 if $1 > $2
# 2 if $1 < $2
pvm_version_compare() {
	local v1="$1"
	local v2="$2"

	if [ "$v1" = "$v2" ]; then
		return 0
	fi

	local v1_major v1_minor v1_build
	local v2_major v2_minor v2_build

	read -r v1_major v1_minor v1_build <<-EOF
		$(pvm_parse_version "$v1")
	EOF

	read -r v2_major v2_minor v2_build <<-EOF
		$(pvm_parse_version "$v2")
	EOF

	# Compare major
	if [ "${v1_major:-0}" -gt "${v2_major:-0}" ]; then
		return 1
	elif [ "${v1_major:-0}" -lt "${v2_major:-0}" ]; then
		return 2
	fi

	# Compare minor
	if [ "${v1_minor:-0}" -gt "${v2_minor:-0}" ]; then
		return 1
	elif [ "${v1_minor:-0}" -lt "${v2_minor:-0}" ]; then
		return 2
	fi

	# Compare build
	if [ "${v1_build:-0}" -gt "${v2_build:-0}" ]; then
		return 1
	elif [ "${v1_build:-0}" -lt "${v2_build:-0}" ]; then
		return 2
	fi

	return 0
}

# ---------------------------------------------------------------------------
# Directory helpers
# ---------------------------------------------------------------------------

pvm_version_path() {
	local version="$1"
	printf '%s/versions/%s' "$PVM_DIR" "$version"
}

pvm_version_bin_path() {
	local version="$1"
	printf '%s/versions/%s/bin' "$PVM_DIR" "$version"
}

pvm_alias_path() {
	local name="$1"
	printf '%s/alias/%s' "$PVM_DIR" "$name"
}

pvm_cache_dir() {
	printf '%s/.cache' "$PVM_DIR"
}

pvm_cache_bin_dir() {
	printf '%s/.cache/bin' "$PVM_DIR"
}

# ---------------------------------------------------------------------------
# Version validation
# ---------------------------------------------------------------------------

# Check if a version is installed
pvm_is_version_installed() {
	local version="$1"
	local version_path
	version_path="$(pvm_version_path "$version")"
	[ -d "$version_path" ] && [ -x "${version_path}/bin/pike" ]
}

# ---------------------------------------------------------------------------
# Alias management
# ---------------------------------------------------------------------------

pvm_get_alias() {
	local name="$1"
	local alias_file
	alias_file="$(pvm_alias_path "$name")"
	if [ -f "$alias_file" ]; then
		cat "$alias_file"
		return 0
	fi
	return 1
}

pvm_set_alias() {
	local name="$1"
	local version="$2"
	local alias_dir
	alias_dir="$(dirname "$(pvm_alias_path "$name")")"
	[ -d "$alias_dir" ] || mkdir -p "$alias_dir"
	printf '%s' "$version" > "$(pvm_alias_path "$name")"
}

pvm_remove_alias() {
	local name="$1"
	local alias_file
	alias_file="$(pvm_alias_path "$name")"
	if [ -f "$alias_file" ]; then
		rm -f "$alias_file"
		return 0
	fi
	return 1
}

pvm_list_aliases() {
	local alias_dir
	alias_dir="${PVM_DIR}/alias"
	if [ -d "$alias_dir" ]; then
		local name version
		for file in "$alias_dir"/*; do
			[ -f "$file" ] || continue
			name="$(basename "$file")"
			version="$(cat "$file")"
			if [ "$name" = "default" ]; then
				printf '%s -> %s\n' "$name" "$version"
			else
				printf '%s -> %s\n' "$name" "$version"
			fi
		done
	fi
}

# ---------------------------------------------------------------------------
# .pikerc file resolution
# ---------------------------------------------------------------------------

# Walk up from $PWD looking for .pikerc
pvm_find_pikerc() {
	local path="${PWD}"
	while [ "$path" != "/" ]; do
		if [ -f "${path}/.pikerc" ]; then
			printf '%s' "${path}/.pikerc"
			return 0
		fi
		path="$(dirname "$path")"
	done
	# Check root
	if [ -f "/.pikerc" ]; then
		printf '%s' "/.pikerc"
		return 0
	fi
	return 1
}

# Read and parse .pikerc file
pvm_read_pikerc() {
	local pikerc_file
	pikerc_file="$(pvm_find_pikerc)" || return 1

	local line
	while IFS= read -r line || [ -n "$line" ]; do
		# Skip comments and blank lines
		line="$(printf '%s' "$line" | sed 's/#.*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
		[ -z "$line" ] && continue
		printf '%s' "$line"
		return 0
	done < "$pikerc_file"
	return 1
}

# ---------------------------------------------------------------------------
# Version resolution chain
# ---------------------------------------------------------------------------

# Resolve the effective version given a possibly-ambiguous spec
pvm_resolve_version() {
	local provided_version="$1"

	# If explicit version given, resolve aliases
	if [ -n "${provided_version}" ]; then
		# Check if it's an alias
		local resolved
		if resolved="$(pvm_get_alias "$provided_version")" && [ -n "$resolved" ]; then
			printf '%s' "$resolved"
			return 0
		fi

		# Check for "latest" keyword
		if [ "$provided_version" = "latest" ]; then
			pvm_resolve_latest
			return $?
		fi

		# Return as-is
		printf '%s' "$provided_version"
		return 0
	fi

	# No version provided — walk the resolution chain

	# 1. .pikerc file
	local pikerc_version
	if pikerc_version="$(pvm_read_pikerc)" && [ -n "$pikerc_version" ]; then
		# Recursively resolve (might be "latest" or an alias)
		pvm_resolve_version "$pikerc_version"
		return $?
	fi

	# 2. default alias
	local default_version
	if default_version="$(pvm_get_alias "default")" && [ -n "$default_version" ]; then
		printf '%s' "$default_version"
		return 0
	fi

	# 3. Latest installed version
	pvm_resolve_latest_installed
}

pvm_resolve_latest_installed() {
	local latest=""
	local version
	for dir in "${PVM_DIR}/versions/"*; do
		[ -d "$dir" ] || continue
		version="$(basename "$dir")"
		if [ -z "$latest" ]; then
			latest="$version"
		else
			pvm_version_compare "$version" "$latest"
			case $? in
				1) latest="$version" ;;  # version > latest
			esac
		fi
	done

	if [ -n "$latest" ]; then
		printf '%s' "$latest"
		return 0
	fi
	return 1
}

pvm_resolve_latest() {
	local remote_version
	remote_version="$(pvm_get_latest_remote_version)" || {
		pvm_err "unable to determine latest version from remote"
		return 1
	}
	printf '%s' "$remote_version"
}

# ---------------------------------------------------------------------------
# Network operations
# ---------------------------------------------------------------------------

# Fetch a URL. Tries curl then wget.
pvm_fetch() {
	local url="$1"
	local output="$2"

	if pvm_has curl; then
		curl -q -L -s -o "$output" "$url" || {
			pvm_err "curl failed: $url"
			return 1
		}
	elif pvm_has wget; then
		wget -q -O "$output" "$url" || {
			pvm_err "wget failed: $url"
			return 1
		}
	else
		pvm_err "curl or wget is required"
		return 1
	fi
}

# Fetch a URL to stdout
pvm_fetch_to_stdout() {
	local url="$1"

	if pvm_has curl; then
		curl -q -L -s "$url" || {
			pvm_err "curl failed: $url"
			return 1
		}
	elif pvm_has wget; then
		wget -q -O - "$url" || {
			pvm_err "wget failed: $url"
			return 1
		}
	else
		pvm_err "curl or wget is required"
		return 1
	fi
}

# ---------------------------------------------------------------------------
# Remote version listing
# ---------------------------------------------------------------------------

# Parse the HTML directory listing from pike.lysator.liu.se
# Extracts version-like directory names (e.g., "8.0.1116", "8.0.1732")
pvm_parse_remote_versions() {
	local html="$1"
	printf '%s\n' "$html" | \
		grep -oE 'href="([0-9]+\.[0-9]+\.[0-9]+)/"' | \
		sed 's/href="//;s/\///' | \
		sort -t. -k1,1n -k2,2n -k3,3n
}

# Get the latest version available remotely
pvm_get_latest_remote_version() {
	local listing
	listing="$(pvm_fetch_to_stdout "${_PVM_PIKE_BASE_URL}/")" || return 1
	local versions
	versions="$(pvm_parse_remote_versions "$listing")" || return 1

	# Return the last (highest) version
	local latest=""
	local ver
	while IFS= read -r ver; do
		[ -z "$ver" ] && continue
		latest="$ver"
	done <<-EOF
		${versions}
	EOF

	if [ -n "$latest" ]; then
		printf '%s' "$latest"
		return 0
	fi
	return 1
}

# ---------------------------------------------------------------------------
# Binary matching
# ---------------------------------------------------------------------------

# Find the best binary slug for the current platform
# Outputs the filename (e.g., "Pike-v8.0.1116-Linux-5.4.65-x86_64")
pvm_find_binary_slug() {
	local version="$1"
	local os arch
	os="$(pvm_get_os)"
	arch="$(pvm_get_arch)"

	local listing
	listing="$(pvm_fetch_to_stdout "${_PVM_PIKE_BASE_URL}/${version}/")" || return 1

	# Match: Pike-v{VER}-{OS}-*-{ARCH}

	# Try exact OS + arch match
	local matches
	matches="$(printf '%s\n' "$listing" | \
		grep -oE "href=\"(Pike-v${version}-${os}-[^\"]*-${arch}[^\"]*)\"" | \
		sed 's/href="//;s/"$//' | \
		sort)"

	if [ -z "$matches" ]; then
		return 1
	fi

	# Pick the last match (latest kernel version, since they're sorted)
	local match
	match="$(printf '%s\n' "$matches" | tail -1)"
	printf '%s' "$match"
}

# ---------------------------------------------------------------------------
# Download and installation
# ---------------------------------------------------------------------------

pvm_download() {
	local url="$1"
	local output="$2"
	local description="$3"

	[ -d "$(dirname "$output")" ] || mkdir -p "$(dirname "$output")"

	pvm_info "Downloading ${description}..."
	pvm_fetch "$url" "$output" || return 1

	if [ ! -s "$output" ]; then
		pvm_err "downloaded file is empty"
		rm -f "$output"
		return 1
	fi

	pvm_info "Download complete: $(basename "$output")"
}

# Extract a Pike self-extracting archive
pvm_extract_binary() {
	local archive="$1"
	local version="$2"
	local dest
	dest="$(pvm_version_path "$version")"

	# Pike self-extracting archives are shell scripts containing an embedded tar.gz
	# Strategy: try to extract the embedded tar.gz

	local tmpdir
	tmpdir="$(mktemp -d)" || {
		pvm_err "failed to create temp directory"
		return 1
	}

	# Check if it's a gzip file (tar.gz) or a self-extracting script
	local file_type
	file_type="$(file -b "$archive" 2>/dev/null || echo "unknown")"

	if printf '%s' "$file_type" | grep -qi "gzip"; then
		# Direct tar.gz — extract it
		tar -xzf "$archive" -C "$tmpdir" || {
			pvm_err "failed to extract archive"
			rm -rf "$tmpdir"
			return 1
		}
	elif printf '%s' "$file_type" | grep -qi "POSIX tar\|tar archive"; then
		# POSIX tar (self-extracting) — extract it first, then find the inner tar.gz
		tar -xf "$archive" -C "$tmpdir" || {
			pvm_err "failed to extract outer archive"
			rm -rf "$tmpdir"
			return 1
		}

		# Find inner tar.gz
		local inner_tar
		inner_tar="$(find "$tmpdir" -name '*.tar.gz' -o -name '*.tgz' 2>/dev/null | head -1)"
		if [ -n "$inner_tar" ]; then
			local tmpdir2
			tmpdir2="$(mktemp -d)" || {
				pvm_err "failed to create temp directory"
				rm -rf "$tmpdir"
				return 1
			}
			tar -xzf "$inner_tar" -C "$tmpdir2" || {
				pvm_err "failed to extract inner archive"
				rm -rf "$tmpdir" "$tmpdir2"
				return 1
			}
			rm -rf "$tmpdir"
			tmpdir="$tmpdir2"
		fi
	else
		# Try as shell script (self-extracting) — look for the tar data after a marker
		# Or just try to extract as tar.gz directly
		tar -xzf "$archive" -C "$tmpdir" 2>/dev/null || \
		tar -xf "$archive" -C "$tmpdir" 2>/dev/null || {
			# Try to skip the shell script header and extract the embedded archive
			# Self-extracting archives have a shell header followed by tar data
			local line_count
			line_count="$(grep -an '^__ARCHIVE_BELOW__' "$archive" 2>/dev/null | head -1 | cut -d: -f1)"
			if [ -n "$line_count" ]; then
				tail -n +"$((line_count + 1))" "$archive" | tar -xzf - -C "$tmpdir" 2>/dev/null || \
				tail -n +"$((line_count + 1))" "$archive" | tar -xf - -C "$tmpdir" 2>/dev/null || {
					pvm_err "failed to extract self-extracting archive"
					rm -rf "$tmpdir"
					return 1
				}
			else
				pvm_err "unrecognized archive format: $archive"
				rm -rf "$tmpdir"
				return 1
			fi
		}
	fi

	# Find the extracted Pike directory
	local pike_dir
	pike_dir="$(find "$tmpdir" -maxdepth 1 -type d -name "Pike-v${version}*" | head -1)"
	if [ -z "$pike_dir" ]; then
		# Try any directory
		pike_dir="$(find "$tmpdir" -maxdepth 1 -type d | grep -v "^${tmpdir}$" | head -1)"
	fi

	if [ -z "$pike_dir" ]; then
		pvm_err "could not find extracted Pike directory"
		rm -rf "$tmpdir"
		return 1
	fi

	# Move to destination
	if [ -d "$dest" ]; then
		pvm_info "removing existing installation at $dest"
		rm -rf "$dest"
	fi

	mv "$pike_dir" "$dest" || {
		pvm_err "failed to move Pike to $dest"
		rm -rf "$tmpdir"
		return 1
	}

	rm -rf "$tmpdir"

	# Create bin directory and symlink
	mkdir -p "${dest}/bin"
	if [ -x "${dest}/build/pike" ]; then
		ln -sf "${dest}/build/pike" "${dest}/bin/pike"
	elif [ -x "${dest}/pike" ]; then
		ln -sf "${dest}/pike" "${dest}/bin/pike"
	else
		# Search for the pike binary
		local pike_binary
		pike_binary="$(find "$dest" -name pike -type f -executable 2>/dev/null | head -1)"
		if [ -n "$pike_binary" ]; then
			ln -sf "$pike_binary" "${dest}/bin/pike"
		else
			pvm_err "could not find pike binary in installation"
			rm -rf "$dest"
			return 1
		fi
	fi

	pvm_info "Installed Pike $version to $dest"
}

# Install Pike from a binary
pvm_install_binary() {
	local version="$1"
	local os arch slug url cache_file
	os="$(pvm_get_os)"
	arch="$(pvm_get_arch)"

	# Find matching binary
	slug="$(pvm_find_binary_slug "$version")" || {
		pvm_err "no binary found for ${os}-${arch} for Pike ${version}"
		return 1
	}

	url="${_PVM_PIKE_BASE_URL}/${version}/${slug}"
	cache_file="$(pvm_cache_bin_dir)/${slug}"

	# Check cache
	if [ -f "$cache_file" ]; then
		pvm_info "Using cached ${slug}"
	else
		pvm_download "$url" "$cache_file" "$slug" || return 1
	fi

	# Extract
	pvm_extract_binary "$cache_file" "$version"
}

# Install Pike from source
pvm_install_source() {
	local version="$1"
	local url cache_file dest
	url="${_PVM_PIKE_BASE_URL}/${version}/Pike-v${version}.tar.gz"
	cache_file="$(pvm_cache_bin_dir)/Pike-v${version}.tar.gz"
	dest="$(pvm_version_path "$version")"

	# Check cache
	if [ ! -f "$cache_file" ]; then
		pvm_download "$url" "$cache_file" "Pike-v${version}.tar.gz" || return 1
	fi

	# Extract and build
	local tmpdir
	tmpdir="$(mktemp -d)" || {
		pvm_err "failed to create temp directory"
		return 1
	}

	pvm_info "Extracting source..."
	tar -xzf "$cache_file" -C "$tmpdir" || {
		pvm_err "failed to extract source"
		rm -rf "$tmpdir"
		return 1
	}

	local srcdir
	srcdir="$(find "$tmpdir" -maxdepth 1 -type d -name "Pike-v${version}*" | head -1)"
	if [ -z "$srcdir" ]; then
		srcdir="$(find "$tmpdir" -maxdepth 1 -type d | grep -v "^${tmpdir}$" | head -1)"
	fi

	if [ -z "$srcdir" ]; then
		pvm_err "could not find extracted source directory"
		rm -rf "$tmpdir"
		return 1
	fi

	pvm_info "Building Pike ${version} from source (this may take a while)..."
	local nproc
	nproc="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"

	(cd "$srcdir" && \
		make -j"$nproc" && \
		make install prefix="$dest") || {
		pvm_err "build failed"
		rm -rf "$tmpdir" "$dest"
		return 1
	}

	rm -rf "$tmpdir"

	# Create bin directory and symlink
	mkdir -p "${dest}/bin"
	if [ -x "${dest}/build/pike" ]; then
		ln -sf "${dest}/build/pike" "${dest}/bin/pike"
	elif [ -x "${dest}/bin/pike" ]; then
		: # already there
	else
		local pike_binary
		pike_binary="$(find "$dest" -name pike -type f -executable 2>/dev/null | head -1)"
		if [ -n "$pike_binary" ]; then
			ln -sf "$pike_binary" "${dest}/bin/pike"
		else
			pvm_err "could not find pike binary after build"
			return 1
		fi
	fi

	pvm_info "Built and installed Pike $version to $dest"
}

# ---------------------------------------------------------------------------
# PATH manipulation
# ---------------------------------------------------------------------------

# Remove all pvm version paths from PATH
pvm_strip_path() {
	local new_path=""
	local IFS=':'
	local -a path_entries
	read -ra path_entries <<< "$PATH"
	local entry
	for entry in "${path_entries[@]}"; do
		case "$entry" in
			"${PVM_DIR}/versions/"*)
				# Skip pvm version paths
				;;
			*)
				if [ -z "$new_path" ]; then
					new_path="$entry"
				else
					new_path="${new_path}:${entry}"
				fi
				;;
		esac
	done
	PATH="$new_path"
}

# Prepend a version's bin directory to PATH
pvm_prepend_version_to_path() {
	local version="$1"
	local bin_path
	bin_path="$(pvm_version_bin_path "$version")"

	pvm_strip_path
	PATH="${bin_path}:${PATH}"

	export PVM_BIN="${bin_path}"
	export PVM_PIKE="${bin_path}/pike"
	export PATH

	# Clear command hash table
	pvm_set_pike_env "$version"
	hash -r 2>/dev/null || true
}

pvm_strip_pike_env() {
	# Strip pvm entries from PIKE_MODULE_PATH
	if [ -n "${PIKE_MODULE_PATH:-}" ]; then
		local new_path=""
		local IFS=':'
		local -a path_entries
		read -ra path_entries <<< "$PIKE_MODULE_PATH"
		local entry
		for entry in "${path_entries[@]}"; do
			case "$entry" in
				"${PVM_DIR}/versions/"*)
					# Skip pvm version paths
					;;
				*)
					if [ -z "$new_path" ]; then
						new_path="$entry"
					else
						new_path="${new_path}:${entry}"
					fi
					;;
			esac
		done
		if [ -n "$new_path" ]; then
			PIKE_MODULE_PATH="$new_path"
		else
			unset PIKE_MODULE_PATH
		fi
	fi

	# Strip pvm entries from PIKE_INCLUDE_PATH
	if [ -n "${PIKE_INCLUDE_PATH:-}" ]; then
		local new_path=""
		local IFS=':'
		local -a path_entries
		read -ra path_entries <<< "$PIKE_INCLUDE_PATH"
		local entry
		for entry in "${path_entries[@]}"; do
			case "$entry" in
				"${PVM_DIR}/versions/"*)
					# Skip pvm version paths
					;;
				*)
					if [ -z "$new_path" ]; then
						new_path="$entry"
					else
						new_path="${new_path}:${entry}"
					fi
					;;
			esac
		done
		if [ -n "$new_path" ]; then
			PIKE_INCLUDE_PATH="$new_path"
		else
			unset PIKE_INCLUDE_PATH
		fi
	fi

	# Unset Pike master and pvm-specific variables
	unset PIKE_MASTER
	unset PVM_PIKE_HOME
	unset PVM_PIKE_VERSION
}

# Set Pike environment variables for a version
# Detects the correct layout (binary extract vs source install)
pvm_set_pike_env() {
	local version="$1"
	local version_path
	version_path="$(pvm_version_path "$version")"

	# Detect lib/modules path — check common layouts
	local modules_path=""
	if [ -d "${version_path}/build/lib/modules" ]; then
		modules_path="${version_path}/build/lib/modules"
	elif [ -d "${version_path}/lib/modules" ]; then
		modules_path="${version_path}/lib/modules"
	elif [ -d "${version_path}/build/lib" ]; then
		modules_path="${version_path}/build/lib"
	fi

	# Strip any prior pvm-managed entries before prepending
	pvm_strip_pike_env

	# Set PIKE_MODULE_PATH if modules directory exists
	if [ -n "$modules_path" ]; then
		if [ -n "${PIKE_MODULE_PATH:-}" ]; then
			PIKE_MODULE_PATH="${modules_path}:${PIKE_MODULE_PATH}"
		else
			PIKE_MODULE_PATH="$modules_path"
		fi
		export PIKE_MODULE_PATH
	fi

	# Set PIKE_INCLUDE_PATH if include directory exists (binary extract layout)
	if [ -d "${version_path}/build/include" ]; then
		local include_path="${version_path}/build/include"
		if [ -n "${PIKE_INCLUDE_PATH:-}" ]; then
			PIKE_INCLUDE_PATH="${include_path}:${PIKE_INCLUDE_PATH}"
		else
			PIKE_INCLUDE_PATH="$include_path"
		fi
		export PIKE_INCLUDE_PATH
	fi

	# Set PIKE_MASTER if master.pike exists
	if [ -f "${version_path}/master.pike" ]; then
		PIKE_MASTER="${version_path}/master.pike"
		export PIKE_MASTER
	fi

	# Set pvm integration variables
	PVM_PIKE_HOME="${version_path}/build"
	export PVM_PIKE_HOME
	PVM_PIKE_VERSION="${version}"
	export PVM_PIKE_VERSION
}
# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

pvm_command_install() {
	local version=""
	local force_source=0
	local force_source=0

	# Parse arguments
	while [ $# -gt 0 ]; do
		case "$1" in
			--source)
				force_source=1
				shift
				;;
			--binary)
				force_source=0
				shift
				;;
			--latest)
				version="latest"
				shift
				;;
			-*)
				pvm_err "unknown option: $1"
				return 1
				;;
			*)
				if [ -z "$version" ]; then
					version="$1"
				else
					pvm_err "unexpected argument: $1"
					return 1
				fi
				shift
				;;
		esac
	done

	# Resolve version
	if [ -z "$version" ]; then
		version="$(pvm_read_pikerc)" || {
			pvm_err "no version specified and no .pikerc found"
			return 1
		}
	fi

	version="$(pvm_resolve_version "$version")" || {
		pvm_err "could not resolve version: $version"
		return 1
	}

	# Strip leading 'v'
	version="${version#v}"

	# Check if already installed
	if pvm_is_version_installed "$version"; then
		pvm_info "Pike ${version} is already installed"
		return 0
	fi

	# Ensure directories exist
	mkdir -p "$(pvm_cache_bin_dir)" 2>/dev/null
	mkdir -p "${PVM_DIR}/versions" 2>/dev/null
	mkdir -p "${PVM_DIR}/alias" 2>/dev/null

	if [ "$force_source" -eq 1 ]; then
		pvm_install_source "$version"
	else
		if ! pvm_install_binary "$version"; then
			local os arch
			os="$(pvm_get_os)"
			arch="$(pvm_get_arch)"
			if [ -t 0 ]; then
				pvm_err "No prebuilt binary available for ${os}-${arch}."
				printf "pvm: Build Pike %s from source? [Y/n] " "$version" >&2
				read -r answer
				case "$answer" in
					[nN]*)
						pvm_err "Aborting. Use 'pvm install ${version} --source' to build from source later."
						return 1
						;;
				esac
			else
				pvm_info "No binary found. Falling back to source build..."
			fi
			pvm_install_source "$version"
		fi
	fi
}

pvm_command_use() {
	local version=""

	while [ $# -gt 0 ]; do
		case "$1" in
			-*)
				pvm_err "unknown option: $1"
				return 1
				;;
			*)
				version="$1"
				shift
				;;
		esac
	done

	# Resolve version
	version="$(pvm_resolve_version "$version")" || {
		pvm_err "could not resolve version"
		return 1
	}

	# Strip leading 'v'
	version="${version#v}"

	# Check if installed
	if ! pvm_is_version_installed "$version"; then
		pvm_err "Pike ${version} is not installed"
		pvm_err "Run 'pvm install ${version}' first"
		return 1
	fi

	pvm_prepend_version_to_path "$version"
	pvm_info "Now using Pike ${version}"
}

pvm_command_current() {
	local current=""
	if [ -n "${PVM_BIN:-}" ] && [ -d "${PVM_BIN}" ]; then
		# Extract version from PVM_BIN path
		current="$(printf '%s' "$PVM_BIN" | sed "s|${PVM_DIR}/versions/||" | cut -d/ -f1)"
	fi

	if [ -n "$current" ]; then
		printf '%s\n' "$current"
	else
		pvm_err "no active Pike version"
		return 1
	fi
}

pvm_command_ls() {
	local pattern="${1:-}"
	local found=0

	if [ ! -d "${PVM_DIR}/versions" ]; then
		pvm_info "No versions installed"
		return 0
	fi

	local version
	for dir in "${PVM_DIR}/versions/"*; do
		[ -d "$dir" ] || continue
		version="$(basename "$dir")"

		# Apply pattern filter
		if [ -n "$pattern" ]; then
			case "$version" in
				*$pattern*) ;;
				*) continue ;;
			esac
		fi

		# Mark current version
		local marker=""
		local current
		current=""
		if [ -n "${PVM_BIN:-}" ]; then
			current="$(printf '%s' "$PVM_BIN" | sed "s|${PVM_DIR}/versions/||" | cut -d/ -f1)"
		fi
		if [ "$version" = "$current" ]; then
			marker=" (current)"
		fi

		# Check if this is the default
		local default_ver
		default_ver="$(pvm_get_alias "default" 2>/dev/null)" || default_ver=""
		if [ "$version" = "$default_ver" ] && [ "$marker" = "" ]; then
			marker=" (default)"
		fi

		printf '%s%s\n' "$version" "$marker"
		found=1
	done

	if [ "$found" -eq 0 ]; then
		pvm_info "No versions installed"
	fi
}

pvm_command_ls_remote() {
	local pattern="${1:-}"
	local listing versions

	pvm_info "Fetching available versions..."
	listing="$(pvm_fetch_to_stdout "${_PVM_PIKE_BASE_URL}/")" || {
		pvm_err "failed to fetch version list from ${_PVM_PIKE_BASE_URL}"
		return 1
	}

	versions="$(pvm_parse_remote_versions "$listing")" || {
		pvm_err "failed to parse version list"
		return 1
	}

	local ver found=0
	while IFS= read -r ver; do
		[ -z "$ver" ] && continue

		# Apply pattern filter
		if [ -n "$pattern" ]; then
			case "$ver" in
				*$pattern*) ;;
				*) continue ;;
			esac
		fi

		# Mark installed versions
		local marker=""
		if pvm_is_version_installed "$ver"; then
			marker=" (installed)"
		fi

		printf '%s%s\n' "$ver" "$marker"
		found=1
	done <<-EOF
		${versions}
	EOF

	if [ "$found" -eq 0 ]; then
		pvm_info "No versions found matching '${pattern}'"
	fi
}

pvm_command_uninstall() {
	local version="$1"

	if [ -z "$version" ]; then
		pvm_err "version required: pvm uninstall <version>"
		return 1
	fi

	version="${version#v}"

	if ! pvm_is_version_installed "$version"; then
		pvm_err "Pike ${version} is not installed"
		return 1
	fi

	# Check if it's the current version
	local current=""
	if [ -n "${PVM_BIN:-}" ]; then
		current="$(printf '%s' "$PVM_BIN" | sed "s|${PVM_DIR}/versions/||" | cut -d/ -f1)"
	fi
	if [ "$version" = "$current" ]; then
		pvm_err "cannot uninstall the currently active version"
		pvm_err "Run 'pvm use <other-version>' first"
		return 1
	fi

	local version_path
	version_path="$(pvm_version_path "$version")"
	pvm_info "Uninstalling Pike ${version}..."
	rm -rf "$version_path" || {
		pvm_err "failed to remove $version_path"
		return 1
	}
	pvm_info "Uninstalled Pike ${version}"
}

pvm_command_alias() {
	local name="${1:-}"
	local version="${2:-}"

	if [ -z "$name" ]; then
		# List all aliases
		pvm_list_aliases
		return 0
	fi

	if [ -z "$version" ]; then
		# Print alias value
		local resolved
		resolved="$(pvm_get_alias "$name")" || {
			pvm_err "alias '${name}' not found"
			return 1
		}
		printf '%s -> %s\n' "$name" "$resolved"
		return 0
	fi

	# Validate version (must be installed or resolvable)
	version="${version#v}"
	pvm_set_alias "$name" "$version"
	pvm_info "Created alias ${name} -> ${version}"
}

pvm_command_unalias() {
	local name="$1"

	if [ -z "$name" ]; then
		pvm_err "alias name required: pvm unalias <name>"
		return 1
	fi

	pvm_remove_alias "$name" || {
		pvm_err "alias '${name}' not found"
		return 1
	}
	pvm_info "Removed alias ${name}"
}

pvm_command_default() {
	local version="${1:-}"

	if [ -z "$version" ]; then
		# Show current default
		local default_ver
		default_ver="$(pvm_get_alias "default")" || {
			pvm_err "no default version set"
			return 1
		}
		printf '%s\n' "$default_ver"
		return 0
	fi

	version="$(pvm_resolve_version "$version")" || {
		pvm_err "could not resolve version: $version"
		return 1
	}
	version="${version#v}"

	pvm_set_alias "default" "$version"
	pvm_info "Default version set to ${version}"
}

pvm_command_run() {
	local version="$1"
	shift

	if [ -z "$version" ]; then
		pvm_err "version required: pvm run <version> [args...]"
		return 1
	fi

	version="$(pvm_resolve_version "$version")" || {
		pvm_err "could not resolve version"
		return 1
	}
	version="${version#v}"

	if ! pvm_is_version_installed "$version"; then
		pvm_err "Pike ${version} is not installed"
		return 1
	fi

	local pike_bin
	pike_bin="$(pvm_version_path "$version")/bin/pike"
	exec "$pike_bin" "$@"
}

pvm_command_exec() {
	local version="$1"
	shift

	if [ -z "$version" ]; then
		pvm_err "version required: pvm exec <version> <command> [args...]"
		return 1
	fi

	version="$(pvm_resolve_version "$version")" || {
		pvm_err "could not resolve version"
		return 1
	}
	version="${version#v}"

	if ! pvm_is_version_installed "$version"; then
		pvm_err "Pike ${version} is not installed"
		return 1
	fi

	local bin_path
	bin_path="$(pvm_version_bin_path "$version")"

	PATH="${bin_path}:${PATH}" "$@"
}

pvm_command_which() {
	local version="${1:-}"

	if [ -z "$version" ]; then
		# Use current version
		if [ -n "${PVM_PIKE:-}" ] && [ -x "${PVM_PIKE}" ]; then
			printf '%s\n' "$PVM_PIKE"
			return 0
		fi
		pvm_err "no active Pike version"
		return 1
	fi

	version="$(pvm_resolve_version "$version")" || {
		pvm_err "could not resolve version"
		return 1
	}
	version="${version#v}"

	if ! pvm_is_version_installed "$version"; then
		pvm_err "Pike ${version} is not installed"
		return 1
	fi

	printf '%s\n' "$(pvm_version_path "$version")/bin/pike"
}

pvm_command_deactivate() {
	if [ -z "${PVM_BIN:-}" ]; then
		pvm_err "pvm is not active"
		return 1
	fi

	pvm_strip_pike_env
	pvm_strip_path
	unset PVM_BIN
	unset PVM_PIKE
	hash -r 2>/dev/null || true
	pvm_info "pvm deactivated"
}

pvm_command_cache() {
	local subcmd="${1:-}"

	case "$subcmd" in
		dir)
			printf '%s\n' "$(pvm_cache_dir)"
			;;
		clear)
			local cache_dir
			cache_dir="$(pvm_cache_dir)"
			if [ -d "$cache_dir" ]; then
				rm -rf "${cache_dir:?}"/*
				pvm_info "Cache cleared"
			else
				pvm_info "Cache directory does not exist"
			fi
			;;
		"")
			pvm_err "subcommand required: pvm cache <dir|clear>"
			return 1
			;;
		*)
			pvm_err "unknown cache subcommand: $subcmd"
			return 1
			;;
	esac
}

pvm_command_debug() {
	printf 'pvm version: %s\n' "$_PVM_VERSION"
	printf 'PVM_DIR: %s\n' "$PVM_DIR"
	printf 'OS: %s\n' "$(pvm_get_os)"
	printf 'Arch: %s\n' "$(pvm_get_arch)"
	printf 'PVM_BIN: %s\n' "${PVM_BIN:-<not set>}"
	printf 'PVM_PIKE: %s\n' "${PVM_PIKE:-<not set>}"
	printf 'SHELL: %s\n' "${SHELL:-<not set>}"
	printf 'PATH (pvm entries): %s\n' "$(printf '%s' "$PATH" | tr ':' '\n' | grep "${PVM_DIR}" | tr '\n' ':')"
	printf 'Default: %s\n' "$(pvm_get_alias "default" 2>/dev/null || echo '<not set>')"
	local pikerc
	pikerc="$(pvm_find_pikerc 2>/dev/null)" && printf '.pikerc: %s (%s)\n' "$pikerc" "$(head -1 "$pikerc" 2>/dev/null)" || printf '.pikerc: <not found>\n'
	printf 'curl: %s\n' "$(pvm_has curl && echo 'yes' || echo 'no')"
	printf 'wget: %s\n' "$(pvm_has wget && echo 'yes' || echo 'no')"
}

pvm_command_unload() {
	unset -f pvm
	unset -f pvm_err pvm_info pvm_has
	unset -f pvm_get_os pvm_get_arch
	unset -f pvm_parse_version pvm_version_compare pvm_version_major_minor
	unset -f pvm_version_path pvm_version_bin_path pvm_alias_path pvm_cache_dir pvm_cache_bin_dir
	unset -f pvm_is_version_installed
	unset -f pvm_get_alias pvm_set_alias pvm_remove_alias pvm_list_aliases
	unset -f pvm_find_pikerc pvm_read_pikerc
	unset -f pvm_resolve_version pvm_resolve_latest_installed pvm_resolve_latest
	unset -f pvm_fetch pvm_fetch_to_stdout
	unset -f pvm_parse_remote_versions pvm_get_latest_remote_version
	unset -f pvm_find_binary_slug
	unset -f pvm_download pvm_extract_binary pvm_install_binary pvm_install_source
	unset -f pvm_strip_path pvm_prepend_version_to_path
	unset -f pvm_command_install pvm_command_use pvm_command_current
	unset -f pvm_command_ls pvm_command_ls_remote
	unset -f pvm_command_uninstall
	unset -f pvm_command_alias pvm_command_unalias pvm_command_default
	unset -f pvm_command_run pvm_command_exec pvm_command_which
	unset -f pvm_command_deactivate pvm_command_cache pvm_command_debug pvm_command_unload
	unset _PVM_LOADED _PVM_VERSION _PVM_PIKE_BASE_URL
	printf 'pvm unloaded\n'
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

pvm() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
		install)   pvm_command_install "$@" ;;
		use)       pvm_command_use "$@" ;;
		current)   pvm_command_current ;;
		ls|list)   pvm_command_ls "$@" ;;
		ls-remote) pvm_command_ls_remote "$@" ;;
		uninstall) pvm_command_uninstall "$@" ;;
		alias)     pvm_command_alias "$@" ;;
		unalias)   pvm_command_unalias "$@" ;;
		default)   pvm_command_default "$@" ;;
		run)       pvm_command_run "$@" ;;
		exec)      pvm_command_exec "$@" ;;
		which)     pvm_command_which "$@" ;;
		deactivate) pvm_command_deactivate ;;
		cache)     pvm_command_cache "$@" ;;
		debug)     pvm_command_debug ;;
		unload)    pvm_command_unload ;;
		version|--version)
			printf 'pvm v%s\n' "$_PVM_VERSION"
			;;
		help|--help|-h)
			printf 'pvm — Pike Version Manager v%s\n\n' "$_PVM_VERSION"
			printf 'Usage: pvm <command> [options]\n\n'
			printf 'Commands:\n'
			printf '  install <ver>       Install a Pike version (--source, --binary, --latest)\n'
			printf '  use [ver]           Switch to a Pike version\n'
			printf '  current             Print the active version\n'
			printf '  ls [pattern]        List installed versions\n'
			printf '  ls-remote [pattern] List available versions\n'
			printf '  uninstall <ver>     Uninstall a Pike version\n'
			printf '  alias [name [ver]]  Manage version aliases\n'
			printf '  unalias <name>      Remove an alias\n'
			printf '  default [ver]       Set or show default version\n'
			printf '  run <ver> [args]    Run pike with a specific version\n'
			printf '  exec <ver> <cmd>    Run a command with Pike on PATH\n'
			printf '  which [ver]         Print path to pike binary\n'
			printf '  deactivate          Remove pvm from PATH\n'
			printf '  cache <dir|clear>   Manage download cache\n'
			printf '  debug               Print diagnostic information\n'
			printf '  unload              Remove pvm from current shell\n'
			printf '  version             Print pvm version\n'
			printf '  help                Show this help message\n'
			;;
		"")
			pvm_err "command required. Run 'pvm help' for usage."
			return 1
			;;
		*)
			pvm_err "unknown command: $command"
			pvm_err "Run 'pvm help' for usage."
			return 1
			;;
	esac
}

# ---------------------------------------------------------------------------
# Auto-use on shell startup
# ---------------------------------------------------------------------------

# Auto-use the default or .pikerc version if PVM_AUTO_USE is set
if [ "${PVM_AUTO_USE:-}" = "true" ]; then
	pvm_command_use 2>/dev/null || true
fi
