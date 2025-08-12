#!/usr/bin/env python3
import ipaddress
import sys

def range_to_cidrs(start_ip: str, end_ip: str):
    """Convert an inclusive IP range to the minimal set of CIDR blocks."""
    start = ipaddress.IPv4Address(start_ip)
    end = ipaddress.IPv4Address(end_ip)
    networks = ipaddress.summarize_address_range(start, end)
    return [str(net) for net in networks]

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <start_ip> <end_ip>")
        print(f"Example: {sys.argv[0]} 45.226.180.0 45.226.183.0")
        sys.exit(1)

    start_ip = sys.argv[1]
    end_ip = sys.argv[2]

    cidrs = range_to_cidrs(start_ip, end_ip)
    print(f"Input range: {start_ip} -> {end_ip}")
    print("Minimal CIDR blocks:")
    for c in cidrs:
        print(c)
