---
name: smart-home-casting
description: "Cast images, messages, and media to smart TVs and displays on the local network. Covers Chromecast / Google Cast, Android TV, and any DLNA/AirPlay-capable screen reachable over Wi-Fi."
version: 1.0.0
author: agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [smart-home, chromecast, android-tv, casting, media, pychromecast, network]
    related_skills: [tuya-iot-devices, openhue]
prerequisites:
  commands: [python3, curl, arp, ping]
  pip: [pychromecast, Pillow]
---

# Smart Home Casting

Cast images, media, and messages to smart TVs and displays on the local network (Chromecast, Android TV, AirPlay, DLNA).

## When to Use

- User says "send a message to my TV", "cast to my TV", "show this on my smart TV"
- User has a VU/Samsung/LG/Sony/Android TV or Chromecast device
- Need to display an image, notification, or media on a big screen
- Wants to put a message on a shared display in a society, office, or home

## Discovery

### Step 1 — Find Chromecast / Android TV on the LAN

Use `pychromecast` discovery (pure Python, no root, no nmap):

```python
import pychromecast

services, browser = pychromecast.discovery.discover_chromecasts(timeout=15)
for svc in services:
    print(f"{svc.friendly_name} at {svc.host}:{svc.port}")
    print(f"  Model: {svc.model_name}, UUID: {svc.uuid}")

# Connect and check status
chromecasts, _ = pychromecast.get_chromecasts()
cast = chromecasts[0]  # or filter by name
cast.wait()
print(cast.name)        # e.g. "rithvi tv"
print(cast.status.display_name)  # e.g. "YouTube"
```

### Step 2 — Fallback port probe (if mDNS fails)

Chromecast / Android TV exposes ports `8008` and `8009`. Quick check:

```python
import urllib.request
for ip in ['192.168.1.6', '192.168.1.12']:
    try:
        req = urllib.request.Request(f'http://{ip}:8008', headers={'User-Agent': 'Mozilla/5.0'})
        rsp = urllib.request.urlopen(req, timeout=2)
        print(f"{ip}:8008 responded [{rsp.status}] — likely Android TV/Chromecast")
    except Exception:
        pass
```

### Step 3 — Identify the TV brand

Common smart TV models and their chromecast identifiers:

| Displayed `model_name` | Likely Brand | Notes |
|---|---|---|
| `HAT4KDTV` | VU (India) | VU Android TV — built-in Chromecast |
| `Chromecast` | Google Chromecast | Dongle / puck |
| `Chromecast Ultra` | Google 4K puck | Has Ethernet port |
| `Chromecast HD` | Google 1080p | Newer budget model |
| `SHIELD Android TV` | NVIDIA SHIELD | Gaming + streaming box |
| `BRAVIA` | Sony | Bravia Android TV |
| `webOSTV` | LG | May NOT expose Chromecast (uses AirPlay/DLNA) |

## Image Casting Workflow

### Full pipeline: Create image → serve over LAN → cast to TV

```python
import pychromecast
from PIL import Image, ImageDraw, ImageFont
import os

# 1. Create the image
width, height = 1920, 1080
img = Image.new('RGB', (width, height), color='black')
draw = ImageDraw.Draw(img)

font_size = 100
for font_path in ['/System/Library/Fonts/Helvetica.ttc',
                    '/System/Library/Fonts/Arial.ttf']:
    try:
        font = ImageFont.truetype(font_path, font_size)
        break
    except:
        font = ImageFont.load_default()

message = "Hello from Hermes!\nTV display message"

bbox = draw.multiline_textbbox((0, 0), message, font=font, spacing=20)
x = (width - (bbox[2]-bbox[0])) // 2
y = (height - (bbox[3]-bbox[1])) // 2
draw.multiline_text((x, y), message, fill='white', font=font,
                    spacing=20, align='center')

img.save('/tmp/tv_message.png')

# 2. Serve the image (run in background)
#    terminal(background=True, command="python3 -m http.server 8765 --directory /tmp")

# 3. Cast to TV
image_url = f'http://192.168.1.20:8765/tv_message.png'  # sender's LAN IP

chromecasts, _ = pychromecast.get_chromecasts()
cast = next(c for c in chromecasts if c.name == 'rithvi tv')
cast.wait()

mc = cast.media_controller
mc.play_media(
    image_url,
    content_type='image/png',
    title='Hermes Message',
    thumb=image_url
)
```

