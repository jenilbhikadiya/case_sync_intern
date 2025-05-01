@echo off
echo Building Production APK...
fvm flutter pub get
fvm flutter build apk --flavor production -t lib/main_production.dart --release

echo Production APK build completed.
echo APK location: build/app/outputs/flutter-apk/app-production-release.apk
pause 