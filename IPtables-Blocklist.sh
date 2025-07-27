#!/bin/bash

# Description:
#   Reads a list of ASNs from a text file (with optional inline comments)
#   Queries bgpview.io for their IP prefixes
#   Prints or applies iptables/ip6tables rules to block them

# Usage:
#   ./block_asns.sh asns.txt             # Dry run (print rules only)
#   sudo ./block_asns.sh --apply asns.txt # Apply rules via iptables

APPLY=false

# Check for --apply or -a flag
if [[ "$1" == "-a" || "$1" == "--apply" ]]; then
    APPLY=true
    shift
fi

ASN_FILE="$1"

if [[ ! -f "$ASN_FILE" ]]; then
    echo "Error: ASN input file not found: $ASN_FILE"
    exit 1
fi

# Check required tool: jq
if ! command -v jq &>/dev/null; then
    echo "Error: 'jq' is required but not installed. Try: sudo apt install jq"
    exit 1
fi

# Process ASNs, skipping empty lines and full-line comments
grep -vE '^\s*#|^\s*$' "$ASN_FILE" | while read -r LINE; do
    # Strip inline comment and whitespace
    ASN=$(echo "$LINE" | cut -d'#' -f1 | tr -d '[:space:]')

    # Validate ASN format
    if [[ ! "$ASN" =~ ^[0-9]+$ ]]; then
        echo "Skipping invalid ASN line: $LINE"
        continue
    fi

    echo "🔍 Fetching prefixes for AS$ASN..."

    RESPONSE=$(curl -s "https://api.bgpview.io/asn/$ASN/prefixes")

    if [[ -z "$RESPONSE" ]]; then
        echo "Failed to fetch data for AS$ASN"
        continue
    fi

    # IPv4 prefixes
    echo "$RESPONSE" | jq -r '.data.ipv4_prefixes[].prefix' | while read -r PREFIX; do
        CMD="iptables -A INPUT -s $PREFIX -j DROP"
        if $APPLY; then
            echo "Applying: $CMD"
            sudo $CMD
        else
            echo "$CMD"
        fi
    done

    # IPv6 prefixes
    echo "$RESPONSE" | jq -r '.data.ipv6_prefixes[].prefix' | while read -r PREFIX; do
        CMD="ip6tables -A INPUT -s $PREFIX -j DROP"
        if $APPLY; then
            echo "Applying: $CMD"
            sudo $CMD
        else
            echo "$CMD"
        fi
    done

done

