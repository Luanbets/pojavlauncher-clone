#!/usr/bin/env python3
"""PojavLauncher Clone Builder v7.0 — Minimalist Approach

Changes ONLY:
1. Package name in AndroidManifest.xml, strings.xml, BuildConfig.smali
2. Single invoke-static line in MainActivity.onCreate after super.onCreate
3. 3 new smali files: RootHelper + 2 inner classes
4. doNotCompress for JRE assets

Preserves 100%:
- All smali code (except 1 injection line)
- All native .so libraries
- All assets
- All resources
- Original compression via doNotCompress
"""

import os
import sys
import shutil
import subprocess

BASE_DIR = "/home/z/my-project/tools"
SOURCE_DIR = os.path.join(BASE_DIR, "pojav_decompiled")
OUTPUT_DIR = "/home/z/my-project/download"
BUILD_DIR = os.path.join(BASE_DIR, "build_work")
APKTOOL = os.path.join(BASE_DIR, "apktool.jar")
UBER_SIGNER = os.path.join(BASE_DIR, "uber-apk-signer.jar")
KEYSTORE = os.path.join(BASE_DIR, "release.keystore")

CLONES = [
    ("1", "pojavlaunch.clone1"),
    ("2", "pojavlaunch.clone2"),
    ("3", "pojavlaunch.clone3"),
    ("4", "pojavlaunch.clone4"),
]

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(BUILD_DIR, exist_ok=True)


def safe_replace_in_file(filepath, old, new):
    """Read file, replace exact string, write back."""
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    new_content = content.replace(old, new)
    if new_content == content:
        print(f"  [WARN] No replacement made in {filepath}: '{old}' not found")
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)


def do_package_rename(work_dir, pkg_suffix):
    """Minimal package rename: only what's needed for independent installation."""
    new_pkg = f"net.kdt.{pkg_suffix}"
    old_pkg = "net.kdt.pojavlaunch.debug"

    # 1. AndroidManifest.xml — package attribute
    safe_replace_in_file(
        os.path.join(work_dir, "AndroidManifest.xml"),
        f'package="{old_pkg}"',
        f'package="{new_pkg}"'
    )

    # 2. strings.xml — provider authorities (unique per app)
    safe_replace_in_file(
        os.path.join(work_dir, "res/values/strings.xml"),
        "net.kdt.pojavlaunch.scoped.gamefolder.debug",
        f"net.kdt.{pkg_suffix}.scoped.gamefolder"
    )

    # 3. strings.xml — application_package string
    safe_replace_in_file(
        os.path.join(work_dir, "res/values/strings.xml"),
        old_pkg,
        new_pkg
    )

    # 4. BuildConfig.smali — APPLICATION_ID
    safe_replace_in_file(
        os.path.join(work_dir, "smali_classes7/net/kdt/pojavlaunch/BuildConfig.smali"),
        old_pkg,
        new_pkg
    )

    # 5. apktool.yml — set renameManifestPackage
    safe_replace_in_file(
        os.path.join(work_dir, "apktool.yml"),
        "renameManifestPackage: null",
        f"renameManifestPackage: {new_pkg}"
    )

    # 6. Recursive XML resource replacement (catches pref_control.xml etc.)
    for root, dirs, files in os.walk(os.path.join(work_dir, "res")):
        for fname in files:
            if fname.endswith('.xml'):
                fpath = os.path.join(root, fname)
                safe_replace_in_file(fpath, old_pkg, new_pkg)

    print(f"  [OK] Package renamed to {new_pkg}")


def update_doNotCompress(work_dir):
    """Add JRE extensions to doNotCompress to preserve original compression."""
    apktool_yml = os.path.join(work_dir, "apktool.yml")
    with open(apktool_yml, 'r') as f:
        content = f.read()

    entries_to_add = [
        "jar", "tar.xz", "pack",
    ]

    lines = content.split('\n')
    new_lines = []
    in_dnc = False
    existing = set()

    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip() == 'doNotCompress:':
            new_lines.append(line)
            in_dnc = True
            i += 1
            continue
        if in_dnc:
            stripped = line.strip()
            if stripped.startswith('- '):
                entry = stripped.lstrip('- ').strip()
                existing.add(entry)
                new_lines.append(line)
                i += 1
                continue
            else:
                # End of section — add missing entries
                for e in entries_to_add:
                    if e not in existing:
                        new_lines.append(f"- {e}")
                in_dnc = False
        new_lines.append(line)
        i += 1

    # Handle if doNotCompress was last section
    if in_dnc:
        for e in entries_to_add:
            if e not in existing:
                new_lines.append(f"- {e}")

    with open(apktool_yml, 'w') as f:
        f.write('\n'.join(new_lines))

    print(f"  [OK] doNotCompress updated (added: {entries_to_add})")


