#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
[ -x build/macos-arm64/btop-zh ] || { echo '请先运行 sh scripts/build-macos-arm64.sh。' >&2; exit 1; }
mkdir -p dist
staging=$(mktemp -d "$project_dir/dist/.package.XXXXXX")
trap 'rm -rf "$staging"' EXIT HUP INT TERM
package_name=btop-zh-macos-arm64
package_dir="$staging/$package_name"
mkdir -p "$package_dir/bin" "$package_dir/share/btop"
cp build/macos-arm64/btop-zh "$package_dir/bin/btop-zh"
cp -R themes "$package_dir/share/btop/"
cp LICENSE README.md CHANGELOG.md CONTRIBUTING.md THIRD_PARTY_NOTICES.md "$package_dir/"
cp -R docs "$package_dir/"
mkdir -p "$package_dir/licenses"
cp include/fmt/LICENSE.rst "$package_dir/licenses/fmt-LICENSE.rst"
cp packaging/macos/*.sh packaging/macos/*.command packaging/macos/安装说明.txt "$package_dir/"
chmod 755 "$package_dir/bin/btop-zh" "$package_dir/"*.sh "$package_dir/"*.command
(cd "$package_dir" && /usr/bin/find -s bin share docs licenses LICENSE README.md CHANGELOG.md CONTRIBUTING.md THIRD_PARTY_NOTICES.md install.sh uninstall.sh Install.command Uninstall.command 安装说明.txt -type f -exec /usr/bin/shasum -a 256 {} \; > PAYLOAD.sha256)
rm -rf "dist/$package_name"
mv "$package_dir" "dist/$package_name"
(cd dist && tar -czf "$package_name.tar.gz" "$package_name" && /usr/bin/ditto -c -k --keepParent "$package_name" "$package_name.zip" && shasum -a 256 "$package_name.tar.gz" "$package_name.zip" > SHA256SUMS && shasum -a 256 "$package_name.tar.gz" > "$package_name.tar.gz.sha256")
printf '一键安装包：%s/dist/%s.zip\n' "$project_dir" "$package_name"
