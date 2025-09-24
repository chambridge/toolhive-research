#!/bin/bash
set -euo pipefail

# Toolhive MCP Registry - ToolHive CLI Installation Script
# Automates download and installation of ToolHive CLI

# Configuration
VERSION="v0.3.5"
INSTALL_DIR="$HOME/bin"
BINARY_NAME="thv"

# Detect platform
PLATFORM=""
ARCH=""

case "$(uname -s)" in
    Darwin) PLATFORM="darwin" ;;
    Linux)  PLATFORM="linux" ;;
    *)      echo "❌ Unsupported platform: $(uname -s)"; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64)  ARCH="amd64" ;;
    arm64)   ARCH="arm64" ;;
    aarch64) ARCH="arm64" ;;
    *)       echo "❌ Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

ARCHIVE_NAME="toolhive_${VERSION#v}_${PLATFORM}_${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/stacklok/toolhive/releases/download/${VERSION}/${ARCHIVE_NAME}"

echo "🚀 Installing ToolHive CLI..."
echo "  Version: $VERSION"
echo "  Platform: $PLATFORM"
echo "  Architecture: $ARCH"
echo "  Install Directory: $INSTALL_DIR"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Check if already installed
if [[ -x "$INSTALL_DIR/$BINARY_NAME" ]]; then
    CURRENT_VERSION=$("$INSTALL_DIR/$BINARY_NAME" version 2>/dev/null | head -1 || echo "unknown")
    echo "ℹ️ ToolHive CLI already installed: $CURRENT_VERSION"
    read -p "Reinstall with $VERSION? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Download and extract
echo "📦 Downloading ToolHive CLI..."
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

cd "$TEMP_DIR"
if curl -L -o "$ARCHIVE_NAME" "$DOWNLOAD_URL"; then
    echo "✅ Download successful"
else
    echo "❌ Download failed"
    exit 1
fi

echo "📦 Extracting archive..."
if tar -xzf "$ARCHIVE_NAME"; then
    echo "✅ Extraction successful"
else
    echo "❌ Extraction failed"
    exit 1
fi

# Install binary
if [[ -f "$BINARY_NAME" ]]; then
    chmod +x "$BINARY_NAME"
    cp "$BINARY_NAME" "$INSTALL_DIR/"
    echo "✅ ToolHive CLI installed to $INSTALL_DIR/$BINARY_NAME"
else
    echo "❌ Binary not found in archive"
    exit 1
fi

# Check installation
if "$INSTALL_DIR/$BINARY_NAME" version &>/dev/null; then
    INSTALLED_VERSION=$("$INSTALL_DIR/$BINARY_NAME" version | head -1)
    echo "✅ Installation verified: $INSTALLED_VERSION"
else
    echo "❌ Installation verification failed"
    exit 1
fi

# Check PATH
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo "✅ $INSTALL_DIR is in PATH"
else
    echo "⚠️ $INSTALL_DIR is not in PATH"
    echo ""
    echo "Add to your shell profile:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
    echo "For bash/zsh:"
    echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.bashrc"
    echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.zshrc"
fi

echo ""
echo "🎉 ToolHive CLI installation complete!"
echo ""
echo "Next steps:"
echo "1. Configure registry: $BINARY_NAME config set-registry \$(pwd)/registry/registry.json"
echo "2. List available servers: $BINARY_NAME registry list"
echo "3. Deploy a server: $BINARY_NAME run osv-scanner"