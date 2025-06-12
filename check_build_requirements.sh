#!/bin/bash

# BloomeeTunes Build Requirements Checker
# This script checks if all required tools are installed for building

set -e

echo "🔍 BloomeeTunes Build Requirements Checker 🔍"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check Flutter
check_flutter() {
    print_check "Checking Flutter installation..."
    if command -v flutter &> /dev/null; then
        flutter --version
        print_pass "Flutter is installed"
        
        # Check Flutter doctor
        print_check "Running Flutter doctor..."
        flutter doctor
    else
        print_fail "Flutter is not installed"
        echo "Install from: https://docs.flutter.dev/get-started/install"
        return 1
    fi
}

# Check Android requirements
check_android() {
    print_check "Checking Android development setup..."
    
    # Check for Android SDK
    if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
        print_pass "Android SDK path is set"
    else
        print_fail "Android SDK path not set (ANDROID_HOME or ANDROID_SDK_ROOT)"
    fi
    
    # Check for Java
    if command -v java &> /dev/null; then
        java_version=$(java -version 2>&1 | head -n 1)
        print_pass "Java is installed: $java_version"
    else
        print_fail "Java is not installed"
    fi
    
    # Check for Android Studio or command line tools
    if command -v adb &> /dev/null; then
        print_pass "Android Debug Bridge (adb) is available"
    else
        print_warn "ADB not found in PATH"
    fi
}

# Check Windows requirements
check_windows() {
    print_check "Checking Windows development setup..."
    
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Check for Visual Studio
        if command -v msbuild &> /dev/null; then
            print_pass "MSBuild is available"
        else
            print_fail "MSBuild not found - Visual Studio required"
        fi
        
        # Check for CMake
        if command -v cmake &> /dev/null; then
            cmake_version=$(cmake --version | head -n 1)
            print_pass "CMake is installed: $cmake_version"
        else
            print_fail "CMake is not installed"
        fi
    else
        print_warn "Not running on Windows - Windows build requirements not checked"
    fi
}

# Check Linux requirements
check_linux() {
    print_check "Checking Linux development setup..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check for GCC
        if command -v gcc &> /dev/null; then
            gcc_version=$(gcc --version | head -n 1)
            print_pass "GCC is installed: $gcc_version"
        else
            print_fail "GCC is not installed"
        fi
        
        # Check for G++
        if command -v g++ &> /dev/null; then
            gpp_version=$(g++ --version | head -n 1)
            print_pass "G++ is installed: $gpp_version"
        else
            print_fail "G++ is not installed"
        fi
        
        # Check for CMake
        if command -v cmake &> /dev/null; then
            cmake_version=$(cmake --version | head -n 1)
            print_pass "CMake is installed: $cmake_version"
        else
            print_fail "CMake is not installed"
        fi
        
        # Check for Ninja
        if command -v ninja &> /dev/null; then
            ninja_version=$(ninja --version)
            print_pass "Ninja is installed: $ninja_version"
        else
            print_fail "Ninja is not installed"
        fi
        
        # Check for GTK development libraries
        if pkg-config --exists gtk+-3.0; then
            gtk_version=$(pkg-config --modversion gtk+-3.0)
            print_pass "GTK3 development libraries: $gtk_version"
        else
            print_fail "GTK3 development libraries not found"
        fi
        
        # Check for pkg-config
        if command -v pkg-config &> /dev/null; then
            print_pass "pkg-config is available"
        else
            print_fail "pkg-config is not installed"
        fi
    else
        print_warn "Not running on Linux - Linux build requirements not checked"
    fi
}

# Check project dependencies
check_project() {
    print_check "Checking project dependencies..."
    
    if [ -f "pubspec.yaml" ]; then
        print_pass "pubspec.yaml found"
        
        # Check if dependencies are installed
        if [ -d ".dart_tool" ]; then
            print_pass "Dependencies appear to be installed"
        else
            print_warn "Dependencies may not be installed - run 'flutter pub get'"
        fi
    else
        print_fail "pubspec.yaml not found - not in Flutter project directory?"
    fi
}

# Main execution
main() {
    echo "Checking build requirements for all platforms..."
    echo ""
    
    check_flutter
    echo ""
    
    check_android
    echo ""
    
    check_windows
    echo ""
    
    check_linux
    echo ""
    
    check_project
    echo ""
    
    echo "=============================================="
    echo "Requirements check completed!"
    echo ""
    echo "Next steps:"
    echo "1. Fix any failed requirements above"
    echo "2. Run 'flutter doctor' for detailed Flutter setup"
    echo "3. Use build_all.sh (Linux/Mac) or build_all.bat (Windows) to build"
    echo ""
    echo "Platform-specific installation commands:"
    echo ""
    echo "Fedora/RHEL:"
    echo "  sudo dnf install gcc-c++ cmake ninja-build gtk3-devel pkg-config"
    echo ""
    echo "Ubuntu/Debian:"
    echo "  sudo apt-get install gcc g++ cmake ninja-build libgtk-3-dev pkg-config"
    echo ""
    echo "Windows:"
    echo "  Install Visual Studio 2022 with C++ development tools"
    echo ""
    echo "Android:"
    echo "  Install Android Studio and accept SDK licenses"
}

main "$@"