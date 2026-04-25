# TinyMeet

## CI / Fastlane setup

This project includes CI setup for validating the `TinyMeet` Xcode project, with automated build and unit-test checks targeting the shared `TinyMeet-Staging` scheme.

## Dependency management

This repository contains both a root `Package.swift` and an Xcode app project.

- `TinyMeet.xcodeproj` is the source of truth for the iOS app target's package dependencies.
- `Package.swift` is kept aligned for local SwiftPM resolution and package-level tooling.

If you add or update Firebase, GoogleSignIn, or test packages, make sure the Xcode project and `Package.swift` stay in sync.

### Nightly builds (CircleCI) — only when new merges landed

CircleCI contains a scheduled workflow named `nightly-testflight`.

- It runs nightly on the `main` branch.
- It only performs the nightly work if there were **new commits merged** since the last successful nightly run.

How the “only if merged” logic works:
- CI compares `HEAD` to a tag in the repo: `nightly-testflight-last-success`
- If they match, the job halts early (no build/upload)
- If they differ (or the tag doesn’t exist), the job runs the nightly lane and then force-updates the tag

Scripts:
- `ci/should_upload_nightly.sh`
- `ci/mark_nightly_success.sh`

### Required CircleCI configuration for nightly TestFlight

1) **App Store Connect API key** (recommended for CI)

Add these environment variables in CircleCI Project Settings:
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_KEY_CONTENT` (base64-encoded `.p8` content)

These are used by `fastlane ios nightly_beta`.

The `nightly_beta` lane will:
- resolve Swift package dependencies
- set a timestamp-based build number
- archive the `TinyMeet-Staging` scheme for App Store distribution
- upload the generated IPA to TestFlight

2) **Repo write access to push the gating tag**

The nightly job updates the git tag `nightly-testflight-last-success` on `origin`.

In CircleCI:
- Project Settings → **SSH Keys** → add an SSH key with **write access** to the repo

Without this, the nightly job can still build/upload, but it won’t be able to update the tag, and you’ll upload every night.

3) **Signing for archive/export**

The nightly lane performs an App Store archive/export, so CircleCI must also have valid signing available for the `TinyMeet-Staging` app target.

Examples:
- Xcode automatic signing with the required certificates/profiles available on the CircleCI machine
- or a Fastlane-managed signing setup such as `match`

Without signing, the nightly job can pass the gate step but fail during `build_app` before upload.

### Files used by CI
- `.github/workflows/ios-ci.yml`
- `.circleci/config.yml`
- `.swiftlint.yml`
- `Gemfile`
- `fastlane/Appfile`
- `fastlane/Fastfile`

### What the Fastlane lane does
The `ios tests` lane will:
- resolve Swift package dependencies
- run unit tests for the `TinyMeet-Staging` scheme
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

### Optional local parity with CI
If you want to mirror the main CI checks locally, run:

```bash
swiftlint lint --strict --config .swiftlint.yml
xcodebuild -project "TinyMeet.xcodeproj" -scheme "TinyMeet-Staging" -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build
bundle exec fastlane ios tests
```

## GitHub Actions
The GitHub Actions workflow lives at:

- `.github/workflows/ios-ci.yml`

It runs on:
- pushes
- pull requests targeting `main` or `develop`

The workflow currently runs these checks:
- SwiftLint
- Xcode unit tests against `TinyMeet-Staging`

This is the workflow that should appear on GitHub pull requests as status checks.

## CircleCI
The CircleCI workflow currently uses a macOS Xcode image and runs on branch pushes, including commits that update an open pull request.

That validation workflow runs these checks in order:
- install Ruby gems with Bundler
- install SwiftLint with Homebrew
- run `swiftlint lint --strict --config .swiftlint.yml`
- run an Xcode build check for the `TinyMeet-Staging` scheme
- run `bundle exec fastlane ios tests`
- store Fastlane test output as artifacts

### Pull request validation
When you create or update a pull request on GitHub, GitHub Actions should validate the branch with:
- SwiftLint
- staging unit tests

If you do not see those checks on the PR page, the usual causes are:
- no workflow file under `.github/workflows/`
- GitHub Actions disabled for the repository
- the workflow file not present on the PR branch
- missing shared Xcode scheme in source control

### Important Xcode prerequisite
CI needs the `TinyMeet-Staging` scheme to be shared in source control.

If CI cannot find the scheme, open Xcode and make sure the scheme is shared, then commit the generated file under:

- `TinyMeet.xcodeproj/xcshareddata/xcschemes/`

This repository should now contain the shared staging and production `.xcscheme` files so CI can target staging explicitly.

### Current scope
This setup currently focuses on core validation for pull requests and branch pushes:
- lint
- unit tests against staging
- build checks on CircleCI against staging

Possible next steps:
- add UI-test coverage in a separate job
- add a dedicated Fastlane build lane for CI consistency
- add beta/TestFlight delivery lanes
- add signing and App Store Connect configuration
