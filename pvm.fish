# pvm.fish — Fish shell integration for pvm (Pike Version Manager)
# This file is sourced by Fish shell. Do not execute directly.
# Requires pvm.sh to be in $PVM_DIR/pvm.sh

set -g PVM_FISH_VERSION "0.2.0"

# Determine PVM_DIR if not set
if not set -q PVM_DIR
    set -gx PVM_DIR "$HOME/.pvm"
end

# Private function to call pvm.sh in bash and capture output
function __pvm_bash -d "Execute pvm command in bash subshell"
    bash -c "source '$PVM_DIR/pvm.sh' 2>/dev/null; pvm $argv"
end

# Private function to get current version from Fish environment
function __pvm_current -d "Get the current Pike version from Fish env"
    if set -q PVM_BIN && test -d "$PVM_BIN"
        # Extract version from PVM_BIN path
        string replace -r ".*/versions/" "" "$PVM_BIN" | string replace -r "/.*" ""
    else
        return 1
    end
end

# Main pvm function
function pvm -d "Pike Version Manager"
    set -l cmd "$argv[1]"
    set -e argv[1]

    switch "$cmd"
        # Commands that don't mutate caller state — delegate to bash subshell
        case install ls list ls-remote uninstall alias unalias default run exec which cache debug help version
            __pvm_bash $cmd $argv
            return $status

        # Commands that mutate caller state — handle in Fish
        case use
            __pvm_use $argv
            return $status

        case deactivate
            __pvm_deactivate
            return $status

        case current
            __pvm_current
            return $status

        case unload
            __pvm_unload
            return $status

        case ""
            echo "pvm: command required. Run 'pvm help' for usage." >&2
            return 1

        case "*"
            echo "pvm: unknown command: $cmd" >&2
            echo "Run 'pvm help' for usage." >&2
            return 1
    end
end

# Handle 'pvm use <version>'
function __pvm_use -d "Switch to a Pike version (Fish-native)"
    set -l version "$argv[1]"

    # Call pvm _fish use to get environment setup
    set -l output (__pvm_bash _fish use $version 2>&1)
    set -l status $status

    if test $status -ne 0
        echo "pvm: $output" >&2
        return 1
    end

    # Parse the output and apply environment changes
    for line in $output
        set -l parts (string split '=' $line 1)
        if test (count $parts) -ge 2
            set -l key $parts[1]
            set -l value $parts[2]
            # Strip empty values (key= with nothing after)
            if test -z "$value"
                # Unset the variable
                set -e "$key" 2>/dev/null
            else
                # Set the variable
                set -gx "$key" "$value"
            end
        else
            # Output the variable name for unsetting (no value = key only)
            set -l var (string trim "$line")
            if test -n "$var"
                set -e "$var" 2>/dev/null
            end
        end
    end

    # Replace Fish's PATH with the new value
    if set -q PVM_PATH
        set -gx PATH $PVM_PATH
        set -e PVM_PATH
    end

    # Update PATH to include the Pike version's bin directory
    if set -q PVM_BIN
        # Remove any existing pvm paths from PATH
        set -l new_path
        for p in $PATH
            if not string match -q "$PVM_DIR/versions/*" "$p"
                set -a new_path $p
            end
        end
        set -gx PATH $PVM_BIN $new_path
    end

    # Print version if available
    if set -q PVM_PIKE_VERSION
        echo "Now using Pike $PVM_PIKE_VERSION"
    end
end

# Handle 'pvm deactivate'
function __pvm_deactivate -d "Remove pvm from PATH (Fish-native)"
    # Call pvm _fish deactivate to get the clean PATH
    set -l output (__pvm_bash _fish deactivate 2>&1)
    set -l status $status

    if test $status -ne 0
        echo "pvm: $output" >&2
        return 1
    end

    # Parse the output and unset variables
    for line in $output
        set -l parts (string split '=' $line 1)
        if test (count $parts) -ge 2
            set -l key $parts[1]
            set -l value $parts[2]
            set -gx "$key" "$value"
        else
            # Variable name only — unset it
            set -l var (string trim "$line")
            if test -n "$var"
                set -e "$var" 2>/dev/null
            end
        end
    end

    # Replace Fish's PATH with the clean value
    if set -q PVM_PATH
        set -gx PATH $PVM_PATH
        set -e PVM_PATH
    end

    echo "pvm: deactivated"
end

# Handle 'pvm unload'
function __pvm_unload -d "Remove pvm from current Fish shell"
    # Unset all pvm environment variables
    set -e PVM_DIR 2>/dev/null
    set -e PVM_BIN 2>/dev/null
    set -e PVM_PIKE 2>/dev/null
    set -e PVM_PIKE_HOME 2>/dev/null
    set -e PVM_PIKE_VERSION 2>/dev/null
    set -e PVM_AUTO_USE 2>/dev/null
    set -e PIKE_MODULE_PATH 2>/dev/null
    set -e PIKE_INCLUDE_PATH 2>/dev/null
    set -e PIKE_MASTER 2>/dev/null

    # Remove pvm functions
    functions -e pvm 2>/dev/null
    functions -e __pvm_use 2>/dev/null
    functions -e __pvm_deactivate 2>/dev/null
    functions -e __pvm_current 2>/dev/null
    functions -e __pvm_unload 2>/dev/null
    functions -e __pvm_bash 2>/dev/null

    # Remove pvm paths from PATH
    set -l new_path
    for p in $PATH
        if not string match -q "$HOME/.pvm/versions/*" "$p"
            set -a new_path $p
        end
    end
    set -gx PATH $new_path

    echo "pvm unloaded"
end

# Register tab completions
complete -c pvm -f -a "install" -d "Install a Pike version"
complete -c pvm -f -a "use" -d "Switch to a Pike version"
complete -c pvm -f -a "current" -d "Print the active version"
complete -c pvm -f -a "ls" -d "List installed versions"
complete -c pvm -f -a "ls-remote" -d "List available versions"
complete -c pvm -f -a "uninstall" -d "Uninstall a Pike version"
complete -c pvm -f -a "alias" -d "Manage version aliases"
complete -c pvm -f -a "unalias" -d "Remove an alias"
complete -c pvm -f -a "default" -d "Set or show default version"
complete -c pvm -f -a "run" -d "Run pike with a specific version"
complete -c pvm -f -a "exec" -d "Run a command with Pike on PATH"
complete -c pvm -f -a "which" -d "Print path to pike binary"
complete -c pvm -f -a "deactivate" -d "Remove pvm from PATH"
complete -c pvm -f -a "cache" -d "Manage download cache"
complete -c pvm -f -a "debug" -d "Print diagnostic information"
complete -c pvm -f -a "unload" -d "Remove pvm from current shell"
complete -c pvm -f -a "version" -d "Print pvm version"
complete -c pvm -f -a "help" -d "Show help message"

# Auto-use the default or .pikerc version if PVM_AUTO_USE is set
if set -q PVM_AUTO_USE; and test "$PVM_AUTO_USE" = "true"
    pvm use 2>/dev/null; or true
end
