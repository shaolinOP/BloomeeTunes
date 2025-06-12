@echo off
REM BloomeeTunes Multi-Platform Build Script for Windows
REM This script builds the app for Android ARM64-v8a, Windows x64, and Linux x64

setlocal enabledelayedexpansion

echo 🎵 BloomeeTunes Multi-Platform Build Script 🎵
echo ================================================

REM Check if Flutter is installed
echo [INFO] Checking Flutter installation...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH
    echo [INFO] Please install Flutter from: https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

flutter --version
echo [SUCCESS] Flutter is installed

REM Clean and prepare project
echo [INFO] Preparing project...
flutter clean
flutter pub get
echo [SUCCESS] Project prepared

REM Create dist directory
if not exist "dist" mkdir dist

REM Build for Android ARM64-v8a
echo [INFO] Building for Android ARM64-v8a...
flutter doctor | findstr "Android toolchain" >nul
if not errorlevel 1 (
    echo [INFO] Building APK...
    flutter build apk --target-platform android-arm64 --release
    
    echo [INFO] Building App Bundle...
    flutter build appbundle --target-platform android-arm64 --release
    
    echo [INFO] Building APKs for all architectures...
    flutter build apk --split-per-abi --release
    
    echo [SUCCESS] Android builds completed!
    echo [INFO] APK location: build\app\outputs\flutter-apk\app-release.apk
    echo [INFO] AAB location: build\app\outputs\bundle\release\app-release.aab
) else (
    echo [WARNING] Android toolchain not properly configured. Skipping Android build.
    echo [INFO] Run 'flutter doctor' to see Android setup requirements
)

REM Build for Windows x64
echo [INFO] Building for Windows x64...
flutter doctor | findstr "Visual Studio" >nul
if not errorlevel 1 (
    flutter build windows --release
    
    REM Create distribution folder
    if not exist "dist\windows-x64" mkdir dist\windows-x64
    xcopy /E /I /Y build\windows\x64\runner\Release\* dist\windows-x64\
    
    echo [SUCCESS] Windows build completed!
    echo [INFO] Windows build location: dist\windows-x64\
) else (
    echo [WARNING] Visual Studio not properly configured. Skipping Windows build.
    echo [INFO] Install Visual Studio 2022 with C++ development tools
)

REM Build for Linux x64 (if WSL is available)
echo [INFO] Checking for Linux build capability...
wsl --list >nul 2>&1
if not errorlevel 1 (
    echo [INFO] WSL detected. Attempting Linux build...
    wsl bash -c "cd /mnt/c$(pwd | sed 's/C://' | sed 's/\\/\//g') && flutter build linux --release"
    
    if not errorlevel 1 (
        if not exist "dist\linux-x64" mkdir dist\linux-x64
        xcopy /E /I /Y build\linux\x64\release\bundle\* dist\linux-x64\
        echo [SUCCESS] Linux build completed!
        echo [INFO] Linux build location: dist\linux-x64\
    ) else (
        echo [WARNING] Linux build failed in WSL
    )
) else (
    echo [WARNING] WSL not available. Skipping Linux build.
    echo [INFO] Install WSL and Flutter in Linux environment for Linux builds
)

REM Create build summary
echo [INFO] Creating build summary...
echo # Build Summary > BUILD_SUMMARY.txt
echo Generated on: %date% %time% >> BUILD_SUMMARY.txt
echo. >> BUILD_SUMMARY.txt

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ✅ Android APK: build\app\outputs\flutter-apk\app-release.apk >> BUILD_SUMMARY.txt
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do echo    Size: %%~zA bytes >> BUILD_SUMMARY.txt
)

if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ✅ Android AAB: build\app\outputs\bundle\release\app-release.aab >> BUILD_SUMMARY.txt
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do echo    Size: %%~zA bytes >> BUILD_SUMMARY.txt
)

if exist "dist\windows-x64" (
    echo ✅ Windows x64: dist\windows-x64\ >> BUILD_SUMMARY.txt
)

if exist "dist\linux-x64" (
    echo ✅ Linux x64: dist\linux-x64\ >> BUILD_SUMMARY.txt
)

echo. >> BUILD_SUMMARY.txt
echo Flutter version: >> BUILD_SUMMARY.txt
flutter --version >> BUILD_SUMMARY.txt

echo [SUCCESS] Build summary created: BUILD_SUMMARY.txt

echo.
echo [SUCCESS] 🎉 Build process completed!
echo [INFO] Check BUILD_SUMMARY.txt for details

REM Display summary
if exist "BUILD_SUMMARY.txt" (
    echo.
    echo [INFO] Build Summary:
    type BUILD_SUMMARY.txt
)

pause