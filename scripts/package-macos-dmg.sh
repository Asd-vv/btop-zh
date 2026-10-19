#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
[ -f dist/btop-zh-macos-arm64/PAYLOAD.sha256 ] || {
  echo '请先运行 sh scripts/package-macos-arm64.sh。' >&2
  exit 1
}
staging=$(mktemp -d "$project_dir/dist/.dmg.XXXXXX")
trap 'rm -rf "$staging"' EXIT HUP INT TERM
python3 - "$project_dir" "$staging" <<'PY'
import pathlib, plistlib, shutil, sys
root, staging = map(pathlib.Path, sys.argv[1:])
for action, title in [('install', '安装 btop-zh'), ('uninstall', '卸载 btop-zh')]:
    app = staging / (title + '.app')
    contents = app / 'Contents'
    executable = contents / 'MacOS/launch'
    resources = contents / 'Resources'
    executable.parent.mkdir(parents=True)
    resources.mkdir()
    if action == 'install':
        shutil.copytree(root / 'dist/btop-zh-macos-arm64', resources / 'payload')
        command = 'payload/Install.command'
    else:
        for name in ['Uninstall.command', 'uninstall.sh']:
            shutil.copy2(root / 'packaging/macos' / name, resources / name)
        command = 'Uninstall.command'
    executable.write_text('''#!/bin/sh
set -eu
resources=$(CDPATH= cd -- "$(dirname -- "$0")/../Resources" && pwd)
command="$resources/''' + command + '''"
if [ "${1:-}" = --check ]; then
  [ -f "$command" ] && [ -x "$command" ]
  exit
fi
exec /usr/bin/open -a Terminal "$command"
''')
    executable.chmod(0o755)
    info = {
        'CFBundleIdentifier': 'org.btop-zh.' + action,
        'CFBundleName': title,
        'CFBundleDisplayName': title,
        'CFBundleExecutable': 'launch',
        'CFBundlePackageType': 'APPL',
        'CFBundleShortVersionString': '1.4.7',
        'CFBundleVersion': '1.4.7',
        'LSMinimumSystemVersion': '15.0',
        'LSUIElement': True,
        'NSHighResolutionCapable': True,
        'NSHumanReadableCopyright': 'Apache-2.0; based on aristocratos/btop and dijiaozhibei-top/btop-cn',
    }
    with (contents / 'Info.plist').open('wb') as stream:
        plistlib.dump(info, stream)
    (contents / 'PkgInfo').write_text('APPL????')
shutil.copy2(root / 'packaging/macos/dmg/安装说明.txt', staging / '安装说明.txt')
shutil.copy2(root / 'LICENSE', staging / 'LICENSE')
PY
for app in "$staging/"*.app; do
  /usr/bin/plutil -lint "$app/Contents/Info.plist"
  "$app/Contents/MacOS/launch" --check
  /usr/bin/codesign --force --sign - --timestamp=none "$app"
  /usr/bin/codesign --verify --deep --strict "$app"
done
/usr/bin/hdiutil create -ov -volname 'btop-zh 中文版安装' -srcfolder "$staging" -fs HFS+ -format UDZO "$project_dir/dist/btop-zh-macos-arm64.dmg"
/usr/bin/hdiutil verify "$project_dir/dist/btop-zh-macos-arm64.dmg"
(cd dist && shasum -a 256 btop-zh-macos-arm64.tar.gz btop-zh-macos-arm64.zip btop-zh-macos-arm64.dmg > SHA256SUMS)
printf 'DMG 安装包：%s/dist/btop-zh-macos-arm64.dmg\n' "$project_dir"
