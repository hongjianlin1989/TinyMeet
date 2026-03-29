# TinyMeet

## CI / Fastlane setup

This project includes a lightweight Fastlane + CircleCI setup for validating the `TinyMeet` Xcode project in CI.

### Files used by CI
- `.circleci/config.yml`
- `.swiftlint.yml`
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

Run the Fastlane test lane locally:

```bash
bundle exec fastlane ios tests
```

If you need a different simulator, override the environment variables:

```bash
SIMULATOR_NAME="iPhone 16" SIMULATOR_OS="18.2" bundle exec fastlane ios tests
```

### Optional local parity with CircleCI
If you want to mirror the main CI checks locally, run:

```bash
swiftlint lint --strict --config .swiftlint.yml
xcodebuild -project "TinyMeet.xcodeproj" -scheme "TinyMeet" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build
bundle exec fastlane ios tests
```

### CircleCI behavior
The CircleCI workflow currently uses a macOS Xcode image and runs on branch pushes, including commits that update an open pull request.

That validation workflow runs these checks in order:
- install Ruby gems with Bundler
- install SwiftLint with Homebrew
- run `swiftlint lint --strict --config .swiftlint.yml`
- run an Xcode build check for the `TinyMeet` scheme
- run `bundle exec fastlane ios tests`
- store Fastlane test output as artifacts

### Pull request validation
When you create or update a pull request, CircleCI will validate the branch with:
- lint
- build
- unit tests

This means unit-test checks are part of pull request validation, not just manual or post-merge runs.

### Important Xcode prerequisite
CI needs the `TinyMeet` scheme to be shared in source control.

If CircleCI cannot find the scheme, open Xcode and make sure the scheme is shared, then commit the generated file under:

- `TinyMeet.xcodeproj/xcshareddata/xcschemes/`

At the moment, make sure that shared scheme file is committed before relying on CircleCI build/test runs.

### Current scope
This setup currently focuses on core validation for pull requests and branch pushes:
- lint
- build
- unit tests

Possible next steps:
- add UI-test coverage in a separate job
- add a dedicated Fastlane build lane for CI consistency
- add beta/TestFlight delivery lanes
- add signing and App Store Connect configuration
