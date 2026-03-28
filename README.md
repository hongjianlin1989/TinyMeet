# TinyMeet

## CI / Fastlane setup

This project includes a minimal Fastlane + CircleCI setup for running iOS unit tests on the `TinyMeet` scheme.

### Files added
- `.circleci/config.yml`
- `Gemfile`
- `fastlane/Appfile`
- `fastlane/Fastfile`

### What the Fastlane lane does
The `ios tests` lane will:
- resolve Swift package dependencies
- run unit tests for the `TinyMeet` scheme
- target an iOS simulator
- disable code signing for CI test runs

### Local setup
Install gems with Bundler:

```bash
bundle install
```

Run the test lane locally:

```bash
bundle exec fastlane ios tests
```

If you need a different simulator, override the environment variables:

```bash
SIMULATOR_NAME="iPhone 16" SIMULATOR_OS="18.2" bundle exec fastlane ios tests
```

### CircleCI behavior
The CircleCI workflow will:
- use a macOS Xcode image
- install Ruby gems with Bundler
- run `bundle exec fastlane ios tests`
- store Fastlane test output as artifacts

### Important Xcode prerequisite
CI needs the `TinyMeet` scheme to be shared in source control.

If CircleCI cannot find the scheme, open Xcode and make sure the scheme is shared, then commit the generated file under:

- `TinyMeet.xcodeproj/xcshareddata/xcschemes/`

### Current scope
This setup is intentionally minimal and currently focuses on unit-test CI.

Possible next steps:
- add UI-test coverage in a separate job
- add linting
- add Fastlane lanes for beta/TestFlight delivery
- add signing and App Store Connect configuration