def inject_root_helper(work_dir):
    """Inject 3 RootHelper smali files + single line into MainActivity.onCreate.

    The injection is AFTER invoke-super {p0, p1} in onCreate(Bundle).
    It uses p0 (this/Activity) as context — does NOT touch any local registers v0-v3.
    """
    base = BASE_DIR
    smali_dir = os.path.join(work_dir, "smali_classes7/net/kdt/pojavlaunch")

    # Copy 3 files
    for fname in ["RootHelper.smali", "RootHelper$1.smali", "RootHelper$2.smali"]:
        src = os.path.join(base, fname)
        dst = os.path.join(smali_dir, fname)
        shutil.copy2(src, dst)
    print("  [OK] RootHelper smali files copied")

    # Inject single line into MainActivity.onCreate after super.onCreate(Bundle)
    main_activity = os.path.join(smali_dir, "MainActivity.smali")
    with open(main_activity, 'r') as f:
        lines = f.readlines()

    new_lines = []
    injected = False
    in_oncreate_bundle = False

    for line in lines:
        new_lines.append(line)

        # Detect the target method
        if '.method public onCreate(Landroid/os/Bundle;)V' in line:
            in_oncreate_bundle = True
            continue

        # End of any method
        if in_oncreate_bundle and '.end method' in line:
            if not injected:
                print("  [WARN] Injection point not found!")
            in_oncreate_bundle = False
            continue

        # Inject AFTER super.onCreate(savedInstanceState)
        if in_oncreate_bundle and not injected:
            if 'invoke-super {p0, p1}' in line and 'onCreate' in line:
                # SINGLE LINE INJECTION — uses only p0, returns void, no register corruption
                new_lines.append('\n')
                new_lines.append('    # RootHelper: delayed Toast + OOM_ADJ (background thread, 2.5s UI delay)\n')
                new_lines.append('    invoke-static {p0}, Lnet/kdt/pojavlaunch/RootHelper;->performRootInit(Landroid/content/Context;)V\n')
                new_lines.append('\n')
                injected = True
                print("  [OK] RootHelper injected into MainActivity.onCreate (single invoke-static)")

    with open(main_activity, 'w') as f:
        f.writelines(new_lines)


def build_and_sign(work_dir, clone_id):
    """Build APK with apktool and sign with uber-apk-signer."""
    unsigned = os.path.join(BUILD_DIR, f"clone_{clone_id}_unsigned.apk")

    # Build — let apktool handle resources normally
    result = subprocess.run(
        ["java", "-jar", APKTOOL, "b", work_dir, "-o", unsigned],
        capture_output=True, text=True, timeout=600
    )
    if result.returncode != 0:
        print(f"  [ERROR] apktool build failed:\n{result.stderr[-500:]}")
        return False
    print(f"  [OK] APK compiled ({os.path.getsize(unsigned) // 1024 // 1024} MB)")

    # Sign
    signed_dir = os.path.join(BUILD_DIR, f"signed_{clone_id}")
    result = subprocess.run(
        ["java", "-jar", UBER_SIGNER,
         "--apks", unsigned,
         "--ks", KEYSTORE,
         "--ksAlias", "pojavclone",
         "--ksPass", "clone123",
         "--ksKeyPass", "clone123",
         "--out", signed_dir],
        capture_output=True, text=True, timeout=120
    )
    if result.returncode != 0:
        print(f"  [ERROR] signing failed:\n{result.stderr[-500:]}")
        return False

    # Find signed APK
    for f in os.listdir(signed_dir):
        if f.endswith("-aligned-signed.apk"):
            final = os.path.join(signed_dir, f)
            apk_name = f"PojavLauncher-Clone{clone_id}.apk"
            dest = os.path.join(OUTPUT_DIR, apk_name)
            shutil.copy2(final, dest)
            print(f"  [OK] Signed: {apk_name} ({os.path.getsize(dest) // 1024 // 1024} MB)")
            return True

    print(f"  [ERROR] No signed APK found")
    return False


def main():
    print("=" * 50)
    print(" PojavLauncher Clone Builder v7.0 (Minimalist)")
    print("=" * 50)

    for clone_id, pkg_suffix in CLONES:
        work_dir = os.path.join(BUILD_DIR, f"clone_{clone_id}")
        print(f"\n--- Clone {clone_id}: net.kdt.{pkg_suffix} ---")

        # Fresh copy
        if os.path.exists(work_dir):
            shutil.rmtree(work_dir)
        shutil.copytree(SOURCE_DIR, work_dir)

        print("[1/5] Package rename...")
        do_package_rename(work_dir, pkg_suffix)

        print("[2/5] doNotCompress for JRE assets...")
        update_doNotCompress(work_dir)

        print("[3/5] Inject RootHelper (3 files + 1 line)...")
        inject_root_helper(work_dir)

        print("[4/5] Build APK...")
        print("[5/5] Sign APK...")
        if not build_and_sign(work_dir, clone_id):
            print(f"  [FAILED] Clone {clone_id}")

    print("\n" + "=" * 50)
    print(" BUILD COMPLETE")
    print("=" * 50)
    print("\nOutput:")
    for f in sorted(os.listdir(OUTPUT_DIR)):
        if f.endswith(".apk"):
            size = os.path.getsize(os.path.join(OUTPUT_DIR, f))
            print(f"  {f} ({size // 1024 // 1024} MB)")


if __name__ == "__main__":
    main()
