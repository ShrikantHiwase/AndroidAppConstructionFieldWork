# Flutter embedding keeps most of what it needs via consumer rules; the
# entries below cover plugins that reflect into their own classes.

# flutter_local_notifications uses GSON-style reflection for scheduled payloads.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# workmanager background callbacks are resolved reflectively.
-keep class dev.fluttercommunity.workmanager.** { *; }

# Keep annotation metadata used by the above.
-keepattributes *Annotation*
