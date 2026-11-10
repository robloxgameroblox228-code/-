# VR Vision

An early Android VR video-player prototype for phone-based cardboard viewers.

## Current prototype features
- Open local video files using Android's system picker
- Open a direct HTTP/HTTPS video URL
- Two synchronized eye players for side-by-side viewing
- Mono mode duplicates the same video for both eyes
- Playback and seek controls are provided in the player interface
- Immersive landscape mode and keep-screen-awake
- Image zoom and horizontal eye offset controls
- Circular, oval and rounded-rectangle viewing masks
- Calibration grid overlay
- Save/load the current headset settings locally

## Important limitations
This is a prototype and has not yet been tested on a physical headset. Lens masks and basic image alignment are implemented, but a calibrated optical barrel/pincushion distortion shader, independent left/right eye geometry controls, robust multi-profile naming, YouTube playback, and broad network-stream compatibility are not implemented. SBS mode expects a side-by-side source video. Direct URL playback requires a direct media URL, not a normal YouTube page.

## Build APK
1. Open the Actions tab.
2. Select the latest Build VR Vision APK run on branch main.
3. Wait for a green Success check.
4. Open the run's Artifacts section and download VR-Vision-debug.
5. Extract the ZIP and install app-debug.apk on Android.

Package: com.vrvision.app
Minimum Android: 6.0 (API 23)
Build type: debug APK.
