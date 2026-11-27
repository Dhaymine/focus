"""Idempotent patch of the generated Android project.

1. Core library desugaring (flutter_local_notifications)
2. Notification permissions and receivers in the manifest
3. Force compileSdk 36 on all Android library subprojects (file_picker etc.)
"""
import pathlib
import re
import sys

app = pathlib.Path("android/app")
root = pathlib.Path("android")
DESUGAR_VERSION = "2.1.4"
COMPILE_SDK = 36

# ---------- app gradle: desugaring ----------
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
            print(text)
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
            print(text)
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

# ---------- root gradle: force compileSdk on library subprojects ----------
MARK = "FOCUS_FORCE_COMPILE_SDK"
root_kts = root / "build.gradle.kts"
root_groovy = root / "build.gradle"

KTS_BLOCK = f"""
// {MARK}
subprojects {{
    afterEvaluate {{
        if (plugins.hasPlugin("com.android.library")) {{
            extensions.getByName("android").withGroovyBuilder {{
                "compileSdkVersion"({COMPILE_SDK})
            }}
        }}
    }}
}}
"""

GROOVY_BLOCK = f"""
// {MARK}
subprojects {{
    afterEvaluate {{ p ->
        if (p.plugins.hasPlugin('com.android.library')) {{
            p.android.compileSdkVersion {COMPILE_SDK}
        }}
    }}
}}
"""


def insert_block(path: pathlib.Path, block: str) -> None:
    text = path.read_text()
    if MARK in text:
        return
    lines = text.split("\n")
    last_import = -1
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import = i
    head = lines[: last_import + 1]
    tail = lines[last_import + 1 :]
    path.write_text("\n".join(head) + "\n" + block + "\n".join(tail))


if root_kts.exists():
    insert_block(root_kts, KTS_BLOCK)
    print("--- android/build.gradle.kts after patch ---")
    print(root_kts.read_text())
elif root_groovy.exists():
    insert_block(root_groovy, GROOVY_BLOCK)
    print("--- android/build.gradle after patch ---")
    print(root_groovy.read_text())
else:
    sys.exit("No android/build.gradle(.kts) found")

# ---------- manifest ----------
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
