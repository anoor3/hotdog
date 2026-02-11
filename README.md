# HotDOG or Not

HOTDOG is a playful, fully native SwiftUI recreation of the “Not Hotdog” app from HBO’s Silicon Valley. Point your camera (or pick any photo) and the app instantly calls out whether you’re staring at a bona fide hotdog or a pretender, complete with the bold, tongue-in-cheek UI from the show.

## Features
- **Instant classification** – Uses Apple’s on-device Vision framework (`VNClassifyImageRequest`) to spot hotdogs with minimal latency and without sending data off-device.
- **Camera & gallery support** – Snap photos in the moment or analyze anything from your library using the custom image picker wrapper.
- **Authentic UI & UX** – Gradient background, oversized verdict banner, and playful typography match the SEEFOOD vibe showcased on-screen.
- **Confidence insights** – Displays top labels and percentages so you can see exactly what the model “thought” it saw.
- **Graceful handling** – Progress indicators, friendly error messages, and source-availability alerts keep the experience smooth.

## Project Structure
- `hotdogApp.swift` – Entry point wiring SwiftUI’s `ContentView` into the app scene.
- `ContentView.swift` – All layout, state management, and Vision classification logic, plus the `ImagePicker` UIKit bridge and supporting models.
- `Assets.xcassets` – Placeholder for custom icons or imagery (add app icons, launch screens, etc.).

## Requirements
- Xcode 15 or newer
- iOS 17 SDK (can be adjusted downward if needed)
- Device or simulator with camera/photo-library access (classification runs on-device; simulator camera uses the system’s sample feed)

## Running SEEFOOD
1. Open the project in Xcode.
2. Select an iOS simulator or a physical device (recommended for using the actual camera).
3. Build & run (`⌘R`).
4. Grant camera/photo permissions on first launch.
5. Snap or select a photo and wait for the verdict banner to call out HOTDOG / NOT HOTDOG.

## Customization Tips
- **Model tweaks** – Swap in a custom Core ML model if you want more precise food recognition. Replace the `VNClassifyImageRequest` with `VNCoreMLRequest` targeting your model.
- **Branding** – Update typography, colors, and copy in `ContentView` to make the meme your own.
- **Result thresholds** – Adjust the `hotdogObservation` confidence cutoff or the number of “Also spotted” suggestions to fine-tune output.

## License
This project is provided as-is for educational and entertainment purposes. Feel free to expand it into the AI-powered snack detector of your dreams.
