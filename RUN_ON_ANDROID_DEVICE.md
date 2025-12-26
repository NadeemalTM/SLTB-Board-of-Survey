# 📱 HOW TO RUN FLUTTER APP ON USB ANDROID DEVICE

## ✅ **PREREQUISITES CHECKLIST**

Before starting, ensure you have:
- ✅ Flutter SDK installed (check: `flutter --version`)
- ✅ Android device with USB cable
- ✅ USB Debugging enabled on Android device
- ✅ Device drivers installed (Windows)

---

## 🔧 **STEP 1: ENABLE USB DEBUGGING ON ANDROID DEVICE**

### On Your Android Phone/Tablet:

1. **Open Settings** → About Phone
2. **Tap "Build Number" 7 times** (You'll see "You are now a developer!")
3. **Go back to Settings** → System → Developer Options
4. **Enable "USB Debugging"**
5. **Enable "Install via USB"** (if available)

### Developer Options Location by Brand:
- **Samsung:** Settings → Developer Options
- **Xiaomi/Redmi:** Settings → Additional Settings → Developer Options
- **Oppo/Realme:** Settings → Additional Settings → Developer Options
- **OnePlus:** Settings → System → Developer Options

---

## 🔌 **STEP 2: CONNECT DEVICE TO COMPUTER**

1. **Connect USB cable** from phone to computer
2. **On phone screen:** Allow USB Debugging prompt will appear
   - ✅ Check "Always allow from this computer"
   - Tap **"ALLOW"** or **"OK"**
3. **If no prompt appears:**
   - Swipe down notification panel
   - Tap USB notification
   - Change to **"File Transfer"** or **"MTP"** mode

---

## 💻 **STEP 3: VERIFY DEVICE CONNECTION**

Open PowerShell in project folder and run:

```powershell
cd "G:\SLTB\SLTB Board of Survey\1"
flutter devices
```

### Expected Output:
```
2 connected devices:

SM G950F (mobile) • XXXXXXXX • android-arm64 • Android 11 (API 30)
Chrome (web)     • chrome    • web-javascript • Google Chrome 120.0
```

**✅ If you see your device listed → SUCCESS! Proceed to Step 4**
**❌ If device NOT listed → See Troubleshooting below**

---

## 🚀 **STEP 4: RUN THE APP**

### Option A: Using PowerShell Command

```powershell
cd "G:\SLTB\SLTB Board of Survey\1"
flutter run
```

### Option B: Using VS Code
1. Press **F5** or **Ctrl+F5**
2. Select your Android device from the dropdown
3. Wait for app to build and install

### What Happens Next:
```
Launching lib\main.dart on SM G950F...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk.
Installing build\app\outputs\flutter-apk\app.apk...
Debug service listening on ws://127.0.0.1:xxxxx/
Synced 0.0MB.
```

**⏱️ First run takes 2-5 minutes** (compiling Android dependencies)
**⏱️ Subsequent runs take 30-60 seconds** (hot reload is instant)

---

## 🎯 **STEP 5: TEST THE APP**

Once app launches on your device:

### 1. **Test Login Screen**
   - Username: `admin` Password: `admin123` (Admin)
   - Username: `officer01` Password: `field123` (Field Officer)

### 2. **Grant Permissions When Prompted**
   - ✅ Camera (for barcode scanning)
   - ✅ Storage (for CSV import/export)
   - ✅ Photos (for taking pictures)

### 3. **Test Admin Workflow**
   - Login as admin
   - View dashboard statistics
   - Try importing master CSV (use sample data)
   - Export reports

### 4. **Test Field Officer Workflow**
   - Login as officer01
   - View dashboard
   - Tap scan button (camera will open)
   - Scan a barcode or manually enter asset code

---

## 🔥 **STEP 6: DEVELOPMENT TIPS**

### Hot Reload (Instant Changes):
```powershell
# While app is running, in terminal press:
r     # Hot reload (applies code changes instantly)
R     # Hot restart (full restart)
q     # Quit
```

### Rebuild from Scratch:
```powershell
flutter clean
flutter pub get
flutter run
```

### Run in Release Mode (Faster):
```powershell
flutter run --release
```

### View Logs:
```powershell
flutter logs
```

---

## ⚠️ **TROUBLESHOOTING**

### Problem 1: Device Not Detected

**Solution A: Check USB Drivers**
```powershell
# Install universal Android USB driver
# Download from: https://developer.android.com/studio/run/win-usb
```

**Solution B: Restart ADB**
```powershell
flutter doctor --android-licenses
adb kill-server
adb start-server
flutter devices
```

**Solution C: Try Different USB Cable/Port**
- Use original phone cable (data cable, not charging-only)
- Try different USB port on computer
- Avoid USB hubs

### Problem 2: "Gradle Task Failed"

```powershell
cd "G:\SLTB\SLTB Board of Survey\1\android"
.\gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Problem 3: "Unable to Install APK"

**Solution:**
1. Uninstall old version from phone manually
2. Run: `flutter clean`
3. Run: `flutter run`

### Problem 4: Camera Permission Denied

**Solution:**
1. Go to phone Settings → Apps → SLTB Survey
2. Permissions → Enable Camera and Storage
3. Restart app

### Problem 5: App Crashes on Startup

**Check logs:**
```powershell
flutter logs
```

**Common fixes:**
```powershell
flutter clean
flutter pub get
flutter run --verbose
```

---

## 📊 **USEFUL COMMANDS**

| Command | Purpose |
|---------|---------|
| `flutter devices` | List connected devices |
| `flutter run` | Run app in debug mode |
| `flutter run --release` | Run in release mode (faster) |
| `flutter clean` | Clean build files |
| `flutter doctor` | Check Flutter installation |
| `flutter logs` | View real-time logs |
| `adb devices` | Check ADB connection |
| `adb logcat` | View Android system logs |

---

## 🎓 **KEYBOARD SHORTCUTS (While App Running)**

| Key | Action |
|-----|--------|
| `r` | Hot reload (instant updates) |
| `R` | Hot restart (full restart) |
| `p` | Show grid overlay |
| `P` | Show performance overlay |
| `o` | Toggle platform (Android/iOS) |
| `q` | Quit app |
| `h` | Help |

---

## 🔐 **TEST CREDENTIALS**

### Admin Account:
- Username: `admin`
- Password: `admin123`

### Field Officer Accounts:
- Username: `officer01` to `officer10`
- Password: `field123` (all officers)

---

## 📱 **DEVICE REQUIREMENTS**

### Minimum:
- Android 6.0+ (API 23)
- 2GB RAM
- 100MB free storage
- Camera (for barcode scanning)

### Recommended:
- Android 10+ (API 29)
- 4GB RAM
- 500MB free storage
- Good camera quality

---

## ✅ **QUICK START CHECKLIST**

1. ☐ USB Debugging enabled on phone
2. ☐ Phone connected via USB cable
3. ☐ "Allow USB Debugging" accepted on phone
4. ☐ Run `flutter devices` - phone appears
5. ☐ Run `flutter run`
6. ☐ App installs and launches
7. ☐ Login with test credentials
8. ☐ Grant camera and storage permissions

---

## 🎯 **EXPECTED FIRST RUN TIME**

- **Gradle sync:** 1-2 minutes
- **Dependencies download:** 1-2 minutes  
- **APK build:** 1-2 minutes
- **Installation:** 10-30 seconds
- **Total:** 3-5 minutes

**Subsequent runs:** 30-60 seconds only!

---

## 📞 **NEED HELP?**

### Check Flutter Setup:
```powershell
flutter doctor -v
```

All items should have ✅ green checkmarks.

### Common Issues Fixed By:
```powershell
flutter clean
flutter pub get
flutter doctor --android-licenses
flutter run
```

---

## 🚀 **YOU'RE READY TO GO!**

Run this command now:

```powershell
cd "G:\SLTB\SLTB Board of Survey\1"
flutter devices
flutter run
```

**The app will automatically install and launch on your phone!**
