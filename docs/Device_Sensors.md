# Device sensors (GPS / camera / biometrics)

Packages `geolocator`, `image_picker`, and `local_auth` are in `pubspec.yaml`.
CI and default runs use **Fake** implementations so tests stay green without
hardware.

## Enable native sensors on a device

```bash
cd apps/mobile
flutter run --dart-define=USE_NATIVE_SENSORS=true
```

`DeviceSensorsGate.useNative` switches Riverpod providers to `Device*` services.
On permission failure or plugin errors, Device* falls back to Fake*.

| Service | Fake | Device |
|---------|------|--------|
| Location | Hinjewadi demo fix; geofence always OK | `geolocator` |
| Evidence | `local://demo/...` JPEG stub | `image_picker` camera |
| Biometric | always succeeds | `local_auth` |

Android permissions and iOS usage strings are already in the platform folders.

## Wired call sites

- New Issue → Add GPS / Add photo
- Biometric unlock screen
- Labour muster geofence check
