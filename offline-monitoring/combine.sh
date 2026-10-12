#!/usr/bin/env bash
set -euo pipefail

RV_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$RV_DIR"
RV_ARCHIVE="rv-monitoring-offline-riscv64.zip"

for rv_tool in sha256sum cat mktemp mv; do
    command -v "$rv_tool" >/dev/null 2>&1 || {
        printf 'Missing required tool: %s\n' "$rv_tool" >&2
        exit 1
    }
done

printf 'Checking all 16 parts...\n'
sha256sum -c parts.sha256

RV_PARTS=()
for ((rv_index=0; rv_index<16; rv_index++)); do
    printf -v rv_part '%s.part-%03d' "$RV_ARCHIVE" "$rv_index"
    [[ -f "$rv_part" ]] || {
        printf 'Missing part: %s\n' "$rv_part" >&2
        exit 1
    }
    RV_PARTS+=("$rv_part")
done

read -r RV_EXPECTED RV_LISTED < "$RV_ARCHIVE.sha256"
[[ "$RV_LISTED" == "$RV_ARCHIVE" && "$RV_EXPECTED" =~ ^[0-9a-f]{64}$ ]] || {
    printf 'Invalid archive checksum file.\n' >&2
    exit 1
}

RV_TEMP="$(mktemp "$RV_DIR/.rv-monitoring-merge.XXXXXX")"
trap 'rm -f -- "$RV_TEMP"' EXIT
printf 'Merging parts...\n'
cat -- "${RV_PARTS[@]}" > "$RV_TEMP"
printf '%s  %s\n' "$RV_EXPECTED" "$RV_TEMP" | sha256sum -c -
mv -f -- "$RV_TEMP" "$RV_ARCHIVE"
trap - EXIT
printf 'Ready: %s/%s\n' "$RV_DIR" "$RV_ARCHIVE"
