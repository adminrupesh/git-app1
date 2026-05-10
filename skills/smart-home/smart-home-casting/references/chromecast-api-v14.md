# pychromecast v14+ Attribute Mapping

A quick lookup table because the v14 API surface changed several attributes. Agents hitting `AttributeError` should flip lookup here.

## What changed in v14

| Old (pre-v14) | v14 equivalent | Notes |
|---|---|---|
| `cast.device.friendly_name` | `cast.name` | Human-readable label |
| `cast.device.model_name` | `cast.cast_info.model_name` | Hardware model string |
| `cast.device.host` | `cast.cast_info.host` | IPv4 address |
| `cast.device.port` | `cast.cast_info.port` | Usually 8009 |
| `cast.device.uuid` | `cast.uuid` | UUID string |
| `cast.status.display_name` | `cast.status.display_name` | UNCHANGED — current app |

## Discovery returns `CastInfo` objects

```python
import pychromecast

services, browser = pychromecast.discovery.discover_chromecasts(timeout=15)
for svc in services:
    # svc is a pychromecast.discovery.CastInfo
    print(svc.friendly_name)  # "rithvi tv"
    print(svc.host)           # "192.168.1.6"
    print(svc.port)           # 8009
    print(svc.model_name)     # "HAT4KDTV"
    print(svc.uuid)           # "d62517c7-ab0e-3e49-b5f8-cb072ec9d703"

# To get a Chromecast handle from discovery:
chromecasts, _ = pychromecast.get_chromecasts()
cast = chromecasts[0]  # or filter by cast.name
```

## Do NOT use these (removed)

- `cast.device` → AttributeError
- `cast.host` → AttributeError
- `cast.port` → AttributeError
