#!/usr/bin/env python3
"""Exercise the native macOS TUI with isolated temporary configuration."""
import codecs
import fcntl
import os
import pathlib
import pty
import select
import struct
import subprocess
import sys
import tempfile
import termios
import time

binary = str(pathlib.Path(sys.argv[1]).resolve())

def run(width, height, language):
    with tempfile.TemporaryDirectory(prefix='btop-zh-ui-') as temporary:
        root = pathlib.Path(temporary)
        config = root / 'btop-zh'
        config.mkdir()
        (config / 'btop.conf').write_text(f'lang = "{language}"\nupdate_ms = 1000\n')
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', height, width, 0, 0))
        env = dict(os.environ, TERM='xterm-256color', LANG='en_US.UTF-8',
                   XDG_CONFIG_HOME=temporary, XDG_STATE_HOME=temporary)
        process = subprocess.Popen([binary, '--force-utf'], stdin=slave,
                                   stdout=slave, stderr=slave, env=env)
        os.close(slave)
        decoder = codecs.getincrementaldecoder("utf-8")()
        def read_for(seconds):
            deadline = time.monotonic() + seconds
            data = b''
            while time.monotonic() < deadline:
                if select.select([master], [], [], .1)[0]:
                    try:
                        data += os.read(master, 65536)
                    except OSError:
                        break
            return decoder.decode(data)
        try:
            initial = read_for(2)
            if process.poll() is not None:
                raise RuntimeError(f'Premature exit: {initial}')
            if language == 'zh':
                import re
                plain_initial = re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', initial)
                assert 'N优先级' in plain_initial, 'Priority footer label clipped'
                assert 's发送信号' in plain_initial, 'Signal action label clipped'
                assert '平均负载：' in plain_initial, 'Load average label missing'
                assert 'i读写' in plain_initial, 'Disk IO label missing'
                assert 'e进程树' in plain_initial, 'Process tree label clipped'
                if width >= 120:
                    assert 'k结束' in plain_initial, 'End-process footer label clipped'
            if '--process-dialogs' in sys.argv and language == 'zh':
                os.write(master, b'\x1b[B')
                read_for(.3)
                os.write(master, b's')
                signals = read_for(.4)
                assert '发送系统信号' in signals, 'Signal dialog missing'
                assert '信号可通知进程暂停、继续或退出。' in signals, 'Signal explanation missing'
                # Only inspect dialogs; never confirm a signal or a priority change.
                os.write(master, b'\x1b')
                read_for(.2)
                os.write(master, b'N')
                priority = read_for(.4)
                assert '调整优先级' in priority, 'Priority dialog title missing'
                assert '数值越小，优先级越高。' in priority, 'Priority explanation missing'
                assert '重设 PID' not in priority, 'Misleading PID label returned'
                os.write(master, b'\x1b')
                read_for(.2)
            os.write(master, b'm')
            menu = read_for(.5)
            assert ('选项' if language == 'zh' else '┌─┐') in menu, 'Main menu missing'
            # Click the first main-menu button at its visible text row.
            os.write(master, f'\x1b[<0;{width // 2};{height // 2 - 2}M'.encode())
            clicked = read_for(.5)
            assert ('语言' if language == 'zh' else 'Lang') in clicked, 'Menu mouse hit region missing'
            os.write(master, f'\x1b[<0;{width // 2};{height // 2 - 2}m'.encode())
            read_for(.1)
            os.write(master, b'\x1b')
            read_for(.2)
            os.write(master, b'\x1b')
            read_for(.2)
            os.write(master, b'h')
            help_text = read_for(.5)
            assert ('描述' if language == 'zh' else 'Description:') in help_text, 'Help missing'
            os.write(master, b'\x1b')
            read_for(.2)
            os.write(master, b'o')
            options = read_for(.5)
            assert ('语言' if language == 'zh' else 'Lang') in options, 'Language setting missing'
            if language == 'en':
                assert '界面语言' not in options, 'Chinese leaked into English'
            os.write(master, b'\x1b[B')
            theme_help = read_for(.4)
            assert ('设置界面颜色主题。' if language == 'zh' else 'Set color theme.') in theme_help, 'Theme description missing'
            if language == 'zh':
                assert 'Choose from all theme files' not in theme_help, 'English theme help leaked'
                for key, expected_help in [
                    (b'2', '调整 CPU 面板的位置。'),
                    (b'3', '检测 NVIDIA 显卡的 PCIe 吞吐量。'),
                    (b'4', '调整内存面板与网络面板的上下位置。'),
                    (b'5', '设置网络面板的图表字符类型。'),
                    (b'6', '调整进程面板的位置。'),
                ]:
                    os.write(master, key)
                    category_help = read_for(.4)
                    assert expected_help in category_help, f'Chinese category help missing for {key}'
            os.write(master, b'1')
            read_for(.2)
            os.write(master, b'\x1b[C')
            read_for(.3)
            os.write(master, b'\x1b')
            read_for(.2)
            os.write(master, b'q')
            read_for(.5)
            assert process.wait(timeout=3) == 0, 'Nonzero exit'
            assert not (root / 'btop').exists(), 'Original configuration was touched'
            expected = 'en' if language == 'zh' else 'zh'
            assert f'lang = \"{expected}\"' in (config / 'btop.conf').read_text(), 'Language setting was not saved'
            print(f'PASS {width}x{height} {language}: dashboard, mouse menu, option descriptions, language persistence, exit')
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=3)
            os.close(master)

for args in [(120, 40, 'zh'), (80, 24, 'zh'), (120, 40, 'en')]:
    run(*args)
