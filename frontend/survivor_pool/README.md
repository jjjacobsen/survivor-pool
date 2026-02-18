# survivor_pool

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Releasing

Web is as simple as buying a domain and setting up routing properly. Mobile requires registering with the App Store or Play Store

- [ios](https://docs.flutter.dev/deployment/ios)

Note: If it seems like things are deploying right, Cloudflare does caching and you might need to go purge that

### Android / Play Store setup

1. Install Android Studio:

   ```bash
   brew install --cask android-studio
   ```

2. Open Android Studio and complete the standard setup flow.

3. Install `Android SDK Command-line Tools` in Android Studio:
   - Open Settings
   - Go to `Languages & Frameworks -> Android SDK`
   - Open the `SDK Tools` tab
   - Check `Android SDK Command-line Tools (latest)`
   - Click Apply / OK and let it install

4. Accept Android licenses:

   ```bash
   flutter doctor --android-licenses
   ```

5. Verify tooling:
   - At this point, `flutter doctor -v` should report everything healthy for Android.
   - Flutter run/build commands must be run from this Flutter project root: `frontend/survivor_pool` (the folder that contains `pubspec.yaml`).

6. Launch an emulator:

   ```bash
   flutter emulators --launch Medium_Phone_API_36.1
   ```

7. Result:
   - This launches an Android device on macOS via QEMU.
   - For local backend access from Android emulator, use `http://10.0.2.2:8000` instead of `http://localhost:8000`.
   - Example:

   ```bash
   flutter run -d "sdk gphone64 arm64" --dart-define=API_BASE_URL=http://10.0.2.2:8000
   ```

8. Use the Play Store bundle identifier:
   - Android `namespace` and `applicationId` are set to `com.survivorpoolapp.survivorpool` in `android/app/build.gradle.kts`.

9. Create and keep release signing files:
   - `android/upload-keystore.jks`
   - `android/key.properties`
   - They are intentionally ignored by git in `android/.gitignore`.
   - If you need to regenerate them:

   ```bash
   cd android
   STORE_PASS=$(openssl rand -hex 24)
   KEY_PASS=$(openssl rand -hex 24)
   /Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool \
     -genkeypair -v \
     -keystore upload-keystore.jks \
     -storetype JKS \
     -storepass "$STORE_PASS" \
     -keypass "$KEY_PASS" \
     -alias upload \
     -keyalg RSA \
     -keysize 2048 \
     -validity 10000 \
     -dname "CN=Survivor Pool, OU=Mobile, O=Survivor Pool, L=Unknown, ST=Unknown, C=US"
   printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=upload\nstoreFile=upload-keystore.jks\n' \
     "$STORE_PASS" "$KEY_PASS" > key.properties
   chmod 600 key.properties upload-keystore.jks
   ```

10. Release signing is wired in `android/app/build.gradle.kts`:
    - `signingConfigs.release` reads from `android/key.properties`.
    - `buildTypes.release` uses that release signing config.

11. Bump version for each Play Store release:
    - Current version is `1.0.1+3` in `pubspec.yaml`.
    - Format is `version_name+version_code`, and Play Store requires version code to increase each upload.

12. Build the Play Store `.aab` bundle:

    ```bash
    mise run aab
    ```

    - Equivalent Flutter command:

    ```bash
    flutter build appbundle --release --obfuscate --split-debug-info=build/android_split_debug_info --dart-define=API_BASE_URL=https://api.survivorpoolapp.com
    ```

13. Play Console URL:
    - https://play.google.com/console

14. In Play Console, complete:
    - App setup + Store listing
    - App content + Data safety forms
    - Internal testing release upload
    - Production release submission

### Icon Composer

This is how Apple wants you to build icons for their apps now. The following is the process I took to create and import the icon into Xcode

- Download Icon Composer
- For symbols and layers I had to use inkscape to generate a svg
  - Then you can drag and drop the svg into icon composer
- Open Xcode
  - Specifically follow the [documentation above](https://docs.flutter.dev/deployment/ios) where it says to run the following from the flutter project directory

    ```bash
    open ios/Runner.xcworkspace
    ```

- Incorporating the custom icon into Xcode
  - Need to drag and drop the .icon file to Runner/Runner
  - Don't put it in the Assets thing
  - Should be able to view the icon in Xcode
  - [this](https://www.youtube.com/watch?v=B9Q3JSDyNIo) video shows how to do it at the end
  - Then under general settings change the App Icon name
  - Delete app in simulator completely before opening to remove cache

#### Web favicon (.ico)

1. Export a PNG from Icon Composer as `icon-1024.png`.
2. Generate the favicon:

   ```bash
   magick icon-1024.png -define icon:auto-resize=16,32,48 favicon2.ico
   ```

3. Copy it into the web app and update the favicon link:
   - Replace `web/favicon.ico` with the new file.
   - Ensure `web/index.html` uses:

   ```html
   <link rel="icon" type="image/x-icon" href="favicon.ico" />
   ```

### Screenshots

- Can take a screenshot using the button on the simulator
- Use the largest display simulator available, then upload to that specific display size
  - Then it scales down the image to the smaller sizes
