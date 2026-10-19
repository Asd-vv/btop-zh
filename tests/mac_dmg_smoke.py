#!/usr/bin/env python3
"""Mount the DMG read-only and validate installation using temporary homes."""
import os
import pathlib
import plistlib
import subprocess
import sys
import tempfile

image = pathlib.Path(sys.argv[1]).resolve()
root = pathlib.Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='btop dmg validation ') as temporary:
    mount = pathlib.Path(temporary) / 'volume'
    mount.mkdir()
    attached = False
    try:
        subprocess.run(['/usr/bin/hdiutil', 'attach', '-readonly', '-nobrowse',
                        '-mountpoint', str(mount), '-plist', str(image)],
                       check=True, stdout=subprocess.DEVNULL)
        attached = True
        for title in ['安装 btop-zh', '卸载 btop-zh']:
            app = mount / (title + '.app')
            with (app / 'Contents/Info.plist').open('rb') as stream:
                info = plistlib.load(stream)
            assert info['CFBundleExecutable'] == 'launch'
            launcher = app / 'Contents/MacOS/launch'
            assert os.access(launcher, os.X_OK)
            subprocess.run([str(launcher), '--check'], check=True)
            subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(app)], check=True)
        payload = mount / '安装 btop-zh.app/Contents/Resources/payload'
        subprocess.run(['/usr/bin/shasum', '-a', '256', '-c', 'PAYLOAD.sha256'],
                       cwd=payload, check=True, stdout=subprocess.DEVNULL)
        subprocess.run([sys.executable, str(root / 'tests/mac_installer_smoke.py'),
                        str(payload)], check=True)
        print('PASS: read-only DMG, app entry points, signatures, payload and install/uninstall lifecycle')
    finally:
        if attached:
            subprocess.run(['/usr/bin/hdiutil', 'detach', str(mount)], check=True,
                           stdout=subprocess.DEVNULL)
