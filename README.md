# ResizeLint Homebrew Tap

[![Homebrew validation](https://github.com/mikonyaa/homebrew-tap/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/mikonyaa/homebrew-tap/actions/workflows/tests.yml)

The official Homebrew tap for [ResizeLint](https://github.com/mikonyaa/ResizeLint), a deterministic static analyzer for Swift and UIKit layout assumptions that can break in resizable windows.

## Install

This formula builds the pinned [1.0.0 source release](https://github.com/mikonyaa/ResizeLint/releases/tag/1.0.0) with Swift Package Manager. It installs one executable; the upstream binary archives and macOS installer are separate distributions. Homebrew installs the declared dependencies. The package requires Swift 6.3 or newer and resolves the exact versions in `Package.resolved`; upstream's `.swift-version` is 6.3.3. The compiler actually used is printed during installation.

On macOS, the selected Xcode/Swift.org toolchain supplies the build compiler and macOS supplies runtime libraries. On Linux, Homebrew Swift is a required runtime dependency: the installed executable dynamically links Swift, Foundation and dispatch libraries. Keep the Homebrew Swift package installed on Linux. Formula revision `1` rebuilds existing 1.0.0 installations with this corrected dependency metadata; `resizelint version` still prints `1.0.0`.

On macOS, install Xcode and its command line tools, and check `xcrun swift --version`: the selected compiler must be Swift 6.3 or newer. Older Xcode versions need an [official Swift.org toolchain](https://www.swift.org/install/macos/package_installer/) selected for CLI builds by exporting its plist `CFBundleIdentifier` as `TOOLCHAINS`; selecting it only in the Xcode IDE does not select it for Homebrew. CI selects Swift 6.3.3 on both macOS architectures. The formula avoids downloading a second Homebrew compiler on macOS; the current Homebrew Swift 6.4 bottle was observed failing its own Mach-O relocation during installation. Source builds also need network access to fetch the pinned Swift packages, disk space and time to compile SwiftSyntax. See [Homebrew's installation requirements](https://docs.brew.sh/Installation).

```sh
brew install mikonyaa/tap/resizelint
```

The source-validation jobs target these environments:

| Environment | CI runner | Validation boundary |
| --- | --- | --- |
| macOS Intel, Sonoma or newer | `macos-15-intel` | Xcode SDK plus selected Swift 6.3.3; source install and all consumer/lifecycle checks. Older macOS releases need their own evidence. |
| macOS Apple Silicon, Sonoma or newer | `macos-26` | Source install, analyzer smoke test, audit/style, linkage and lifecycle checks. Older macOS releases need their own consumer evidence. |
| Linux x86_64 | `ubuntu-24.04` | Source install and the same consumer checks, including ELF runtime linkage. |

Other Linux architectures/distributions are not covered by this matrix. A configured runner is not a passing installation: consult the result and uploaded evidence for the exact commit.

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

Keep `brew config`, the install log (including its Swift version), `brew test` output and linkage output when investigating a build/runtime problem. Missing Swift shared libraries on Linux indicate an incomplete runtime dependency; do not fix an installation by setting a global `LD_LIBRARY_PATH`. See [Homebrew troubleshooting](https://docs.brew.sh/Troubleshooting) and [maintainer validation/version updates](MAINTAINING.md).

`Formula/resizelint.rb` in this tap is the source of truth for `brew install mikonyaa/tap/resizelint`. The duplicate formula in the upstream repository is a reference copy; synchronizing it requires a separate upstream change. See the [ownership procedure](MAINTAINING.md#formula-ownership).

Documentation, rule references, and release notes are maintained in the [ResizeLint repository](https://github.com/mikonyaa/ResizeLint). Report product issues in its [issue tracker](https://github.com/mikonyaa/ResizeLint/issues).

## License

ResizeLint and this tap are available under the [MIT License](LICENSE).
