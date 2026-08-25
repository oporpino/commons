#!/bin/bash
# WeHive Cloudflare Module
# Commands: wehive cloudflare dns find|list|create|delete
# Alias: cf='wehive cloudflare'

wehive_cloudflare_dns_find() {
    local subdomain="$1"

    if [ -z "$subdomain" ]; then
        echo "❌ Usage: wehive cloudflare dns find <subdomain>" >&2
        return 1
    fi

    # Validate credentials
    if [ -z "$TF_VAR_cloudflare_zone_id" ] || [ -z "$TF_VAR_cloudflare_api_token" ]; then
        echo "❌ Cloudflare credentials not configured" >&2
        echo "   Required: TF_VAR_cloudflare_zone_id and TF_VAR_cloudflare_api_token" >&2
        return 1
    fi

    local zone_id="$TF_VAR_cloudflare_zone_id"
    local cf_token="$TF_VAR_cloudflare_api_token"
    local domain="${TF_VAR_domain:-ibft.app}"

    echo "🔍 Searching DNS records for: $subdomain.$domain"

    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$subdomain.$domain" \
        -H "Authorization: Bearer $cf_token" \
        -H "Content-Type: application/json")

    if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
        local records=$(echo "$response" | jq -r '.result[] | "\(.id)\t\(.content)\t\(.name)"' 2>/dev/null)

        if [ -n "$records" ]; then
            echo "Found records:"
            echo "$records" | while IFS=$'\t' read -r id ip name; do
                echo "  ID: $id"
                echo "  IP: $ip"
                echo "  Name: $name"
                echo ""
            done
        else
            echo "  ℹ️  No DNS records found"
        fi
    else
        echo "❌ Cloudflare API error" >&2
        echo "   $(echo "$response" | jq -r '.errors[0].message' 2>/dev/null || echo 'Unknown error')" >&2
        return 1
    fi
}

wehive_cloudflare_dns_list() {
    # Validate credentials
    if [ -z "$TF_VAR_cloudflare_zone_id" ] || [ -z "$TF_VAR_cloudflare_api_token" ]; then
        echo "❌ Cloudflare credentials not configured" >&2
        echo "   Required: TF_VAR_cloudflare_zone_id and TF_VAR_cloudflare_api_token" >&2
        return 1
    fi

    local zone_id="$TF_VAR_cloudflare_zone_id"
    local cf_token="$TF_VAR_cloudflare_api_token"

    echo "📋 Listing all DNS records in zone..."

    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A" \
        -H "Authorization: Bearer $cf_token" \
        -H "Content-Type: application/json")

    if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
        local records=$(echo "$response" | jq -r '.result[] | "\(.id)\t\(.content)\t\(.name)"' 2>/dev/null)

        if [ -n "$records" ]; then
            echo "$records" | while IFS=$'\t' read -r id ip name; do
                echo "  ID: $id"
                echo "  IP: $ip"
                echo "  Name: $name"
                echo ""
            done
        else
            echo "  ℹ️  No DNS records found"
        fi
    else
        echo "❌ Cloudflare API error" >&2
        echo "   $(echo "$response" | jq -r '.errors[0].message' 2>/dev/null || echo 'Unknown error')" >&2
        return 1
    fi
}

wehive_cloudflare_dns_create() {
    local subdomain="$1"
    local ip="$2"

    if [ -z "$subdomain" ] || [ -z "$ip" ]; then
        echo "❌ Usage: wehive cloudflare dns create <subdomain> <ip>" >&2
        return 1
    fi

    # Validate credentials
    if [ -z "$TF_VAR_cloudflare_zone_id" ] || [ -z "$TF_VAR_cloudflare_api_token" ]; then
        echo "❌ Cloudflare credentials not configured" >&2
        echo "   Required: TF_VAR_cloudflare_zone_id and TF_VAR_cloudflare_api_token" >&2
        return 1
    fi

    local zone_id="$TF_VAR_cloudflare_zone_id"
    local cf_token="$TF_VAR_cloudflare_api_token"
    local domain="${TF_VAR_domain:-ibft.app}"

    echo "➕ Creating DNS record: $subdomain.$domain → $ip"

    local response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
        -H "Authorization: Bearer $cf_token" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$subdomain\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}")

    if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
        local record_id=$(echo "$response" | jq -r '.result.id')
        echo "✅ DNS record created successfully!"
        echo "   ID: $record_id"
    else
        echo "❌ Failed to create DNS record" >&2
        echo "   $(echo "$response" | jq -r '.errors[0].message' 2>/dev/null || echo 'Unknown error')" >&2
        return 1
    fi
}

wehive_cloudflare_dns_delete() {
    local subdomain="$1"

    if [ -z "$subdomain" ]; then
        echo "❌ Usage: wehive cloudflare dns delete <subdomain>" >&2
        return 1
    fi

    # Validate credentials
    if [ -z "$TF_VAR_cloudflare_zone_id" ] || [ -z "$TF_VAR_cloudflare_api_token" ]; then
        echo "❌ Cloudflare credentials not configured" >&2
        echo "   Required: TF_VAR_cloudflare_zone_id and TF_VAR_cloudflare_api_token" >&2
        return 1
    fi

    local zone_id="$TF_VAR_cloudflare_zone_id"
    local cf_token="$TF_VAR_cloudflare_api_token"
    local domain="${TF_VAR_domain:-ibft.app}"

    echo "🗑️  Deleting DNS records for: $subdomain.$domain"

    # Get all A records for subdomain
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$subdomain.$domain" \
        -H "Authorization: Bearer $cf_token" \
        -H "Content-Type: application/json")

    if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
        local records=$(echo "$response" | jq -r '.result[].id' 2>/dev/null || echo "")

        if [ -n "$records" ]; then
            local record_count=$(echo "$records" | wc -l | tr -d ' ')
            echo "   Found $record_count record(s)"

            local deleted=0
            for record_id in $records; do
                echo "   Deleting record: $record_id"
                local delete_response=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
                    -H "Authorization: Bearer $cf_token" \
                    -H "Content-Type: application/json")

                if echo "$delete_response" | jq -e '.success == true' >/dev/null 2>&1; then
                    deleted=$((deleted + 1))
                else
                    echo "   ⚠️  Failed to delete record $record_id"
                fi
            done

            echo "✅ Deleted $deleted/$record_count DNS record(s)"
        else
            echo "   ℹ️  No DNS records found"
        fi
    else
        echo "❌ Cloudflare API error" >&2
        echo "   $(echo "$response" | jq -r '.errors[0].message' 2>/dev/null || echo 'Unknown error')" >&2
        return 1
    fi
}

wehive_cloudflare_dns() {
    local subcommand="$1"
    shift

    case "$subcommand" in
        find)
            wehive_cloudflare_dns_find "$@"
            ;;
        list)
            wehive_cloudflare_dns_list "$@"
            ;;
        create)
            wehive_cloudflare_dns_create "$@"
            ;;
        delete)
            wehive_cloudflare_dns_delete "$@"
            ;;
        *)
            echo "Unknown dns subcommand: $subcommand" >&2
            echo "Available: find, list, create, delete" >&2
            return 1
            ;;
    esac
}

wehive_cloudflare() {
    local subcommand="$1"
    shift

    case "$subcommand" in
        dns)
            wehive_cloudflare_dns "$@"
            ;;
        *)
            echo "Unknown cloudflare subcommand: $subcommand" >&2
            echo "Available: dns" >&2
            return 1
            ;;
    esac
}

# Setup alias
alias cf='wehive cloudflare'
