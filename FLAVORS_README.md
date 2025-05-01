# Case Sync Flavors

This project has been set up with two flavors: Production and Staging.

## Flavors

1. **Production**
   - Base URL: `https://pragmanxt.com/case_sync_pro/services/intern/v1/index.php`
   - App Name: "Case Sync"

2. **Staging**
   - Base URL: `https://pragmanxt.com/case_sync_test/services/intern/v1/index.php`
   - App Name: "Case Sync Test"

## Running the App with Flavors

### From Terminal

To run the app with a specific flavor in debug mode:

```bash
# Production
flutter run --flavor production -t lib/main_production.dart

# Staging
flutter run --flavor staging -t lib/main_staging.dart
```

### Building APKs

#### Using Scripts (Windows)

For Windows users, batch files have been provided:

1. Double-click on `build_production.bat` to build the Production APK
2. Double-click on `build_staging.bat` to build the Staging APK

#### Using Scripts (Linux/Mac)

For Linux/Mac users, shell scripts have been provided:

```bash
# Make scripts executable
chmod +x build_production.sh build_staging.sh

# Build Production APK
./build_production.sh

# Build Staging APK
./build_staging.sh
```

#### Manual Building

To build the APKs manually:

```bash
# Production APK
flutter build apk --flavor production -t lib/main_production.dart --release

# Staging APK
flutter build apk --flavor staging -t lib/main_staging.dart --release
```

## APK Locations

The APKs will be generated at:

- Production: `build/app/outputs/flutter-apk/app-production-release.apk`
- Staging: `build/app/outputs/flutter-apk/app-staging-release.apk` 