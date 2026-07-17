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
    system "swift", "build", "--disable-sandbox", "--configuration", "release"
    bin.install ".build/release/resizelint"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/resizelint version").strip
  end
end
