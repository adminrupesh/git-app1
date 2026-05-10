# Smart TV Brand Casting Protocol Matrix

Which casting protocol each major brand uses. Prevents wasting time on Chromecast discovery when the TV only supports AirPlay or DLNA.

## Quick Lookup

| Brand | Built-in Protocol | Chromecast | AirPlay | DLNA | Notes |
|---|---|---|---|---|---|
| **VU (India)** | Google Cast | ✅ Built-in | ❌ | ❌ | `model_name` = `HAT4KDTV` etc. |
| **Google Chromecast** | Google Cast | ✅ Native | ❌ | ❌ | Dongle / puck |
| **NVIDIA SHIELD** | Google Cast | ✅ Native | ❌ | ❌ | `SHIELD Android TV` |
| **Sony Bravia** | Google Cast | ✅ Most models | ❌ | ❌ | Bravia Android TV |
| **Samsung** | SmartThings / Miracast | ❌ | ✅ Some | ✅ | Use SmartThings app |
| **LG** | webOS / AirPlay | ❌ | ✅ Recent models | ✅ | webOS 4.0+ has AirPlay 2 |
| **OnePlus / Xiaomi** | Google Cast | ✅ | ❌ | ❌ | Budget Android TVs |
| **panasonic** | My Home Screen | ❌ | ❌ | ✅ | Older models only DLNA |

## Discovery Strategy Per Brand

| If user says... | Try first | Fallback |
|---|---|---|
| "VU TV" / "Android TV" | Chromecast discovery | — |
| "Samsung TV" | SmartThings app / DLNA | — |
| "LG TV" | AirPlay discovery | DLNA |
| "Sony TV" | Chromecast discovery | — |
| "Don't know the brand" | Chromecast → AirPlay → DLNA | Ask user |

## How to Detect Protocol Support

### Chromecast / Google Cast
```python
import pychromecast
services, _ = pychromecast.discovery.discover_chromecasts(timeout=10)
# If services found → Google Cast supported
```

### AirPlay
```python
# Use `dns-sd` or `zeroconf` to scan for _airplay._tcp
```

### DLNA
```python
# Upnp discovery on SSDP port 1900
```

## Related
- `references/chromecast-api-v14.md` — API surface changes
