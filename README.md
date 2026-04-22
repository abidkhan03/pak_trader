# Pak Trader Invoice App

A fully **offline** Android invoice generator for Pakistan Trader.  
Create professional invoices, generate PDFs, share via WhatsApp, and back up your data — no internet required.

---

## What This App Does

- Fill in your **business details** (Bill From) and **customer details** (Bill To)
- Add products/items with price and quantity — totals calculate automatically
- Generate a **professional PDF invoice** (purple header matching your format)
- **Share the PDF** via WhatsApp, email, or any app
- **Save invoices** by name so you can reload them anytime
- **Backup all data** to a JSON file and restore it on any phone

---

## App Features at a Glance

| Feature | Description |
|---------|-------------|
| Invoice Info | Invoice number, PO number, invoice date, due date |
| Bill From | Your business name, address, email, phone |
| Bill To | Customer / client / company name, address, phone |
| Items Table | Add/remove items with name, description, price, quantity |
| Auto Calculation | Subtotal, tax, and total amount calculated live |
| PDF Generation | Creates a styled PDF saved on your phone |
| WhatsApp Sharing | Share the PDF directly from the app |
| Save Invoices | Save and reload multiple invoices by name |
| Backup | Export all data to a `.json` file and share/save it |
| Restore | Import a backup `.json` file to restore all data |
| Auto-save | Last working invoice is automatically remembered |

---

## For Non-Technical Users — Just Install the APK

If someone has already built the APK for you, skip all the steps below and just:

1. Copy `app-release.apk` to your Android phone
2. Open the file on your phone
3. If asked, allow **"Install from unknown sources"** in your phone settings
4. Tap **Install** — done!

The pre-built APK is located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## For Developers — Build from Source

Follow these steps to set up the development environment and build the APK yourself.

### Requirements

| Tool | Version | Why It's Needed |
|------|---------|-----------------|
| macOS | Any recent version | Build machine OS |
| Java JDK | 17 (exactly) | Android build tools requirement |
| Android SDK | API 35+ | Compiling Android code |
| Android NDK | 28.2.13676358 | Native code used by some packages |
| Flutter SDK | 3.10 or higher | The app framework |
| Homebrew | Any | Package manager for macOS (makes everything easier) |

---

### Step 1 — Install Homebrew (skip if already installed)

Homebrew is a tool that makes installing software on Mac easy.

Open **Terminal** (press `Cmd + Space`, type `Terminal`, press Enter) and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

### Step 2 — Install Java JDK 17

Android build tools require Java 17. Run in Terminal:

```bash
brew install openjdk@17
```

After installation, add Java to your shell profile so it's always available:

```bash
echo 'export JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home' >> ~/.zshrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
```

Verify it worked:

```bash
java -version
# Should show: openjdk version "17.x.x"
```

---

### Step 3 — Install Android SDK and Command-Line Tools

1. Download **Android Studio** from https://developer.android.com/studio  
   *(You can use just the command-line tools if you prefer, but Android Studio is easier)*

2. Open Android Studio → **SDK Manager** → Install:
   - Android SDK Platform **35**
   - Android SDK Build-Tools **35**
   - Android SDK Command-line Tools (latest)
   - NDK (Side by side) **28.2.13676358**
   - CMake **3.22.1**

3. Add the SDK to your shell profile:

```bash
echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
echo 'export ANDROID_SDK_ROOT=$ANDROID_HOME' >> ~/.zshrc
echo 'export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
```

Verify:

```bash
adb --version
# Should show ADB version info
```

---

### Step 4 — Install Flutter SDK

```bash
# Download Flutter to your home folder
cd ~
git clone https://github.com/flutter/flutter.git -b stable flutter/flutter

# Add Flutter to your PATH
echo 'export PATH="$HOME/flutter/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Tell Flutter to use Java 17:

```bash
flutter config --jdk-dir /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

Run the Flutter doctor to check everything is set up:

```bash
flutter doctor
```

All checkmarks should be green. If anything shows a warning, follow the on-screen fix instructions.

---

### Step 5 — Set Up the Project

