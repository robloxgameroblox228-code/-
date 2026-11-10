# VR Vision

An early Android VR video-player prototype for phone-based cardboard viewers.

## Current prototype features
- Open local video files using Android's system picker
- Open a direct HTTP/HTTPS video URL
- Two synchronized eye players for side-by-side viewing
- Mono mode duplicates the same video for both eyes
- Synchronized play/pause, seek bar and time display for both eyes
- Shared volume slider
- Immersive landscape mode and keep-screen-awake
- Image zoom and horizontal eye offset controls
- GPU radial lens-distortion correction on Android 13+ (adjustable and saved in profiles)
- Circular, oval and rounded-rectangle viewing masks
- Calibration grid overlay
- Named headset profiles: save, load, delete and reset settings locally

## Important limitations
This is still a prototype and has not yet been validated on a physical headset. The radial distortion control is a general GPU correction, not a per-headset calibrated optical profile; its effect depends on the phone and lens geometry. Android versions below 13 do not apply the shader. SBS mode expects a side-by-side source video. Direct URL playback requires a direct media URL, not a normal YouTube page. YouTube pages and every possible network stream format are not supported. SBS mode expects a side-by-side source video. Direct URL playback requires a direct media URL, not a normal YouTube page.

## Build APK
1. Open the Actions tab.
2. Select the latest Build VR Vision APK run on branch main.
3. Wait for a green Success check.
4. Open the run's Artifacts section and download VR-Vision-debug.
5. Extract the ZIP and install app-debug.apk on Android.

Package: com.vrvision.app
Minimum Android: 6.0 (API 23)
Build type: debug APK.
