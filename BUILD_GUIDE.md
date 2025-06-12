# BloomeeTunes Build Guide

This guide will help you build BloomeeTunes for Android ARM64-v8a, Windows x64, and Fedora x64.

## Prerequisites

### 1. Flutter SDK
- **Required Version**: Flutter 3.13.0 or later (supports Dart SDK >=3.0.6)
- **Download**: https://docs.flutter.dev/get-started/install

### 2. Platform-Specific Requirements

#### For Android (ARM64-v8a):
- **Android Studio** with Android SDK
- **Android SDK**: API level 21 (Android 5.0) or higher
- **Android NDK**: For native code compilation
- **Java**: JDK 11 or later

#### For Windows (x64):
- **Visual Studio 2022** with C++ development tools
- **Windows 10 SDK** (version 10.0.17763.0 or later)
- **CMake**: Usually included with Visual Studio

#### For Fedora (x64):
- **Development tools**: `gcc`, `g++`, `cmake`, `ninja-build`
- **GTK development libraries**
- **pkg-config**

## Setup Instructions

### 1. Install Flutter

```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### 2. Platform Setup

#### Android Setup:
```bash
# Install Android Studio and SDK
# Accept Android licenses
flutter doctor --android-licenses

# Verify Android setup
flutter doctor
```

#### Windows Setup:
```bash
# Install Visual Studio 2022 with C++ tools
# Enable Windows development
flutter config --enable-windows-desktop

# Verify Windows setup
flutter doctor
```

#### Linux (Fedora) Setup:
```bash
# Install required packages
sudo dnf install gcc-c++ cmake ninja-build gtk3-devel pkg-config

# Enable Linux development
flutter config --enable-linux-desktop

# Verify Linux setup
flutter doctor
```

## Building Instructions

### 1. Prepare the Project

```bash
# Navigate to project directory
cd /path/to/BloomeeTunes

# Get dependencies
flutter pub get

# Clean previous builds (optional)
flutter clean
```

### 2. Build for Android ARM64-v8a

```bash
# Build APK for ARM64-v8a
flutter build apk --target-platform android-arm64 --release

# Alternative: Build App Bundle (recommended for Play Store)
flutter build appbundle --target-platform android-arm64 --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

#### Advanced Android Build Options:
```bash
# Build with specific version and build number
flutter build apk --target-platform android-arm64 --build-name=2.11.6 --build-number=172 --release

# Build with obfuscation (recommended for release)
flutter build apk --target-platform android-arm64 --obfuscate --split-debug-info=build/debug-info --release

# Build for multiple architectures
flutter build apk --split-per-abi --release
```

### 3. Build for Windows x64

```bash
# Build Windows executable
flutter build windows --release

# Output location: build/windows/x64/runner/Release/
# Main executable: bloomee.exe
# Required files: All files in the Release folder
```

#### Windows Build Notes:
- The entire `Release` folder is needed for distribution
- Include all DLL files and data folder
- The app requires Visual C++ Redistributable on target machines

### 4. Build for Fedora x64 (Linux)

```bash
# Build Linux executable
flutter build linux --release

# Output location: build/linux/x64/release/bundle/
# Main executable: bloomee
# Required files: All files in the bundle folder
```

#### Linux Build Notes:
- The entire `bundle` folder is needed for distribution
- Include all shared libraries and data folder
- May require additional libraries on target systems

## Post-Build Steps

### 1. Android APK Signing (for distribution)

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore bloomee-release-key.keystore -alias bloomee -keyalg RSA -keysize 2048 -validity 10000

# Sign APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore bloomee-release-key.keystore build/app/outputs/flutter-apk/app-release.apk bloomee

# Verify signature
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

### 2. Windows Packaging

```bash
# Create distribution folder
mkdir bloomee-windows-x64
cp -r build/windows/x64/runner/Release/* bloomee-windows-x64/

# Create installer (optional - requires NSIS or similar)
# Or create ZIP archive
zip -r bloomee-windows-x64.zip bloomee-windows-x64/
```

### 3. Linux Packaging

```bash
# Create distribution folder
mkdir bloomee-linux-x64
cp -r build/linux/x64/release/bundle/* bloomee-linux-x64/

# Create tarball
tar -czf bloomee-linux-x64.tar.gz bloomee-linux-x64/

# Optional: Create AppImage or Flatpak (requires additional tools)
```

## Build Optimization

### 1. Release Build Optimizations

```bash
# Enable tree shaking and minification
flutter build <platform> --release --tree-shake-icons

# For Android: Enable R8 optimization
# Add to android/gradle.properties:
# android.enableR8=true
```

### 2. Reduce App Size

```bash
# Analyze bundle size
flutter build apk --analyze-size
flutter build appbundle --analyze-size

# Build with specific target platform only
flutter build apk --target-platform android-arm64 --release
```

## Troubleshooting

### Common Issues:

1. **Gradle Build Failed (Android)**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. **Windows Build Failed**:
   - Ensure Visual Studio 2022 with C++ tools is installed
   - Check Windows SDK version
   - Run `flutter doctor` to verify setup

3. **Linux Build Failed**:
   - Install missing development packages
   - Check GTK version compatibility
   - Verify CMake and Ninja installation

4. **Dependency Issues**:
   ```bash
   flutter pub deps
   flutter pub upgrade
   ```

## File Locations Summary

After successful builds, you'll find:

- **Android APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Android AAB**: `build/app/outputs/bundle/release/app-release.aab`
- **Windows**: `build/windows/x64/runner/Release/` (entire folder)
- **Linux**: `build/linux/x64/release/bundle/` (entire folder)

## Distribution Checklist

### Android:
- [ ] APK/AAB built successfully
- [ ] Signed with release key
- [ ] Tested on ARM64 device
- [ ] Version number updated

### Windows:
- [ ] Executable runs without Flutter SDK
- [ ] All DLLs included
- [ ] Tested on clean Windows machine
- [ ] Consider code signing for distribution

### Linux:
- [ ] Executable runs on target distribution
- [ ] All shared libraries included
- [ ] Desktop file created (optional)
- [ ] Tested on Fedora x64

## Notes

- Always test builds on target platforms before distribution
- Consider using CI/CD for automated builds
- Keep build artifacts for debugging if issues arise
- Update version numbers in pubspec.yaml before building
- The current version is 2.11.6+0 - consider incrementing for new releases

## Support

If you encounter issues:
1. Check `flutter doctor` output
2. Verify all platform requirements are met
3. Check the Flutter documentation for your specific platform
4. Review build logs for specific error messages