# Device sensors (GPS / camera / biometrics)

Packages `geolocator`, `image_picker`, `local_auth`, and `image` (pure-Dart
JPEG compress) are in `pubspec.yaml`. CI and default runs use **Fake**
implementations so tests stay green without hardware.

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
| Evidence | `local://demo/...` JPEG stub + ~150 KB size | `image_picker` camera/gallery → `FileImageCompressor` |
| Biometric | always succeeds | `local_auth` |

## Evidence compression

`EvidenceImagePolicy`: max width **1600px**, JPEG quality **70** (floor 40),
soft target **~400 KB**. `DeviceEvidenceCapture` applies picker limits then
`FileImageCompressor` (resize + quality ladder). Demo Fake paths get
`byteSizeBytes` without I/O. New Issue shows `Queued · ~NN KB`.

## Android permissions and iOS usage strings

Already in the platform folders.

## Wired call sites

- New Issue → Add GPS / Add photo / From gallery
- Site ops → Safety observation/incident photo; QA WIR fail photo (compressed + Storage outbox upload)
- Biometric unlock screen
- Labour muster geofence check
