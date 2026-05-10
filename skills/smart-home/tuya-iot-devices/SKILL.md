---
name: tuya-iot-devices
description: "Discover, identify, and control Tuya-ecosystem IoT devices on the local network. Covers smart plugs, sockets, and switches from brands like Wipro, Sonoff, generic Tuya OEM."
version: 1.0.0
author: agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Smart-Home, IoT, Tuya, Wipro, Sonoff, Smart-Plug, LAN, ESP8266]
    related_skills: [openhue]
prerequisites:
  commands: [curl, arp, ping]
optional:
  commands: [nmap]
  pip: [tinytuya]
---

# Tuya IoT Devices on LAN

The Tuya cloud ecosystem powers many smart-home brands (Wipro, Sonoff, generic smart plugs, some white-label devices). They share common network fingerprints and a shared discovery/control model.

This skill covers **LAN-side identification** and **basic control** when cloud credentials are unavailable. It does NOT provide cloud keys — see the Pitfalls section for why.

## When to Use

- User says "turn off the smart socket", "reboot the plug", "my Wipro socket..."
- A device with hostname `ESP_*` or unknown IoT MAC appears on Wi-Fi
- Need to identify what that `192.168.1.X` device actually is
- Physical reset/reboot is required (power cycle, button press)

## Network Discovery (no root, no nmap)

### Step 1 — Who is online?

```bash
# List ARP table (learns recently active hosts)
arp -a | grep -v "incomplete\|255"

# Confirm which IPs are alive (fast, bash-only, no root)
for ip in $(seq 1 30); do
  (echo >/dev/tcp/192.168.1.$ip/80) 2>/dev/null && echo "192.168.1.$ip UP"
done
```

### Step 2 — Identify by open ports

Tuya devices expose **port 6668/tcp** (native Tuya local protocol) when online:

```bash
for port in 80 443 6668 8080; do
  (echo >/dev/tcp/192.168.1.3/$port) 2>/dev/null && echo "Port $port OPEN" || echo "Port $port CLOSED"
done
```

Signature:
- `6668 OPEN` → very likely a Tuya device
- `80 OPEN` → may have a web config page (some OEMs expose it)
- `80 CLOSED` → cloud-only device, needs app / local keys

### Step 3 — Probe HTTP if any port responds

```bash
curl -s --connect-timeout 3 "http://192.168.1.3/" -A "Mozilla/5.0" | head -20
```

No output is normal — most Tuya plugs do NOT expose HTTP.

## Device Identification Table

| Fingerprint | Likely Device | Notes |
|---|---|---|
| Hostname `ESP_*` + port 6668 | Tuya/Wipro/Sonoff smart plug/switch/bulb | ESP8266/ESP32 chipset |
| Hostname `TP-Link_*` | Range extender / router | Not a plug |
| MAC vendor `Espressif` | ESP-based IoT | Check `arp -a` vendors |
| Port 6668 only | Tuya native device | Needs localKey for control |

## Control Paths

### Option A: Via Official App (Wipro Next Smart Home, Smart Life, Tuya Smart)

- Always works if the device was set up with the app.
- Use brand-specific app → tap device → toggle power / reboot from UI.
- This is the **fastest path**; recommend it first when credentials are unknown.

### Option B: Local control with TinyTuya (requires localKey)

Prerequisites: `pip install tinytuya`

Requires the **device ID** and **local key** extracted from the app. Without these, API control is impossible.

```python
import tinytuya

d = tinytuya.OutletDevice('DEVICE_ID_HERE', '192.168.1.3', 'LOCAL_KEY_HERE')
d.set_version(3.3)
d.turn_off()
```

### Option C: Physical Button / Power Cycle (always works)

**Power cycle (most reliable reboot):**
1. Unplug the socket from the wall outlet (or turn off the wall switch).
2. Wait 5 seconds.
3. Plug back in.
4. Device reconnects to Wi-Fi in 10–30 seconds.

**Using the device button:**
| Action | Button Press | Result |
|---|---|---|
| Toggle ON/OFF | Short press (< 1 sec) | Switches power state |
| Reboot | Long press (5–10 sec) | LED blinks, device reboots |
| Factory Reset | Very long press (> 15 sec) | Wipes Wi-Fi config — ⚠️ avoid unless intended |

## Reboot Scenarios

If the user asks to "reboot the socket / plug / switch":
1. Try Option A (app) first if the user has the app.
2. If no app / no cloud access → suggest **power cycle** (unplug + wait + plug).
3. TinyTuya is only viable if the user can provide or extract `localKey`.

## Quick Reference Script

Use the script `scripts/probe-tuya-device.sh` to fingerprint a local IP in one shot.

## Pitfalls

- **Port 6668 ≠ open control.** It means the Tuya protocol listener is running. Unless you have `localKey`, you cannot issue commands.
- **HTTP endpoints missing.** Tuya plugs rarely expose HTTP. Do not waste time trying `/toggle`, `/off`, `/api` paths unless port 80 is actually open.
- **Home Assistant ≠ automatic access.** If Home Assistant controls the device, ask the user to toggle via HA UI or expose HA API.
- **Voice assistants.** If Alexa/Google Home is linked, voice commands work — but Hermes does not auto-link to Alexa without explicit integration.
- **Do not guess localKey.** Key extraction requires app credentials or the mobile app's developer mode. Hermes does not have a built-in Tuya key extractor.
- **Router block as reboot alternative.** Blocking the MAC at the router disconnects it from Wi-Fi but does NOT power-cycle the plug. That is a network-isolation action, not a reboot.

## Related References

- `references/tuya-port-signatures.md` — Common open-port maps for other IoT families.
