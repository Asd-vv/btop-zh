#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu
[ -n "${HOME:-}" ] && [ "$HOME" != / ] || exit 1
install_dir="$HOME/.local/share/btop-zh"
command_dir="$HOME/.local/bin"
if [ ! -d "$install_dir" ]; then printf '未发现用户级 btop-zh 安装。\n'; exit 0; fi
[ ! -L "$install_dir" ] && [ -f "$install_dir/.managed" ] && [ "$(cat "$install_dir/.managed")" = 'btop-zh user installation v1' ] || {
  printf '安装标记不匹配，未进行删除：%s\n' "$install_dir" >&2; exit 1;
}
keep_backups=false
for name in btop btop-zh; do
  target="$command_dir/$name"
  if [ -f "$target" ] && [ ! -L "$target" ] && /usr/bin/grep -Fqx '# Managed by btop-zh installer v1' "$target"; then
    rm "$target"
  fi
  if [ -e "$install_dir/backups/$name" ] || [ -L "$install_dir/backups/$name" ]; then
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      mv "$install_dir/backups/$name" "$target"
    else
      printf '同名命令已被其他程序修改，保留该文件及旧备份：%s\n' "$target"
      keep_backups=true
    fi
  fi
done
if [ -f "$install_dir/profiles.list" ]; then
  while IFS= read -r profile; do
    [ -f "$profile" ] || continue
    # Remove only the managed section; keep changes the user made after install.
    /usr/bin/grep -Fq '# >>> btop-zh PATH >>>' "$profile" || continue
    /usr/bin/grep -Fq '# <<< btop-zh PATH <<<' "$profile" || {
      printf '配置块不完整，请手动检查：%s\n' "$profile" >&2; exit 1;
    }
    temporary=$(mktemp "$(dirname -- "$profile")/.btop-zh-profile.XXXXXX")
    /usr/bin/awk '
      $0 == "# >>> btop-zh PATH >>>" {skip=1; next}
      $0 == "# <<< btop-zh PATH <<<" {skip=0; next}
      !skip {print}
    ' "$profile" > "$temporary"
    cat "$temporary" > "$profile"
    rm "$temporary"
  done < "$install_dir/profiles.list"
fi
if [ "$keep_backups" = true ]; then
  rm -rf "$install_dir/releases"
  rm -f "$install_dir/current"
  printf '程序已卸载；备份保留在 %s/backups。\n' "$install_dir"
else
  rm -rf "$install_dir"
  printf '卸载完成。\n'
fi
printf '用户配置 ~/.config/btop-zh 已保留；重新打开终端后生效。\n'
