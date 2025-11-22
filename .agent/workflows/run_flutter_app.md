---
description: How to run the Flutter Rider app
---

# How to Run the Flutter Rider App

This guide explains how to run the Rider application on your local machine.

## Prerequisites

1.  **Flutter SDK**: Ensure Flutter is installed and added to your PATH. Run `flutter doctor` to verify.
2.  **Device**:
    -   **Android**: Start an Android Emulator via Android Studio or connect a physical Android device (with USB Debugging enabled).
    -   **iOS**: Start the iOS Simulator (macOS only) or connect a physical iPhone.
    -   **Web/Desktop**: You can also run on Chrome or Windows/macOS desktop if enabled.

## Steps

1.  **Navigate to the Project Directory**
    Open your terminal and navigate to the Rider app folder:
    ```powershell
    cd c:\Users\Eslam\Desktop\myrid7\myrid\Flutter\Rider
    ```

2.  **Install Dependencies**
    Download the required packages:
    ```powershell
    flutter pub get
    ```

3.  **Run the App**
    Launch the app on your connected device:
    ```powershell
    flutter run
    ```

    If you have multiple devices connected, list them first:
    ```powershell
    flutter devices
    ```
    Then run on a specific device using its ID:
    ```powershell
    flutter run -d <device-id>
    ```

## Troubleshooting

-   **CocoaPods (macOS)**: If running on iOS, you might need to install pods:
    ```bash
    cd ios
    pod install
    cd ..
    ```
-   **Gradle Errors (Android)**: Ensure you have a valid JDK installed (JDK 17 is recommended for newer Flutter versions).
