#!/bin/bash
set -e

# Install Flutter
if [ ! -d "/tmp/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
fi

export PATH="/tmp/flutter/bin:$PATH"

# Configure and build
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release
