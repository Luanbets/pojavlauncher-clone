# PojavLauncher Clone Builder v7.0

4 fully independent PojavLauncher clones with Root OOM Guard.

## Injection (Minimalist)
- **1 line** added to `MainActivity.onCreate(Bundle)` after `super.onCreate()`
- 3 new files: `RootHelper.smali`, `RootHelper$1.smali` (background thread), `RootHelper$2.smali` (UI toast)
- No existing smali modified except 1 line

## Root Features
- OOM_ADJ set to -17 via `su -c echo -17 > /proc/pid/oom_score_adj`
- Toast via `Handler.postDelayed(2500ms)` — waits for NativeActivity window
- Logcat: `android.util.Log.d("POJAV_CLONE", ...)` at every step

## Package Changes (Minimum Required)
- AndroidManifest.xml: `package` attribute
- strings.xml: `storageProviderAuthorities`, `application_package`
- BuildConfig.smali: `APPLICATION_ID`
- Recursive XML resource scan
