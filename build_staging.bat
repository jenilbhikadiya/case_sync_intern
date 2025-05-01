@echo off
echo Building Staging APK...
fvm flutter pub get
fvm flutter build apk --flavor staging -t lib/main_staging.dart --release

echo Staging APK build completed.
echo APK location: build/app/outputs/flutter-apk/app-staging-release.apk
pause 