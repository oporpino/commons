#!/bin/bash
# WeHive Core - Main CLI Entry Point

wehive_help() {
    cat << 'EOF'
WeHive Infrastructure CLI

Usage: wehive <command> [subcommand] [args...]

Commands:
  helpers      Utility helpers
  cloudflare   Cloudflare operations (alias: cf)

Helpers:
  wehive helpers env:load    Load environment (idempotent)
                             Usage: eval "$(wehive helpers env:load)"

Cloudflare DNS:
  wehive cloudflare dns find <subdomain>      Find DNS records
  wehive cloudflare dns list                  List all DNS records
  wehive cloudflare dns create <subdomain> <ip>  Create DNS record
  wehive cloudflare dns delete <subdomain>    Delete DNS records

  cf dns <command>           Alias for 'wehive cloudflare dns'

Examples:
  # Load environment
  eval "$(wehive helpers env:load)"

  # DNS management
  wehive cloudflare dns find messagebroker
  cf dns delete messagebroker
  cf dns create messagebroker 1.2.3.4

EOF
}

# Main command router
wehive_main() {
    # Store script location for helpers to find project root
    export WEHIVE_SCRIPT="$0"

    if [ $# -eq 0 ]; then
        wehive_help
        return 0
    fi

    local command="$1"
    shift

    case "$command" in
        helpers)
            wehive_helpers "$@"
            ;;
        cloudflare)
            wehive_cloudflare "$@"
            ;;
        -h|--help|help)
            wehive_help
            ;;
        *)
            echo "Unknown command: $command" >&2
            echo "Run 'wehive help' for usage" >&2
            return 1
            ;;
    esac
}

# Execute main if this is the entry point
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    wehive_main "$@"
fi
