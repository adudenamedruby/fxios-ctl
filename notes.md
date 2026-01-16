High-Value Candidates

1. narya build - Build the app

This is heavily used across workflows with many variations:

- Schemes: Fennec, Focus, Klar, FirefoxBeta, Fennec_Enterprise
- Configurations: Fennec_Testing, FocusDebug, KlarDebug, release configs
- Destinations: simulator vs device
- Build types: regular build, build-for-testing

# Potential usage

narya build # Build default (Fennec for simulator)
narya build -p focus # Build Focus
narya build --for-testing # Build for testing
narya build --configuration release # Release build

2. narya test - Run tests

Multiple test plans are used repeatedly:

- UnitTest / UnitTests
- SmokeTest / Smoketest
- PerformanceTestPlan
- AccessibilityTestPlan
- FullFunctionalTests

narya test # Run unit tests
narya test --plan smoke # Run smoke tests
narya test --plan performance # Run performance tests

3. narya npm or fold into bootstrap

This pattern appears in almost every workflow:
npm install
npm run build

4. narya resolve-packages - Resolve SPM dependencies

Very common pre-build step:
xcodebuild -resolvePackageDependencies -onlyUsePackageVersionsFromResolvedFile

5. narya lint - Run SwiftLint

Used in CI with version pinning:

- Currently pins to version 0.62.2
- Runs via swiftlint-extended step

6. narya danger - Run Danger for PR checks

swift run danger-swift ci
Also generates coverage.json from xcresult.

7. narya screenshots - L10n screenshot generation

./firefox-ios/l10n-screenshots.sh en-US
./firefox-ios/l10n-screenshots.sh --test-without-building $LOCALES

8. narya sentry upload - Upload debug symbols

Repeated for Firefox, Focus, and Klar:
sentry-cli upload-dif --org mozilla --project firefox-ios $DSYM_PATH

9. narya codesign - Configure code signing

This sed pattern appears repeatedly:
sed -i '' 's/CODE_SIGN_IDENTITY = "iPhone Developer"/CODE_SIGN_IDENTITY = "iPhone Distribution"/' project.pbxproj

10. narya entitlements - Manage entitlements

For Focus/Klar, setting default browser entitlement:
/usr/libexec/PlistBuddy -c "Add :com.apple.developer.web-browser bool true" Focus.entitlements

Summary Table
┌───────────────────────┬──────────────────────┬────────────┬────────┐
│ Command │ Frequency in Bitrise │ Complexity │ Value │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ build │ ~15+ occurrences │ High │ ⭐⭐⭐ │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ test │ ~10+ occurrences │ Medium │ ⭐⭐⭐ │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ npm (or in bootstrap) │ ~8 occurrences │ Low │ ⭐⭐ │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ resolve-packages │ ~5 occurrences │ Low │ ⭐⭐ │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ lint │ ~3 occurrences │ Medium │ ⭐⭐ │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ danger │ ~2 occurrences │ Low │ ⭐ │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ screenshots │ ~3 occurrences │ Medium │ ⭐ │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ sentry upload │ ~8 occurrences │ Low │ ⭐⭐ │
├───────────────────────┼──────────────────────┼────────────┼────────┤
│ codesign │ ~6 occurrences │ Low │ ⭐⭐ │
└───────────────────────┴──────────────────────┴────────────┴────────┘
