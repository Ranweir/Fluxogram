#!/usr/bin/env bash
set -euo pipefail
T="${1:?telegram dir}"
PKG="com.fluxogram.app"
NAME="Fluxogram"

: "${TG_API_ID:?Set secret TG_API_ID}"
: "${TG_API_HASH:?Set secret TG_API_HASH}"

for f in $(grep -rlE 'applicationId' "$T" --include=build.gradle --include=build.gradle.kts); do
  sed -i -E "s/applicationId[ =]+\"[^\"]*\"/applicationId \"$PKG\"/" "$f"
  sed -i -E "/namespace/! s/\"org\.telegram\.messenger\.(beta|web)\"/\"$PKG\"/" "$f"
done

for f in $(grep -rl 'name="AppName"' "$T" --include=strings.xml); do
  sed -i -E "s|(<string name=\"AppName\"[^>]*>)[^<]*(</string>)|\1$NAME\2|" "$f"
done

B=$(find "$T" -name BuildVars.java | head -1)
sed -i -E "s/APP_ID = [0-9]+;/APP_ID = ${TG_API_ID};/" "$B"
sed -i -E "s/APP_HASH = \"[^\"]*\"/APP_HASH = \"${TG_API_HASH}\"/" "$B"

# Placeholder google-services.json with every package name the build may use
CLIENTS=""
for p in "$PKG" "$PKG.beta" "org.telegram.messenger" "org.telegram.messenger.beta" "org.telegram.messenger.web"; do
  [ -n "$CLIENTS" ] && CLIENTS="$CLIENTS,"
  CLIENTS="$CLIENTS{\"client_info\":{\"mobilesdk_app_id\":\"1:000000000000:android:0000000000000000000000\",\"android_client_info\":{\"package_name\":\"$p\"}},\"oauth_client\":[],\"api_key\":[{\"current_key\":\"placeholder-key\"}],\"services\":{\"appinvite_service\":{\"other_platform_oauth_client\":[]}}}"
done

for d in "$T/TMessagesProj_App" "$T/TMessagesProj"; do
  if [ -d "$d" ]; then
    echo "{\"project_info\":{\"project_number\":\"000000000000\",\"project_id\":\"fluxogram-placeholder\",\"storage_bucket\":\"fluxogram-placeholder.appspot.com\"},\"client\":[$CLIENTS],\"configuration_version\":\"1\"}" > "$d/google-services.json"
  fi
done

if [ -d overlay ] && [ "$(ls -A overlay)" ]; then
  cp -r overlay/. "$T/"
fi
echo "Patch done"
