#!/usr/bin/env bash
# Probe a suspected Tuya/ESP IoT device on the local network
# Usage: ./probe-tuya-device.sh <IP_ADDRESS>

set -e

IP="${1:-192.168.1.3}"
echo "=== Probing $IP ==="
echo ""

# Check if host is alive
if ! ping -c 1 -W 2 "$IP" >/dev/null 2>&1; then
    echo "Host $IP is NOT responding to ping"
    exit 1
fi
echo "Host $IP is UP"
echo ""

# Check common ports
echo "=== Port Scan (bash-only, no root) ==="
for port in 80 443 6668 8080; do
    if (echo >"/dev/tcp/$IP/$port") 2>/dev/null; then
        echo "Port $port: OPEN"
    else
        echo "Port $port: CLOSED"
    fi
done
echo ""

# Try HTTP probe if port 80 is open
if (echo >/dev/tcp/$IP/80) 2>/dev/null; then
    echo "=== HTTP Probe ==="
    curl -s --connect-timeout 3 "http://$IP/" -A "Mozilla/5.0" | head -20 || echo "No HTTP response"
    echo ""
fi

# Show ARP entry
if command -v arp >/dev/null 2>&1; then
    echo "=== ARP Entry ==="
    arp -a | grep "$IP" | grep -v "incomplete" || echo "No ARP entry found"
fi

echo ""
echo "=== Diagnosis ==="
if (echo >/dev/tcp/$IP/6668) 2>/dev/null; then
    echo "Tuya device detected (port 6668 open)"
    echo "Control: Use official app, or physical button press"
elif (echo >/dev/tcp/$IP/80) 2>/dev/null; then
    echo "HTTP service found — may have web UI"
else
    echo "No recognized service ports — device may be cloud-only"
fi
