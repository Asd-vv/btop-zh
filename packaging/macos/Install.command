#!/bin/sh
package_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$package_dir/install.sh"
status=$?
printf '\n按回车关闭此窗口。'
read -r answer
exit "$status"
