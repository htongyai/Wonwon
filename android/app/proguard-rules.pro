# Keep FontAwesomeIcons class and all its fields
-keep class com.joanzapata.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.brandonwever.** { *; }
-keep class com.fortawesome.** { *; }

# Keep FontAwesome classes
-keep class com.fontawesome.** { *; }

# Keep FontAwesome classes from the font_awesome_flutter package
-keep class font_awesome_flutter.** { *; }

# Specifically keep FontAwesomeIcons and its inner classes
-keep class font_awesome_flutter.FontAwesomeIcons { *; }
-keep class font_awesome_flutter.FontAwesomeIcons$* { *; }

# Don't obfuscate FontAwesome classes
-keepnames class com.fontawesome.** { *; }
-keepnames class font_awesome_flutter.** { *; }

# Keep Flutter runtime
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep all icon classes used in the app
-keep class **.R
-keep class **.R$* {
    <fields>;
} 