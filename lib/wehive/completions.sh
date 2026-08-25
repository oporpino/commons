#!/bin/bash
# WeHive Bash Completions

_wehive_completions() {
    local cur prev words cword

    # Manual initialization (compatible with all bash versions)
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # Get the command hierarchy
    local cmd="${words[1]:-}"
    local subcmd="${words[2]:-}"
    local subsubcmd="${words[3]:-}"

    # Handle 'cf' alias - treat as 'cloudflare dns'
    if [ "${words[0]}" = "cf" ]; then
        # Shift the perspective: cf is cloudflare dns
        case "$cword" in
            1)
                # cf <tab> → dns subcommands
                COMPREPLY=($(compgen -W "dns" -- "$cur"))
                return 0
                ;;
            2)
                # cf dns <tab> → dns operations
                COMPREPLY=($(compgen -W "find list create delete" -- "$cur"))
                return 0
                ;;
        esac
    fi

    case "$cword" in
        1)
            # Top level commands
            COMPREPLY=($(compgen -W "helpers cloudflare help" -- "$cur"))
            ;;
        2)
            # Second level
            case "$cmd" in
                helpers)
                    COMPREPLY=($(compgen -W "env:load" -- "$cur"))
                    ;;
                cloudflare)
                    COMPREPLY=($(compgen -W "dns" -- "$cur"))
                    ;;
            esac
            ;;
        3)
            # Third level
            if [ "$cmd" = "cloudflare" ] && [ "$subcmd" = "dns" ]; then
                COMPREPLY=($(compgen -W "find list create delete" -- "$cur"))
            fi
            ;;
    esac
}

# Register completions
complete -F _wehive_completions wehive

# Alias completions
complete -F _wehive_completions cf
