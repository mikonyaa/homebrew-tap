#!/usr/bin/env bash
set -euo pipefail

# This installer is exclusively for disposable GitHub-hosted macOS runners.
if [[ ${GITHUB_ACTIONS:-} != true || ${RUNNER_ENVIRONMENT:-} != github-hosted || ${RUNNER_OS:-} != macOS ]]
then
  printf '%s\n' 'Run this toolchain setup only in a disposable GitHub macOS job.' >&2
  exit 2
fi
evidence=${1:?Usage: scripts/setup-macos-toolchain.sh /absolute/evidence-directory}
mkdir -p "${evidence}"
runner_temp=${RUNNER_TEMP:?Required GitHub runner temp directory}
github_env=${GITHUB_ENV:?Required GitHub environment file}
runner_arch=${RUNNER_ARCH:?Required GitHub runner architecture}
package="${runner_temp}/swift-6.3.3-RELEASE-osx.pkg"
toolchain=/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain
if [[ -e ${toolchain} ]]
then
  printf '%s\n' 'Refusing to replace an existing Swift 6.3.3 toolchain.' >&2
  exit 2
fi
if [[ ${runner_arch} == X64 ]]
then
  sudo xcode-select --switch /Applications/Xcode_26.3.app
fi
xcode-select --print-path | tee "${evidence}/xcode-selection.log"
xcrun --show-sdk-path | tee "${evidence}/sdk.log"
curl --fail --location --retry 3 \
  https://download.swift.org/swift-6.3.3-release/xcode/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE-osx.pkg \
  --output "${package}"
shasum -a 256 "${package}" | tee "${evidence}/swift-package-sha256.log"
pkgutil --check-signature "${package}" | tee "${evidence}/swift-package-signature.log"
grep -Fq 'Developer ID Installer: Swift Open Source (V9AUD2URP3)' "${evidence}/swift-package-signature.log"
sudo installer -pkg "${package}" -target / | tee "${evidence}/swift-package-install.log"
identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${toolchain}/Info.plist")
[[ ${identifier} == org.swift.* ]] || exit 1
printf 'HOMEBREW_RESIZELINT_TOOLCHAIN=%s\nRESIZELINT_TEST_TOOLCHAIN=%s\n' "${identifier}" "${toolchain}" >>"${github_env}"
xcrun --toolchain "${identifier}" swift --version | tee "${evidence}/preflight-compiler.log"
