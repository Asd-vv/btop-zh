#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
python3 - <<'PY'
import pathlib, subprocess, zipfile
root = pathlib.Path.cwd()
files = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z']).split(b'\0')
output = root / 'dist/btop-zh-source.zip'
output.parent.mkdir(exist_ok=True)
count = 0
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for name in sorted(set(files)):
        if not name:
            continue
        relative = pathlib.Path(name.decode('utf-8'))
        if relative.parts[0] in {'.git', 'build', 'dist'} or relative.name == '.DS_Store' or '__pycache__' in relative.parts:
            continue
        source = root / relative
        if source.is_file():
            archive.write(source, str(pathlib.Path('btop-zh-source') / relative))
            count += 1
print(f'源码包：{output}（{count} 个文件，不含 Git 元数据和构建结果）')
PY
(cd dist && shasum -a 256 btop-zh-source.zip > btop-zh-source.zip.sha256)
