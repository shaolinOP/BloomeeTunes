#!/bin/bash

# BloomeeTunes Multi-Platform Build Script
# This script builds the app for Android ARM64-v8a, Windows x64, and Linux x64

set -e  # Exit on any error

echo "🎵 BloomeeTunes Multi-Platform Build Script 🎵"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
check_flutter() {
    print_status "Checking Flutter installation..."
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        print_status "Please install Flutter from: https://docs.flutter.dev/get-started/install"
        exit 1
    fi
    
    flutter --version
    print_success "Flutter is installed"
}

# Clean and prepare project
prepare_project() {
    print_status "Preparing project..."
    flutter clean
    flutter pub get
    print_success "Project prepared"
}

# Build for Android ARM64-v8a
build_android() {
    print_status "Building for Android ARM64-v8a..."
    
    if flutter doctor | grep -q "Android toolchain"; then
        print_status "Building APK..."
        flutter build apk --target-platform android-arm64 --release
        
        print_status "Building App Bundle..."
        flutter build appbundle --target-platform android-arm64 --release
        
        print_status "Building APKs for all architectures..."
        flutter build apk --split-per-abi --release
        
        print_success "Android builds completed!"
        print_status "APK location: build/app/outputs/flutter-apk/app-release.apk"
        print_status "AAB location: build/app/outputs/bundle/release/app-release.aab"
    else
        print_warning "Android toolchain not properly configured. Skipping Android build."
        print_status "Run 'flutter doctor' to see Android setup requirements"
    fi
}

# Build for Windows x64
build_windows() {
    print_status "Building for Windows x64..."
    
    if flutter doctor | grep -q "Visual Studio"; then
        flutter build windows --release
        
        # Create distribution folder
        mkdir -p dist/windows-x64
        cp -r build/windows/x64/runner/Release/* dist/windows-x64/
        
        print_success "Windows build completed!"
        print_status "Windows build location: dist/windows-x64/"
    else
        print_warning "Visual Studio not properly configured. Skipping Windows build."
        print_status "Install Visual Studio 2022 with C++ development tools"
    fi
}

# Build for Linux x64
build_linux() {
    print_status "Building for Linux x64..."
    
    if flutter doctor | grep -q "Linux toolchain"; then
        flutter build linux --release
        
        # Create distribution folder
        mkdir -p dist/linux-x64
        cp -r build/linux/x64/release/bundle/* dist/linux-x64/
        
        print_success "Linux build completed!"
        print_status "Linux build location: dist/linux-x64/"
    else
        print_warning "Linux toolchain not properly configured. Skipping Linux build."
        print_status "Install required packages: sudo dnf install gcc-c++ cmake ninja-build gtk3-devel pkg-config"
    fi
}

# Create build summary
create_summary() {
    print_status "Creating build summary..."
    
    echo "# Build Summary" > BUILD_SUMMARY.txt
    echo "Generated on: $(date)" >> BUILD_SUMMARY.txt
    echo "" >> BUILD_SUMMARY.txt
    
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "✅ Android APK: build/app/outputs/flutter-apk/app-release.apk" >> BUILD_SUMMARY.txt
        echo "   Size: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)" >> BUILD_SUMMARY.txt
    fi
    
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        echo "✅ Android AAB: build/app/outputs/bundle/release/app-release.aab" >> BUILD_SUMMARY.txt
        echo "   Size: $(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)" >> BUILD_SUMMARY.txt
    fi
    
    if [ -d "dist/windows-x64" ]; then
        echo "✅ Windows x64: dist/windows-x64/" >> BUILD_SUMMARY.txt
        echo "   Size: $(du -sh dist/windows-x64 | cut -f1)" >> BUILD_SUMMARY.txt
    fi
    
    if [ -d "dist/linux-x64" ]; then
        echo "✅ Linux x64: dist/linux-x64/" >> BUILD_SUMMARY.txt
        echo "   Size: $(du -sh dist/linux-x64 | cut -f1)" >> BUILD_SUMMARY.txt
    fi
    
    echo "" >> BUILD_SUMMARY.txt
    echo "Flutter version:" >> BUILD_SUMMARY.txt
    flutter --version >> BUILD_SUMMARY.txt
    
    print_success "Build summary created: BUILD_SUMMARY.txt"
}

# Main execution
main() {
    # Parse command line arguments
    BUILD_ANDROID=true
    BUILD_WINDOWS=true
    BUILD_LINUX=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --android-only)
                BUILD_WINDOWS=false
                BUILD_LINUX=false
                shift
                ;;
            --windows-only)
                BUILD_ANDROID=false
                BUILD_LINUX=false
                shift
                ;;
            --linux-only)
                BUILD_ANDROID=false
                BUILD_WINDOWS=false
                shift
                ;;
            --no-android)
                BUILD_ANDROID=false
                shift
                ;;
            --no-windows)
                BUILD_WINDOWS=false
                shift
                ;;
            --no-linux)
                BUILD_LINUX=false
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --android-only    Build only for Android"
                echo "  --windows-only    Build only for Windows"
                echo "  --linux-only      Build only for Linux"
                echo "  --no-android      Skip Android build"
                echo "  --no-windows      Skip Windows build"
                echo "  --no-linux        Skip Linux build"
                echo "  -h, --help        Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Start build process
    check_flutter
    prepare_project
    
    # Create dist directory
    mkdir -p dist
    
    # Build for each platform
    if [ "$BUILD_ANDROID" = true ]; then
        build_android
    fi
    
    if [ "$BUILD_WINDOWS" = true ]; then
        build_windows
    fi
    
    if [ "$BUILD_LINUX" = true ]; then
        build_linux
    fi
    
    create_summary
    
    echo ""
    print_success "🎉 Build process completed!"
    print_status "Check BUILD_SUMMARY.txt for details"
    
    # Display summary
    if [ -f "BUILD_SUMMARY.txt" ]; then
        echo ""
        print_status "Build Summary:"
        cat BUILD_SUMMARY.txt
    fi
}

# Run main function with all arguments
main "$@"