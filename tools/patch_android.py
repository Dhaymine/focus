"""Idempotent patch of the generated Android project for flutter_local_notifications."""
import pathlib
import re
import sys

app = pathlib.Path("android/app")
DESUGAR_VERSION = "2.1.4"

# ---------- Gradle ----------
kts = app / "build.gradle.kts"
groovy = app / "build.gradle"

if kts.exists():
    text = kts.read_text()
    if "isCoreLibraryDesugaringEnabled" not in text:
        text, n = re.subn(
            r"(compileOptions\s*\{)",
            r"\1\n        isCoreLibraryDesugaringEnabled = true",
            text,
            count=1,
        )
        if n == 0:
            sys.exit("compileOptions block not found in build.gradle.kts")
    if "desugar_jdk_libs" not in text:
        dep = f'    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:{DESUGAR_VERSION}")'
        if re.search(r"^dependencies\s*\{", text, re.M):
            text = re.sub(r"^(dependencies\s*\{)", r"\1\n" + dep, text, count=1, flags=re.M)
        else:
            text += "\ndependencies {\n" + dep + "\n}\n"
    kts.write_text(text)
elif groovy.exists():
    text = groovy.read_text()
    if "coreLibraryDesugaringEnabled" not in text:
        text, n = re.subn(
            r"(compileOptions\s*\{)",
            r"\1\n        coreLibraryDesugaringEnabled true",
            text,
            count=1,
        )
        if n == 0:
            sys.exit("compileOptions block not found in build.gradle")
    if "desugar_jdk_libs" not in text:
        dep = f"    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:{DESUGAR_VERSION}'"
        if re.search(r"^dependencies\s*\{", text, re.M):
            text = re.sub(r"^(dependencies\s*\{)", r"\1\n" + dep, text, count=1, flags=re.M)
        else:
            text += "\ndependencies {\n" + dep + "\n}\n"
    groovy.write_text(text)
else:
    sys.exit("No android/app/build.gradle(.kts) found")

# ---------- Manifest ----------
manifest = app / "src/main/AndroidManifest.xml"
text = manifest.read_text()

perms = [
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
    '<uses-permission android:name="android.permission.VIBRATE"/>',
    '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
    '<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>',
    '<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32"/>',
]
missing = []
for p in perms:
    name = re.search(r'android:name="([^"]+)"', p).group(1)
    if f'android:name="{name}"' not in text:
        missing.append("    " + p + "\n")
if missing:
    text = text.replace("<application", "".join(missing) + "    <application", 1)

if "ScheduledNotificationReceiver" not in text:
    receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
    text = text.replace("</application>", receivers + "    </application>", 1)

manifest.write_text(text)
print("Android project patched")
