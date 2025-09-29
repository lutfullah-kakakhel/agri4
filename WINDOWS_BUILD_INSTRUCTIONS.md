# AGRI4 ADVISOR - Windows Desktop Build Instructions

## 🖥️ **Windows Desktop Version Setup**

This guide will help you build the AGRI4 ADVISOR app for Windows desktop use.

## 📋 **Prerequisites**

### **1. Windows Requirements**
- **OS:** Windows 10 (version 1903 or later) or Windows 11
- **Architecture:** x64 (64-bit)
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** 10GB free space

### **2. Development Tools Required**

#### **Visual Studio 2022 (Community Edition - FREE)**
1. Download from: https://visualstudio.microsoft.com/downloads/
2. During installation, select these workloads:
   - ✅ **Desktop development with C++**
   - ✅ **Universal Windows Platform development**
   - ✅ **Windows 10/11 SDK** (latest version)

#### **Git for Windows**
1. Download from: https://git-scm.com/download/win
2. Install with default settings

#### **Flutter SDK**
1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your Windows PATH environment variable

## 🚀 **Build Process**

### **Step 1: Clone/Transfer the Project**
```bash
# If you have the project on GitHub:
git clone <your-repo-url>
cd agri4_app

# Or copy the project folder to your Windows machine
```

### **Step 2: Install Flutter Dependencies**
```bash
# Open Command Prompt or PowerShell as Administrator
cd C:\path\to\agri4_app
flutter doctor
flutter pub get
```

### **Step 3: Enable Windows Desktop Support**
```bash
flutter config --enable-windows-desktop
flutter create --platforms=windows .
```

### **Step 4: Build Windows Executable**
```bash
# Debug build (for testing)
flutter build windows --debug

# Release build (for distribution)
flutter build windows --release
```

## 📁 **Output Files**

After successful build, you'll find:

### **Debug Build:**
- **Location:** `build\windows\x64\debug\Runner\`
- **Executable:** `agri4_app.exe`
- **Size:** ~50-100MB (includes debug symbols)

### **Release Build:**
- **Location:** `build\windows\x64\release\Runner\`
- **Executable:** `agri4_app.exe`
- **Size:** ~30-50MB (optimized)

## 🎯 **Distribution Options**

### **Option 1: Direct Distribution**
- Copy the entire `Runner\` folder
- Users need to run `agri4_app.exe`
- All DLL files must be included

### **Option 2: MSI Installer (Recommended)**
```bash
# Install MSIX packaging tools
flutter install --platforms windows

# Create MSIX package
flutter build windows --release
flutter build msix
```

### **Option 3: Portable App**
- Use tools like **NSIS** or **Inno Setup** to create a single executable
- Include all required DLLs and assets

## 🔧 **Troubleshooting**

### **Common Issues:**

#### **1. "Visual Studio not found"**
```bash
flutter doctor --verbose
# Install Visual Studio 2022 with C++ workload
```

#### **2. "CMake not found"**
- Install CMake from: https://cmake.org/download/
- Add to PATH: `C:\Program Files\CMake\bin`

#### **3. "Windows SDK not found"**
- Install Windows 10/11 SDK through Visual Studio Installer
- Or download from: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

#### **4. "Build fails with permission errors"**
- Run Command Prompt as Administrator
- Check antivirus isn't blocking the build process

## 📱 **App Features on Windows**

### **✅ Fully Supported:**
- 🗺️ **Interactive Maps** (Flutter Map)
- 📍 **GPS Location** (via web browser geolocation)
- 🌾 **Field Drawing & Area Calculation**
- 📊 **Weather Data Integration**
- 🛰️ **Satellite Data (NDVI)**
- 🌱 **Agricultural Advisory**
- 💾 **Local Data Storage (Hive)**

### **⚠️ Platform Considerations:**
- **GPS:** Uses browser geolocation (requires HTTPS in production)
- **File Storage:** Uses Windows file system
- **Network:** Standard HTTP requests
- **UI:** Responsive design for desktop screens

## 🎨 **Desktop UI Enhancements**

The app automatically adapts to desktop:
- **Larger Map View:** Better for field planning
- **Keyboard Shortcuts:** Standard Windows shortcuts
- **Window Resizing:** Responsive layout
- **Multiple Windows:** Can open multiple instances

## 📦 **Final Distribution**

### **For End Users:**
1. **Download:** The `Runner` folder or MSI installer
2. **Install:** Run the installer or extract the folder
3. **Launch:** Double-click `agri4_app.exe`
4. **Usage:** Same features as mobile version

### **System Requirements for End Users:**
- Windows 10/11 (64-bit)
- 4GB RAM minimum
- 500MB free storage
- Internet connection for maps and data

## 🚀 **Quick Start Commands**

```bash
# Complete build process:
cd C:\path\to\agri4_app
flutter clean
flutter pub get
flutter build windows --release

# Test the app:
cd build\windows\x64\release\Runner
agri4_app.exe
```

## 📞 **Support**

If you encounter issues:
1. Check `flutter doctor` output
2. Verify all prerequisites are installed
3. Try building in debug mode first
4. Check Windows Event Viewer for errors

---

**🎉 Your AGRI4 ADVISOR Windows desktop app is ready!**

The app will work exactly like the mobile version but optimized for desktop use with larger screens and better navigation.






