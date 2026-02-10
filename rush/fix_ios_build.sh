#!/bin/bash
set -e

# 1. Clean Flutter Build
echo "🧹 Cleaning Flutter project..."
flutter clean
flutter pub get

# 2. Reinstall Pods (selectively)
cd ios
echo "🗑️ Removing problematic pods..."
rm -rf Pods/FirebaseFirestoreInternal
rm -f Podfile.lock
# We keep Pods/BoringSSL-GRPC to avoid re-downloading 300MB

echo "📦 Installing Pods..."
pod install

# 3. Patch gRPC-Core Source
echo "🩹 Applying gRPC-Core patch (basic_seq.h)..."
TARGET_FILE="Pods/gRPC-Core/src/core/lib/promise/detail/basic_seq.h"
if [ -f "$TARGET_FILE" ]; then
    # Remove 'template' keyword from line 100ish
    sed -i '' 's/Tr::template CheckResultAndRunNext/Tr::CheckResultAndRunNext/g' "$TARGET_FILE"
    echo "✅ Patch applied to basic_seq.h"
else
    echo "❌ Error: gRPC-Core file not found at $TARGET_FILE"
    exit 1
fi

# 4. Fix Module Map Symlink
echo "🔗 Fixing gRPC-Core module map..."
mkdir -p Pods/Headers/Private/grpc
ln -sf "../../../Target Support Files/gRPC-Core/gRPC-Core.modulemap" "Pods/Headers/Private/grpc/gRPC-Core.modulemap"
echo "✅ Module map symlinked."

echo "🚀 Done. Ready to build."
