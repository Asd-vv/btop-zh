#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu
fail() { printf '安装失败：%s\n' "$*" >&2; exit 1; }
take_over=false
case "${1:-}" in
  '') ;;
  --take-over) take_over=true ;;
  *) fail '用法：sh install.sh [--take-over]' ;;
esac
[ "$(uname -s)" = Darwin ] || fail '仅支持 macOS。'
[ "$(uname -m)" = arm64 ] || fail '请在 Apple Silicon Mac 的原生 ARM 终端中安装。'
mac_major=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f1)
[ "$mac_major" -ge 15 ] || fail '此编译包要求 macOS 15 或更高版本。'
[ -n "${HOME:-}" ] && [ "$HOME" != / ] || fail '无法确定用户主目录。'
[ "$(id -u)" -ne 0 ] || fail '请使用普通用户运行，不要使用 sudo。'
package_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
install_dir="$HOME/.local/share/btop-zh"
command_dir="$HOME/.local/bin"
marker='btop-zh user installation v1'
wrapper_marker='# Managed by btop-zh installer v1'
[ ! -L "$install_dir" ] || fail '安装目录不能是符号链接。'
if [ -e "$install_dir" ]; then
  [ -f "$install_dir/.managed" ] && [ "$(cat "$install_dir/.managed")" = "$marker" ] || fail "目录已存在且不属于此安装器：$install_dir"
fi
[ -f "$package_dir/PAYLOAD.sha256" ] || fail '缺少文件校验清单，请重新解压完整安装包。'
(cd "$package_dir" && /usr/bin/shasum -a 256 -c PAYLOAD.sha256 >/dev/null) || fail '安装包文件校验失败。'
/usr/bin/file "$package_dir/bin/btop-zh" | /usr/bin/grep -q 'Mach-O 64-bit executable arm64' || fail '安装包中的程序不是 macOS ARM64 格式。'
managed_command() {
  [ -f "$1" ] && [ ! -L "$1" ] && /usr/bin/grep -Fqx "$wrapper_marker" "$1"
}
# Detect a command elsewhere in PATH before changing shell configuration.
existing=$(command -v btop 2>/dev/null || true)
if [ -n "$existing" ] && ! managed_command "$existing" && [ "$take_over" = false ]; then
  printf '检测到已有 btop：%s\n' "$existing"
  if [ -t 0 ]; then
    printf '是否让中文版成为默认 btop？原版程序将保留。[y/N] '
    read -r answer
    case "$answer" in y|Y|yes|YES) take_over=true ;; *) fail '已取消。也可用 --take-over 明确选择中文版。' ;; esac
  else
    fail '请用 --take-over 明确选择中文版，原版文件不会被覆盖。'
  fi
fi
for name in btop btop-zh; do
  target="$command_dir/$name"
  if { [ -e "$target" ] || [ -L "$target" ]; } && ! managed_command "$target"; then
    [ "$take_over" = true ] || fail "已有同名文件：$target；可用 --take-over 备份后安装。"
    [ ! -e "$install_dir/backups/$name" ] && [ ! -L "$install_dir/backups/$name" ] || fail "已有旧备份，无法再次备份 $name。请先检查 $install_dir/backups。"
  fi
done
# Check profiles before installing anything; ZDOTDIR is honored for zsh.
zsh_profile="${ZDOTDIR:-$HOME}/.zshrc"
bash_profile="$HOME/.bash_profile"
for profile in "$zsh_profile" "$bash_profile"; do
  if [ -e "$profile" ]; then
    [ -f "$profile" ] && [ -w "$profile" ] || fail "无法更新配置文件：$profile"
    if /usr/bin/grep -Fq '# >>> btop-zh PATH >>>' "$profile"; then
      /usr/bin/grep -Fq '# <<< btop-zh PATH <<<' "$profile" || fail "PATH 配置块不完整：$profile"
    fi
  fi
done
mkdir -p "$install_dir/releases" "$install_dir/backups" "$command_dir"
printf '%s\n' "$marker" > "$install_dir/.managed"
release_id=$(/usr/bin/shasum -a 256 "$package_dir/PAYLOAD.sha256" | /usr/bin/cut -c1-16)
staging=$(mktemp -d "$install_dir/releases/.stage.XXXXXX")
trap 'if [ -n "${staging:-}" ] && [ -d "$staging" ]; then rm -rf "$staging"; fi' EXIT HUP INT TERM
cp -R "$package_dir/bin" "$package_dir/share" "$package_dir/docs" "$package_dir/licenses" "$staging/"
cp "$package_dir/LICENSE" "$package_dir/README.md" "$package_dir/THIRD_PARTY_NOTICES.md" "$package_dir/CHANGELOG.md" "$package_dir/CONTRIBUTING.md" "$staging/"
chmod 755 "$staging/bin/btop-zh"
if [ ! -e "$install_dir/releases/$release_id" ]; then
  mv "$staging" "$install_dir/releases/$release_id"
else
  rm -rf "$staging"
fi
staging=''
[ ! -e "$install_dir/current" ] || [ -L "$install_dir/current" ] || fail 'current 已存在且不是符号链接。'
ln -sfn "releases/$release_id" "$install_dir/current"
cp "$package_dir/uninstall.sh" "$install_dir/uninstall.sh"
chmod 755 "$install_dir/uninstall.sh"
for name in btop btop-zh; do
  target="$command_dir/$name"
  if { [ -e "$target" ] || [ -L "$target" ]; } && ! managed_command "$target"; then
    mv "$target" "$install_dir/backups/$name"
  fi
  # Both launchers execute the real packaged path so its bundled themes resolve.
  cat > "$target" <<'WRAPPER'
#!/bin/sh
# Managed by btop-zh installer v1
exec "$HOME/.local/share/btop-zh/current/bin/btop-zh" "$@"
WRAPPER
  chmod 755 "$target"
done
for profile in "$zsh_profile" "$bash_profile"; do
  mkdir -p "$(dirname -- "$profile")"
  if ! /usr/bin/grep -Fq '# >>> btop-zh PATH >>>' "$profile" 2>/dev/null; then
    # Preserve the original for reference; uninstall removes only our block.
    if [ -f "$profile" ]; then
      backup_name=$(printf '%s' "$profile" | /usr/bin/shasum -a 256 | /usr/bin/cut -c1-16)
      [ -f "$install_dir/backups/profile-$backup_name" ] || cp -p "$profile" "$install_dir/backups/profile-$backup_name"
    fi
    cat >> "$profile" <<'PROFILE'

# >>> btop-zh PATH >>>
case "$PATH" in
  "$HOME/.local/bin"|"$HOME/.local/bin":*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# <<< btop-zh PATH <<<
PROFILE
  fi
done
# Record the exact files touched, including a custom ZDOTDIR.
for profile in "$zsh_profile" "$bash_profile"; do
  if ! /usr/bin/grep -Fqx "$profile" "$install_dir/profiles.list" 2>/dev/null; then
    printf '%s\n' "$profile" >> "$install_dir/profiles.list"
  fi
done
"$command_dir/btop" --version
printf '\n安装完成。重新打开终端，输入 btop 即可运行中文版。\n'
printf '当前终端立即运行：\n  export PATH="$HOME/.local/bin:$PATH"; hash -r; btop\n'
printf '卸载：\n  sh "$HOME/.local/share/btop-zh/uninstall.sh"\n'
