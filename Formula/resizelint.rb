class Resizelint < Formula
  desc "Static analysis for Swift apps that need to work in every window size"
  homepage "https://github.com/mikonyaa/ResizeLint"
  url "https://github.com/mikonyaa/ResizeLint/releases/download/1.0.0/ResizeLint-1.0.0-source.tar.gz"
  sha256 "d9388896fb241af065ea44422364626ac30632f7f2ff5d0747acf2dad55b2bd0"
  license "MIT"

  depends_on "swift" => :build

  on_macos do
    depends_on macos: :sonoma
  end

  def install
    system "swift", "--version"
    system "swift", "build", "--disable-sandbox", "--configuration", "release"
    bin.install ".build/release/resizelint"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/resizelint version").strip

    (testpath/"Broken.swift").write <<~SWIFT
      import UIKit
      func viewport() { let width = UIScreen.main.bounds.width }
    SWIFT
    (testpath/"Clean.swift").write <<~SWIFT
      import UIKit
      func viewport(in bounds: CGRect) -> CGFloat { bounds.width }
    SWIFT

    broken = JSON.parse(shell_output("#{bin}/resizelint lint Broken.swift --format json", 1))
    assert_equal 1, broken.fetch("schemaVersion")
    assert_equal version.to_s, broken.fetch("toolVersion")
    assert_equal({ "command" => "lint", "paths" => ["Broken.swift"] }, broken.fetch("invocation"))
    assert_equal 1, broken.fetch("summary").fetch("filesAnalyzed")
    assert_equal 1, broken.fetch("summary").fetch("errors")
    assert_equal ["RL001"], broken.fetch("diagnostics").map { |diagnostic| diagnostic.fetch("ruleID") }
    assert_equal ["Broken.swift"], broken.fetch("diagnostics").map { |diagnostic| diagnostic.fetch("path") }
    assert_equal 2, broken.fetch("diagnostics").first.fetch("range").fetch("start").fetch("line")

    clean = JSON.parse(shell_output("#{bin}/resizelint lint Clean.swift --format json"))
    assert_equal 1, clean.fetch("schemaVersion")
    assert_equal [], clean.fetch("diagnostics")
    assert_equal({ "errors" => 0, "warnings" => 0, "info" => 0, "filesAnalyzed" => 1 }, clean.fetch("summary"))

    assert_empty shell_output("#{bin}/resizelint lint Broken.swift --format json --output report.json", 1)
    assert_path_exists testpath/"report.json"
    assert_equal broken, JSON.parse((testpath/"report.json").read)

    assert_empty shell_output("#{bin}/resizelint lint Missing.swift 2>missing.stderr", 2)
    missing = (testpath/"missing.stderr").read
    assert_match "missingPath", missing
    assert_match "Missing.swift", missing
  end
end
