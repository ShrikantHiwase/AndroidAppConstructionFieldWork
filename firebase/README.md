# Firebase
# --------
# 1. Create a Firebase project (Blaze if you need phone auth / Functions).
# 2. From repo root: `firebase use --add` and select the project.
# 3. From apps/mobile: `dart pub global activate flutterfire_cli && flutterfire configure`
# 4. Uncomment Firebase packages in apps/mobile/pubspec.yaml.
# 5. Run emulators: `cd firebase && firebase emulators:start`
#
# Rules are deny-by-default with membership helpers. Expand with emulator tests
# before production traffic.
