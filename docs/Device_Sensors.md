# Device sensors (GPS / camera / biometrics / voice / files)

Packages `geolocator`, `image_picker`, `local_auth`, `record`, `file_picker`,
and `image` (pure-Dart JPEG compress) are in `pubspec.yaml`. CI and default
runs use **Fake** implementations so tests stay green without hardware.

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
| Voice | `local://demo/voice_*.m4a` stub + ~80 KB + canned transcript | `record` mic → AAC/m4a (transcript heuristic on flush) |
| Documents | `local://demo/documents/...` stub + typed preview | `file_picker` → on-device path |
| Biometric | always succeeds | `local_auth` |

## Evidence compression

`EvidenceImagePolicy`: max width **1600px**, JPEG quality **70** (floor 40),
soft target **~400 KB**. `DeviceEvidenceCapture` applies picker limits then
`FileImageCompressor` (resize + quality ladder). Demo Fake paths get
`byteSizeBytes` without I/O. New Issue, site-ops safety/QA fail / labour muster /
material GRN, drawing pins, and DPR activities show queued size when a photo is
attached.

## Voice audio

`VoiceAudioPolicy`: Fake stubs estimate **~80 KB**. Soft cache includes voice
notes; Cleanup clears uploaded `local://` audio stubs. Live capture is capped
at **60s**. Real STT remains deferred — offline notes keep `transcriptPending`
until flush resolves a heuristic transcript.

## Document files

`DocumentFilePolicy`: Fake TXT/CSV/PDF stubs with estimated sizes. Soft cache
includes document local paths; Cleanup clears uploaded `local://` stubs. Full
PDF rendering (`pdfrx`) remains deferred — upload stores metadata + Storage
bytes path.

## Android permissions and iOS usage strings

Already in the platform folders (`RECORD_AUDIO`, `NSMicrophoneUsageDescription`).

## Wired call sites

- New Issue → Add GPS / Add photo / From gallery
- Site ops → Safety observation/incident photo; QA WIR fail photo (compressed + Storage outbox upload)
- Labour muster → optional evidence photo (compressed + Storage outbox upload)
- Materials → optional GRN / consumption evidence photo
- Drawing pins → optional evidence photo
- Today's DPR → optional activity evidence photo
- Voice notes on DPR / issues → Fake stub or live mic (`VoiceCapture`)
- Documents upload → Pick demo file / Pick file (`DocumentFilePicker`)
- Biometric unlock screen
- Labour muster geofence check
