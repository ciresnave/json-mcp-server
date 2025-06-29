class JsonMcpServer < Formula
  desc "High-performance Model Context Protocol server for JSON operations"
  homepage "https://github.com/ciresnave/json-mcp-server"
  version "{{VERSION}}"
  license "MIT OR Apache-2.0"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/ciresnave/json-mcp-server/releases/download/v#{version}/json-mcp-server-v#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "{{SHA256_ARM64}}"
    else
      url "https://github.com/ciresnave/json-mcp-server/releases/download/v#{version}/json-mcp-server-v#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "{{SHA256_X64}}"
    end
  end

  def install
    bin.install "json-mcp-server"
    
    # Install documentation
    doc.install "README.md" if File.exist?("README.md")
    doc.install Dir["examples/*"] if Dir.exist?("examples")
  end

  test do
    # Test that the binary runs and shows version
    system "#{bin}/json-mcp-server", "--version"
    
    # Test basic functionality with a simple JSON file
    (testpath/"test.json").write('{"test": "data", "number": 42}')
    
    # The MCP server runs as a daemon, so we test it can start
    pid = spawn("#{bin}/json-mcp-server")
    sleep 1
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
