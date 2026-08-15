#!/bin/bash
set -e
curl -sL -o /tmp/flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.0-stable.tar.xz
tar -xf /tmp/flutter.tar.xz -C /tmp
/tmp/flutter/bin/flutter config --no-analytics
cd mobile_app
/tmp/flutter/bin/flutter build web --release \
  --dart-define=SUPABASE_URL="$VITE_SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$VITE_SUPABASE_ANON_KEY"
