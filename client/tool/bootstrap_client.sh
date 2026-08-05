#!/usr/bin/env bash
set -euo pipefail

client_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backup_root="$(mktemp -d)"

cleanup() {
  rm -rf "$backup_root"
}
trap cleanup EXIT

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter bulunamadı. Flutter 3.44 kararlı sürümünü PATH'e ekleyin." >&2
  exit 1
fi

cp -a "$client_root/lib" "$backup_root/lib"
cp -a "$client_root/test" "$backup_root/test"
cp -a "$client_root/assets" "$backup_root/assets"
cp "$client_root/pubspec.yaml" "$backup_root/pubspec.yaml"
cp "$client_root/analysis_options.yaml" "$backup_root/analysis_options.yaml"

cd "$client_root"
flutter create . \
  --platforms=android,web \
  --project-name=project_relay_client \
  --org=com.projectrelay

rm -rf "$client_root/lib" "$client_root/test" "$client_root/assets"
cp -a "$backup_root/lib" "$client_root/lib"
cp -a "$backup_root/test" "$client_root/test"
cp -a "$backup_root/assets" "$client_root/assets"
cp "$backup_root/pubspec.yaml" "$client_root/pubspec.yaml"
cp "$backup_root/analysis_options.yaml" "$client_root/analysis_options.yaml"

flutter pub get
flutter analyze

# Navigasyon, görünürlük ve kaydırma hatalarını önce küçük ve anlaşılır
# bir kabul paketiyle yakala. Bu testlerde hit-test uyarıları ölümcüldür.
flutter test --concurrency=1 --reporter=expanded \
  test/widget_test_support_test.dart \
  test/widget_test.dart

# İzole widget kabulünden sonra tüm istemci regresyonlarını çalıştır.
flutter test

echo
echo "Project Relay istemcisi hazır."
echo "Web: flutter run -d edge --dart-define=RELAY_API_URL=http://127.0.0.1:8000"
