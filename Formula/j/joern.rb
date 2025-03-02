class Joern < Formula
  desc "Open-source code analysis platform based on code property graphs"
  homepage "https://joern.io/"
  url "https://github.com/joernio/joern/archive/refs/tags/v4.0.270.tar.gz"
  sha256 "b33ffe32a2e267d82453053b4d4aa67c01a4892a6369da3f773b768141883ce0"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    throttle 10
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "0f89f51dc6b8ae33e4a2d2f3033b8564f24b51393bd510653f4eedb935b3b0f5"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "db89fe4dd710e280ff6881b1759be6ad92bc29d72cfee18de62b886c3b967673"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "ee7a42b37df0199caca6779597d446491a0ee4488506c7c982a88ba6b631931d"
    sha256 cellar: :any_skip_relocation, sonoma:        "c1520f288e3cd67c2d247c70224763b81843e1bc6d7cfb820b0dfcc61b9c7202"
    sha256 cellar: :any_skip_relocation, ventura:       "bd49879c88eae420495e901db6618d6479bb3df0996719edcb88dc7faebfafe1"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "ffede7494c738b321f21b2824a0103b51c338c54a13f4d2b870f0d5213858df8"
  end

  depends_on "sbt" => :build
  depends_on "astgen"
  depends_on "coreutils"
  depends_on "openjdk"
  depends_on "php"

  uses_from_macos "zlib"

  def install
    system "sbt", "stage"

    cd "joern-cli/target/universal/stage" do
      rm(Dir["**/*.bat"])
      libexec.install Pathname.pwd.children
    end

    # Remove incompatible pre-built binaries
    os = OS.mac? ? "macos" : OS.kernel_name.downcase
    astgen_suffix = Hardware::CPU.intel? ? [os] : ["#{os}-#{Hardware::CPU.arch}", "#{os}-arm"]
    libexec.glob("frontends/{csharp,go,js}src2cpg/bin/astgen/{dotnet,go,}astgen-*").each do |f|
      f.unlink unless f.basename.to_s.end_with?(*astgen_suffix)
    end

    libexec.children.select { |f| f.file? && f.executable? }.each do |f|
      (bin/f.basename).write_env_script f, Language::Java.overridable_java_home_env
    end
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      void print_number(int x) {
        std::cout << x << std::endl;
      }

      int main(void) {
        print_number(42);
        return 0;
      }
    CPP

    assert_match "Parsing code", shell_output("#{bin}/joern-parse test.cpp")
    assert_path_exists testpath/"cpg.bin"
  end
end
