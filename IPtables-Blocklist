#!/bin/bash

# Check for required tools
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but not installed. Install with: sudo apt install jq"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but not installed."; exit 1; }

# Usage message
usage() {
    echo "Usage: $0 [--apply] <asn_input_file>"
    echo "  --apply    Actually execute iptables commands"
    exit 1
}

# Parse arguments
APPLY=false
if [ "$1" == "--apply" ]; then
    APPLY=true
    shift
fi

# Ensure input file is provided
if [ $# -ne 1 ]; then
    usage
fi

ASN_FILE="$1"
if [ ! -f "$ASN_FILE" ]; then
    echo "Error: File '$ASN_FILE' not found."
    exit 1
fi

while IFS= read -r ASN; do
    ASN_CLEAN=$(echo "$ASN" | tr -d '[:space:]')
    if [[ ! "$ASN_CLEAN" =~ ^[0-9]+$ ]]; then
        echo "Skipping invalid ASN: $ASN_CLEAN"
        continue
    fi

    echo "Fetching prefixes for AS$ASN_CLEAN..."

    PREFIXES=$(curl -s "https://api.bgpview.io/asn/$ASN_CLEAN/prefixes" | jq -r '.data.ipv4_prefixes[].prefix')

    if [ -z "$PREFIXES" ]; then
        echo "No prefixes found for AS$ASN_CLEAN"
        continue
    fi

    for IP in $PREFIXES; do
        CMD="iptables -A INPUT -s $IP -j DROP"
        if $APPLY; then
            echo "Applying: $CMD"
            sudo $CMD
        else
            echo "$CMD"
        fi
    done

done < "$ASN_FILE"
