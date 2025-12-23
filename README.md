# Anaad Foods UI

## Project Synopsis

Anaad Foods UI is a modern, feature-rich grocery shopping application built with Flutter. This application provides a seamless shopping experience for users looking to purchase groceries and beverages online.

### Key Features

- **Modern UI/UX Design**: Implements Material Design principles with a clean and intuitive user interface
- **Product Categories**: Organized display of grocery items and beverages
- **Interactive Elements**:
  - Carousel slider for featured products
  - Staggered grid view for product listings
  - Video player integration for product demonstrations
  - Shimmer effects for loading states

### Technical Stack

- **Framework**: Flutter (SDK ^3.7.0)
- **Key Dependencies**:
  - `carousel_slider`: For featured product carousels
  - `flutter_staggered_grid_view`: For dynamic product grid layouts
  - `flutter_svg`: For scalable vector graphics
  - `font_awesome_flutter`: For icon integration
  - `shimmer`: For loading state animations
  - `url_launcher`: For external link handling
  - `video_player`: For product video content

### Project Structure

- **Assets**:
  - Images (grocery items, categories, beverages)
  - Icons (including account-specific icons)
  - Fonts
  - Videos

### Development Setup

1. Ensure Flutter SDK is installed (version ^3.7.0 or higher)
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Launch the application using `flutter run`

---

### 🔐 Setup for Team (Required)

> **⚠️ Firebase Configuration Files (Not in Repository)**
>
> For security, Firebase configuration files are excluded from version control.

**Request these files from the project lead:**

| File | Destination | Platform |
|------|-------------|----------|
| `google-services.json` | `android/app/` | Android |
| `GoogleService-Info.plist` | `ios/Runner/` | iOS |
| `.env` | Project root (`./`) | All |

**Without these files, the app will fail to build or connect to Firebase services.**

---

### 🛠️ Building the App

#### **Windows Team**

```powershell
# Clone the repository
git clone git@github.com:anaadfoods/mobile_app_back.git
cd mobile_app_back

# Install dependencies
flutter pub get

# Run on Android emulator/device
flutter run

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build Windows desktop app
flutter build windows
```

#### **Mac Team**

```bash
# Clone the repository
git clone git@github.com:anaadfoods/mobile_app_back.git
cd mobile_app_back

# IMPORTANT: Fix gradlew permissions (first time only)
chmod +x android/gradlew

# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run

# Build iOS (requires Xcode)
flutter build ios

# Build Android APK
flutter build apk --release

# Build macOS desktop app
flutter build macos
```

#### **Common Commands (All Platforms)**

```bash
# Check Flutter installation
flutter doctor

# Clean build cache (if issues occur)
flutter clean && flutter pub get

# Run with verbose logging
flutter run -v

# Run on specific device
flutter devices              # List available devices
flutter run -d <device_id>   # Run on specific device
```

---

### Target Platforms

The application is configured to run on multiple platforms:

- Android
- iOS
- Web
- Windows
- Linux
- macOS

### Development Guidelines

- Follow Flutter best practices and Material Design guidelines
- Maintain consistent code style using Flutter lints
- Ensure responsive design across all supported platforms
- Optimize assets for performance

### Future Enhancements

- User authentication system
- Shopping cart functionality
- Payment gateway integration
- Order tracking system
- Push notifications
- Offline support
