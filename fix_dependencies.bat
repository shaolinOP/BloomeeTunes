@echo off
echo 🔧 Fixing dependency conflicts...
echo.

echo 📦 Cleaning Flutter cache...
flutter clean

echo 📥 Getting updated dependencies...
flutter pub get

echo ✅ Dependencies fixed!
echo.
echo 🚀 Now try building:
echo flutter build apk --target-platform android-arm64 --release
pause