1. Place the project folder at any location (e.g. `/Users/yourname/projects/pak_trader`)

2. Update `android/local.properties` with your actual paths:

```properties
sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk
flutter.sdk=/Users/YOUR_USERNAME/flutter/flutter
flutter.versionCode=1
flutter.versionName=1.0.0
```

> Replace `YOUR_USERNAME` with your actual macOS username (run `whoami` in Terminal to find it)

3. Install Flutter package dependencies:

```bash
cd /path/to/pak_trader
flutter pub get
```

---

### Step 6 — Build the APK

#### Release APK (for installing on phones — recommended)

```bash
export JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

flutter build apk --release --android-skip-build-dependency-validation
```

Output APK:
```
build/app/outputs/flutter-apk/app-release.apk
```

#### Debug APK (for testing with more logs)

```bash
flutter build apk --debug
```

Output:
```
build/app/outputs/flutter-apk/app-debug.apk
```

#### Install directly to a connected Android phone

Connect your phone via USB with **USB Debugging** enabled, then:

```bash
flutter install
```

---

## Common Errors & Fixes

| Error | Fix |
|-------|-----|
| `NDK did not have a source.properties file` | The NDK download is corrupt. Delete `~/Library/Android/sdk/ndk/28.2.13676358` and reinstall via SDK Manager |
| `Java version incompatible` | Make sure `JAVA_HOME` points to JDK 17, not any other version |
| `flutter: command not found` | Flutter is not in your PATH — re-run Step 4 and restart Terminal |
| `SDK location not found` | `android/local.properties` has wrong paths — update `sdk.dir` |
| `Gradle build failed` | Run `flutter clean` then try building again |

---

## Project Structure

```
pak_trader/
├── lib/
│   ├── main.dart                         # App entry point, Hive init, theme
│   ├── models/
│   │   └── invoice_model.dart            # Invoice & InvoiceItem data classes
│   ├── screens/
│   │   └── invoice_form_screen.dart      # Full form UI (all sections)
│   ├── services/
│   │   ├── pdf_service.dart              # PDF layout & generation
│   │   └── database_service.dart         # Hive DB, backup, restore
│   └── widgets/
│       └── item_row_widget.dart          # Dynamic item row (name/desc/price/qty/total)
├── android/
│   ├── app/build.gradle                  # Android build config (SDK, NDK versions)
│   ├── build.gradle                      # AGP & Kotlin versions
│   ├── settings.gradle                   # Plugin versions
│   └── gradle/wrapper/
│       └── gradle-wrapper.properties     # Gradle version
└── pubspec.yaml                          # All Flutter dependencies
```

---

## Key Libraries Used

| Package | Purpose |
|---------|---------|
| `pdf` | PDF document creation and styling |
| `path_provider` | Access app documents directory on device |
| `share_plus` | Android/iOS share sheet (WhatsApp, email, etc.) |
| `permission_handler` | Request storage permissions on Android |
| `hive` + `hive_flutter` | Local NoSQL database for saving invoices |
| `file_picker` | Browse and select backup `.json` files |
| `intl` | Date formatting |

---

## How Backup & Restore Works

**To back up your data:**
1. Open the app → scroll to **Backup & Restore** section
2. Tap **Export Backup**
3. A `.json` file is created and the share sheet opens
4. Send it to yourself via WhatsApp, email, or save to Google Drive

**To restore on a new phone:**
1. Install the APK on the new phone
2. Open the app → scroll to **Backup & Restore** section
3. Tap **Restore Backup**
4. Select the `.json` backup file
5. All your invoices are restored instantly

---

## Build Environment (Tested & Working)

| Component | Version |
|-----------|---------|
| macOS | Sonoma 14+ |
| Java JDK | 17.0.x (OpenJDK via Homebrew) |
| Flutter | 3.x stable |
| Android Gradle Plugin | 8.6.0 |
| Gradle | 8.9 |
| Kotlin | 2.1.0 |
| Android compileSdk | 35 |
| Android minSdk | 26 |
| NDK | 28.2.13676358 |
