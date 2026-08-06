/// Gate for native device sensors (GPS / camera / biometrics).
///
/// Default is off so CI and `flutter test` stay on Fake* implementations.
/// Enable on device builds:
/// `flutter run --dart-define=USE_NATIVE_SENSORS=true`
abstract final class DeviceSensorsGate {
  static const bool useNative = bool.fromEnvironment(
    'USE_NATIVE_SENSORS',
    defaultValue: false,
  );
}
