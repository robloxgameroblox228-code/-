# VR Vision

Android video-player prototype for phone-based VR/cardboard viewers.

## Implemented in this prototype
- Select a local video through Android's file picker
- Playback through AndroidX Media3 / ExoPlayer
- Built-in play, pause, seek and volume controls
- Landscape orientation and immersive full-screen mode
- Keep the display awake while the app is open
- GitHub Actions debug-APK build

## Not implemented yet
The SBS/Mono button is currently only a mode selector in the interface. True per-eye SBS cropping, mono duplication, lens-distortion correction, adjustable lens spacing/shape, calibration grid and saved headset profiles still need implementation and testing. This is an early prototype, not the finished feature-complete app.

## Build and download the APK
1. Open the Actions page: https://github.com/robloxgameroblox228-code/-/actions
2. Select **Build VR Vision APK**.
3. Press **Run workflow**, keep branch **main**, and confirm.
4. Wait until the run has a green check mark.
5. Open that successful run and find **Artifacts** at the bottom.
6. Download **VR-Vision-debug**. GitHub downloads it as a ZIP.
7. Extract the ZIP on your phone. Inside is **app-debug.apk**.
8. Tap the APK to install. If Android blocks it, allow your browser or file manager to install unknown apps, then retry.

If the build fails, open the run, tap the failed job, and send a screenshot of the first red error section.

## Technical details
- Package: com.vrvision.app
- Minimum Android version: Android 6.0 (API 23)
- Debug build; not a signed Play Store release.
