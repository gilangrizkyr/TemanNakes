#!/bin/bash
# =====================================================
# Teman Nakes - Android Studio Setup Script
# Run this in the project root ONCE after cloning.
# =====================================================

FLUTTER_PATH="$HOME/flutter/bin"

echo "🩺 Teman Nakes - Setup Script"
echo "==============================="

# Check if Flutter is available
if [ -f "$FLUTTER_PATH/flutter" ]; then
    export PATH="$PATH:$FLUTTER_PATH"
    echo "✅ Flutter SDK ditemukan di: $FLUTTER_PATH"
elif command -v flutter &> /dev/null; then
    echo "✅ Flutter SDK ditemukan di PATH sistem."
else
    echo "❌ Flutter SDK tidak ditemukan!"
    echo "   Jalankan: tar xf flutter_linux_*-stable.tar.xz"
    echo "   Tarball dapat diunduh dari: https://flutter.dev/docs/get-started/install/linux"
    exit 1
fi

# Get dependencies
echo ""
echo "📦 Mengambil dependencies..."
flutter pub get

# Generate database (jika python3 tersedia)
echo ""
echo "🗄️  Memastikan database tersedia..."
if command -v python3 &> /dev/null; then
    python3 scripts/generate_db.py && echo "✅ Database OK."
else
    echo "⚠️  python3 tidak ditemukan, skip generate database."
    echo "   Pastikan file 'assets/database/temannakes.db' sudah ada."
fi

echo ""
echo "✨ Setup selesai! Project siap dibuka di Android Studio."
echo ""
echo "   Langkah selanjutnya:"
echo "   1. Buka Android Studio"
echo "   2. File > Open > Pilih folder ini (TemanNakes)"
echo "   3. Tunggu Gradle sync selesai"
echo "   4. Tekan tombol Run (▶) untuk menjalankan di emulator/device"
echo ""
echo "   Pastikan Plugin 'Flutter' dan 'Dart' sudah terinstall di Android Studio:"
echo "   Settings > Plugins > cari 'Flutter' > Install"
