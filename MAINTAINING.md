# Maintaining the ResizeLint tap

## Validate a candidate

Use a fresh disposable Homebrew runner/container or prefix, never your regular Homebrew installation for lifecycle checks. Commit the candidate first: `brew tap` clones Git commits, not uncommitted files.

```sh
git add Formula/resizelint.rb scripts/validate-formula.sh .github/workflows/tests.yml README.md MAINTAINING.md
git commit -m "Validate ResizeLint source delivery"
RESIZELINT_DISPOSABLE=1 bash scripts/validate-formula.sh /tmp/resizelint-evidence
```

The script refuses an existing ResizeLint installation/candidate tap. It taps the local Git snapshot as `audit/resizelint-candidate` using a `file://` URL, records both commit SHAs and formula SHA-256 values, and compares the formula bytes before running:

```sh
brew install --build-from-source audit/resizelint-candidate/resizelint
brew test audit/resizelint-candidate/resizelint
brew audit --strict audit/resizelint-candidate/resizelint
brew style audit/resizelint-candidate/resizelint
brew linkage --test audit/resizelint-candidate/resizelint
```

It records `brew config`, platform, the selected Swift version, install receipt, `otool -L/-l` or `ldd/readelf`, commands and actual exit codes. It runs the linked executable on PATH outside the checkout without library-path overrides. Reinstall, `brew autoremove`, another smoke/linkage test, and uninstall run only after the disposable-environment opt-in. Check the installed-formula list after cleanup: retaining Swift because it is a runtime dependency is correct. Formula tests do not compile UIKit; these are analyzer consumers.

Each source-consumer job is mandatory on push `main`, manual dispatch and PR; it names the formula explicitly. The PR-only test-bot job covers bottle construction and review artifacts. It has no release upload or bottle publication step. Do not interpret a skipped job, syntax-only result, source build on another OS, or a downloaded upstream binary as this platform's source-install PASS.

## Update the upstream version

1. Inspect the upstream release and immutable tag before editing. Record the tag's peeled commit SHA, release URL, source URL, version and publisher-provided digest. Stop if the tag moved, the asset was replaced, or the checksum differs unexpectedly. Do not change the published 1.0.0 checksum to bypass a mismatch.
2. Download the source asset and independently calculate SHA-256:

   ```sh
   UPSTREAM_VERSION=1.0.0
   SOURCE_REVIEW_DIR=$(mktemp -d /tmp/resizelint-version.XXXXXX)
   git ls-remote --tags https://github.com/mikonyaa/ResizeLint.git "refs/tags/$UPSTREAM_VERSION" "refs/tags/$UPSTREAM_VERSION^{}"
   curl --fail --location "https://github.com/mikonyaa/ResizeLint/releases/download/$UPSTREAM_VERSION/ResizeLint-$UPSTREAM_VERSION-source.tar.gz" --output "$SOURCE_REVIEW_DIR/source.tar.gz"
   shasum -a 256 "$SOURCE_REVIEW_DIR/source.tar.gz"
   tar -tzf "$SOURCE_REVIEW_DIR/source.tar.gz"
   ```

3. Compare every archived source file against the recorded tag commit. Respect upstream's source archive exclusions (`.github` and `Formula` for 1.0.0), and verify `Package.swift`, `Package.resolved`, `.swift-version`, license and embedded CLI version. Confirm pinned SwiftSyntax, ArgumentParser and Yams revisions; test the compiler actually selected by Homebrew instead of assuming `.swift-version` controls it.
4. Update `url`/`sha256` together in this tap's formula. Keep the focused source build and MIT license. Review runtime changes with the installed binary. For a dependency/packaging change that requires rebuilding an existing upstream version, add/increment Homebrew `revision`; reset it on the next upstream version bump. Avoid changing upstream code inside the tap.
5. Commit and run the disposable candidate validator on macOS Intel, macOS ARM and Linux x86_64. Require install, functional smoke, audit/style, linkage and post-cleanup consumers. Record failures, environment blocks and unrun platforms separately. Review the patch and GitHub Actions artifacts before integrating it.
6. For an actual version upgrade, use a separate disposable tap: install the previously published version from a committed snapshot, advance that same test tap to the candidate commit, run `brew update`, `brew upgrade audit/resizelint-upgrade/resizelint`, then test/linkage/outside-checkout consumers and uninstall. Record both versions and receipts. When only one upstream release exists, reinstall is the available lifecycle evidence; a no-op upgrade or formula revision does not prove upgrade between upstream releases.
7. Prepare the upstream reference-formula follow-up described below. There is no automatic updater or push mechanism in this tap.

## Formula ownership

This repository's `Formula/resizelint.rb` is authoritative for the `mikonyaa/tap` installation command. `ResizeLint/Formula/resizelint.rb` is a reference copy and must not become an independently maintained delivery channel.

After an approved tap change, open a separate upstream review to copy the authoritative formula and add a pointer to this ownership policy. An upstream release/version PR should propose the corresponding tap URL/checksum update, then synchronize the reference copy after the tap review. Do not edit upstream in a tap-only task, mutate old tags/source assets, or assume the reference copy already includes current tap fixes.

## Official references

- [Homebrew formula tests and dependencies](https://docs.brew.sh/Formula-Cookbook)
- [Creating and maintaining a tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Homebrew Swift formula](https://formulae.brew.sh/formula/swift)
- [Swift Static Linux SDK](https://www.swift.org/documentation/articles/static-linux-getting-started.html) — an alternative upstream packaging route, not evidence that this dynamic source formula is static.