### Verifying the cast succeeded

```python
import time; time.sleep(3)
print(mc.status.player_state)  # Should print "PLAYING"
```

## Pitfalls

- **TV must be ON and on Wi-Fi.** Deep standby disconnects Wi-Fi → discover_chromecasts() returns nothing. Wake the TV first.
- **HTTP server must bind to the same LAN as the TV.** If the sender is on a VPN or guest network, the TV cannot reach the URL. Ensure `python3 -m http.server` binds to `0.0.0.0` (default).
- **Image URL must be LAN-reachable, not localhost.** Use the sender's LAN IP (`192.168.1.X`), not `localhost` or `127.0.0.1`.
- **No local firewall blocking port.** macOS may prompt to allow the Python binary to accept incoming connections. Approve it.
- **Port 8008 vs 8009.** Port 8008 serves HTTP REST (device info); 8009 is the protobuf cast receiver channel. Do not confuse them when probing.
- **LG webOS TVs may not appear.** They use AirPlay/DLNA, not Chromecast. See `references/airplay-casting.md` for webOS alternatives.
- **Samsung Smart TVs** also often lack Chromecast. They use Miracast / SmartThings instead.
- **`pychromecast` v14 attribute changes.** In v14+, use `cast.name` not `cast.device.friendly_name`, and `cast.status.display_name` not `cast.device.model_name`. Do not access `cast.device` or `cast.host` directly.
- **TV INPUT / SOURCE must be set to Chromecast.** Even when `player_state` shows `BUFFERING`, the TV screen may still show Cable/HDMI/Set-top Box. The user must manually switch the TV input to Chromecast/Screen Mirroring via remote SOURCE button. This is the #1 cause of "cast command succeeded but screen is blank". Always verify with the user — do not assume the TV is on the right input.
- **Images often land in `PAUSED` state; MP4 videos are more reliable.** Static PNG casting frequently ends up `PAUSED` on Android TV. Converting to a short MP4 (2+ seconds, 1+ fps) via `imageio` + `imageio-ffmpeg` and casting with `content_type='video/mp4'` yields `BUFFERING` → `PLAYING` far more consistently. If an image cast fails, fall back to video.
- **`imageio` uses `pixelformat`, not `pixelfmt`.** The `imageio.get_writer(..., pixelformat='yuv420p')` parameter name is `pixelformat` (full word). Passing `pixelfmt` raises `TypeError: _open() got unexpected keyword argument`.
- **H264 macro_block_size = 16 → pad height to multiple of 16.** `imageio-ffmpeg`'s ffmpeg writer resizes height to the nearest 16 boundary (`1080` → `1088`) for libx264 compatibility. This is harmless — the output still plays at 1920×1080. To suppress the warning or avoid extra processing, create images at dimensions already divisible by 16 (e.g. `1072` height instead of `1080`) or pass `macro_block_size=1` (risk of codec incompatibility on some TVs).

## Quick Reference

| Task | One-liner / snippet |
|---|---|
| Discover all TVs | `pychromecast.discovery.discover_chromecasts(timeout=15)` |
| Find by name | `next(c for c in chromecasts if c.name == 'rithvi tv')` |
| Check if playing | `cast.media_controller.status.player_state` |
| Cast image | `mc.play_media(url, 'image/png', title='X', thumb=url)` |
| Cast video | `mc.play_media(url, 'video/mp4', title='X', thumb=url)` |

## Related References

- `references/chromecast-api-v14.md` — Attribute mapping for `pychromecast>=14`.
- `references/tv-brand-matrix.md` — Which brands use Chromecast vs AirPlay vs DLNA.
- `scripts/generate-tv-image.sh` — Standalone image generator for quick messages.
