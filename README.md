# ResizeLint Homebrew Tap

[![Homebrew validation](https://github.com/mikonyaa/homebrew-tap/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/mikonyaa/homebrew-tap/actions/workflows/tests.yml)

The official Homebrew tap for [ResizeLint](https://github.com/mikonyaa/ResizeLint), a deterministic static analyzer for Swift and UIKit layout assumptions that can break in resizable windows.

## Install

This formula builds the pinned [1.0.0 source release](https://github.com/mikonyaa/ResizeLint/releases/tag/1.0.0) with Swift Package Manager. It installs one executable; the upstream binary archives and macOS installer are separate distributions. Homebrew installs the declared dependencies. The package requires Swift 6.3 or newer and resolves the exact versions in `Package.resolved`; upstream's `.swift-version` is 6.3.3. The compiler actually used is printed during installation.

On macOS, the selected Xcode/Swift.org toolchain supplies the build compiler and macOS supplies runtime libraries. On Linux, Swift is build-only: Homebrew's `std_swift_args` embeds the Swift runtime with `--static-swift-stdlib`. The tested ELF still uses system libc, libm, libstdc++ and libgcc_s; it is not a fully static or cross-distribution binary. Formula revision `1` rebuilds existing 1.0.0 installations with this source-packaging change; `resizelint version` still prints `1.0.0`.

On macOS, install Xcode and its command line tools, and check `xcrun swift --version`: the compiler must be Swift 6.3 or newer. Older Xcode versions need an [official Swift.org toolchain](https://www.swift.org/install/macos/package_installer/). Export its plist `CFBundleIdentifier` as `HOMEBREW_RESIZELINT_TOOLCHAIN` before installing; the formula passes it explicitly to `xcrun --toolchain`. Homebrew filters plain `TOOLCHAINS`, and selecting a toolchain only in the Xcode IDE does not select it for Homebrew. CI selects Swift 6.3.3 on both macOS architectures. Source builds need network access to fetch pinned packages, disk space and time to compile SwiftSyntax. See [Homebrew's installation requirements](https://docs.brew.sh/Installation).

For a manually installed Swift 6.3.3 toolchain:

```sh
export HOMEBREW_RESIZELINT_TOOLCHAIN=$(plutil -extract CFBundleIdentifier raw /Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/Info.plist)
xcrun --toolchain "$HOMEBREW_RESIZELINT_TOOLCHAIN" swift --version
```

The formula uses SwiftPM's current native build fallback and keeps Homebrew's sandbox enabled. Both build engines hit permission errors with a custom mounted temporary directory; the native engine with a standard temporary directory passed. SwiftPM 6.4 deprecates this fallback, so future compiler updates require validation. The formula also avoids the redundant macOS Homebrew Swift 6.4 bottle, which failed its own Mach-O relocation during installation.

```sh
brew install mikonyaa/tap/resizelint
```

The source-validation jobs target these environments:

| Environment | CI runner | Validation boundary |
| --- | --- | --- |
| macOS Intel, Sonoma or newer | `macos-15-intel` | Legacy source consumer check with Xcode SDK and selected Swift 6.3.3. Homebrew classifies Intel macOS as Tier 3. |
| macOS Apple Silicon, Sonoma or newer | `macos-26` | Source install, analyzer smoke test, audit/style, linkage and lifecycle checks. Older macOS releases need their own consumer evidence. |
| Linux x86_64 | `ubuntu-24.04` | Source install and the same consumer checks, including ELF runtime linkage. |

Other Linux architectures/distributions are not covered by this matrix. A configured runner is not a passing installation: consult the result and uploaded evidence for the exact commit.

The formula retains upstream's minimum macOS 14 requirement. Homebrew's current [support tiers](https://docs.brew.sh/Support-Tiers) cover Apple Silicon macOS 15/26/27; Sonoma 14 and all Intel macOS environments are Tier 3. Older releases need separate consumer evidence and a compatible Swift compiler/SDK.

## Upgrade

```sh
brew update
brew upgrade resizelint
```

## Verify

```sh
resizelint version
brew test mikonyaa/tap/resizelint
brew linkage --test mikonyaa/tap/resizelint
```

`brew test` runs the installed CLI on small Swift files. It requires RL001 and exit `1` for `UIScreen.main.bounds.width`, no findings and exit `0` for geometry passed as a parameter, and exit `2` for a missing input. It parses JSON, checks relative diagnostic paths, and verifies that `--output report.json` writes the report with empty stdout.

For your project, run `resizelint lint . --format json --output report.json` from its root. Exit `0` means no finding reached the configured threshold; `1` means a policy finding, `2` means invalid input/configuration, and `3` means an operational failure. See the [upstream CLI contract](https://github.com/mikonyaa/ResizeLint/blob/1.0.0/Docs/CLI.md).

On every push to `main`, pull request and manual run, CI explicitly installs the current formula from source, even when only documentation changed. A separate PR job checks Homebrew's bottle mechanics and uploads review artifacts; it does not publish bottles. The historical green syntax-only run at `86c90cf` skipped installation and is not install evidence.

## Uninstall

```sh
brew uninstall resizelint
```

This removes the Homebrew executable. Independently installed ResizeLint copies and your source/report files are outside the formula's ownership. `type -a resizelint` helps identify another copy on PATH.

## Troubleshooting and maintenance

Keep `brew config`, the install log (including its Swift version), `brew test` output and linkage output when investigating a build/runtime problem. A Linux executable requesting Swift shared libraries does not match the tested source packaging; check its version and installation source instead of setting a global `LD_LIBRARY_PATH`. See [Homebrew troubleshooting](https://docs.brew.sh/Troubleshooting) and [maintainer validation/version updates](MAINTAINING.md).

`Formula/resizelint.rb` in this tap is the source of truth for `brew install mikonyaa/tap/resizelint`. The duplicate formula in the upstream repository is a reference copy; synchronizing it requires a separate upstream change. See the [ownership procedure](MAINTAINING.md#formula-ownership).

Documentation, rule references, and release notes are maintained in the [ResizeLint repository](https://github.com/mikonyaa/ResizeLint). Report product issues in its [issue tracker](https://github.com/mikonyaa/ResizeLint/issues).

## License

ResizeLint and this tap are available under the [MIT License](LICENSE).
