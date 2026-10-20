#!/usr/bin/env python3
"""Verify live macOS power updates, including when GPU graphs are disabled.

Run outside a hardware-restricted sandbox; requires CPU Energy and SystemLoad.
"""
import fcntl
import os
import pathlib
import pty
import re
import select
import struct
import subprocess
import sys
import tempfile
import termios
import time

binary = str(pathlib.Path(sys.argv[1]).resolve())
for width, height, temperatures in [(120, 40, True), (80, 24, True), (80, 24, False)]:
    with tempfile.TemporaryDirectory(prefix='btop-power-') as temporary:
        config = pathlib.Path(temporary) / 'btop-zh'
        config.mkdir()
        (config / 'btop.conf').write_text(
            'lang = "zh"\nupdate_ms = 1000\nshow_cpu_watts = true\n'
            'show_gpu_info = "Off"\ncpu_graph_lower = "total"\n'
            f'check_temp = {str(temperatures).lower()}\n')
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', height, width, 0, 0))
        process = subprocess.Popen([binary, '--force-utf'], stdin=slave, stdout=slave,
                                   stderr=slave, env=dict(os.environ, TERM='xterm-256color',
                                                         XDG_CONFIG_HOME=temporary))
        os.close(slave)
        data = b''
        try:
            deadline = time.monotonic() + 4
            while time.monotonic() < deadline:
                if select.select([master], [], [], .1)[0]:
                    try:
                        data += os.read(master, 65536)
                    except OSError:
                        break
            plain = re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', data.decode('utf-8'))
            # CPU watts must update even with no GPU graph or GPU information shown.
            cpu = re.findall(r'CPU [^│]*?([0-9]+\.[0-9]+)W│', plain)
            system = re.findall(r' ~([0-9]+\.[0-9]+)W', plain)
            assert len(cpu) >= 2, f'CPU power missing or not refreshed: {plain[-3000:]}'
            assert len(system) >= 2, 'System power missing or not refreshed'
            assert all(0 <= float(value) < 1000 for value in cpu + system)
            os.write(master, b'q')
            assert process.wait(timeout=5) == 0
            print(f'PASS {width}x{height}, temperatures={temperatures}: '
                  f'CPU {cpu[-1]}W, system ~{system[-1]}W; GPU graphs disabled')
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
            os.close(master)
