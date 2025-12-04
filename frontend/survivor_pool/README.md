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
