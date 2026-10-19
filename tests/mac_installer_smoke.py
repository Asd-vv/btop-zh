#!/usr/bin/env python3
"""Verify installation, PATH, upgrades and uninstall only in temporary homes."""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

package = pathlib.Path(sys.argv[1]).resolve()
BASE_PATH = '/usr/bin:/bin:/usr/sbin:/sbin'


def environment(home):
    return dict(os.environ, HOME=str(home), ZDOTDIR=str(home),
                PATH=f'{home}/.local/bin:{BASE_PATH}', SHELL='/bin/zsh')


def run(args, env, ok=True, cwd=None):
    result = subprocess.run(args, env=env, cwd=cwd, stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    assert (result.returncode == 0) == ok, result.stdout
    return result.stdout


def state(home):
    return home / '.local/share/btop-zh'


def manifest(folder):
    files = sorted(str(p.relative_to(folder)) for p in folder.rglob('*')
                   if p.is_file() and p.name != 'PAYLOAD.sha256')
    result = subprocess.check_output(['/usr/bin/shasum', '-a', '256', *files], cwd=folder)
    (folder / 'PAYLOAD.sha256').write_bytes(result)


with tempfile.TemporaryDirectory(prefix='btop installer tests ') as temporary:
    root = pathlib.Path(temporary)
    clean = root / 'clean home 中文'
    clean.mkdir()
    env = environment(clean)
    (clean / '.zshrc').write_text('# original zsh settings\nexport BTOP_TEST_ORIGINAL=kept\n')
    (clean / '.bash_profile').write_text('# original bash settings\n')
    config = clean / '.config/btop-zh'
    config.mkdir(parents=True)
    (config / 'btop.conf').write_text('lang = "en"\n')
    run(['sh', str(package / 'install.sh')], env)
    assert (state(clean) / '.managed').is_file()
    for shell, flag in [('/bin/zsh', '-lic'), ('/bin/bash', '-lc')]:
        output = run([shell, flag, 'command -v btop; btop --version'], env)
        assert str(clean / '.local/bin/btop') in output, output
        assert 'btop-zh version:' in output, output
    # Reinstall must not duplicate profiles or releases.
    first_release = (state(clean) / 'current').readlink()
    profile = (clean / '.zshrc').read_text()
    run(['sh', str(package / 'install.sh')], env)
    assert (clean / '.zshrc').read_text() == profile
    assert (state(clean) / 'current').readlink() == first_release
    assert len(list((state(clean) / 'releases').iterdir())) == 1
    print('PASS: clean install, spaces/Chinese paths, zsh/bash btop command, idempotent reinstall')
    # A changed package installs a new release and preserves user configuration.
    upgrade = root / 'upgrade package'
    shutil.copytree(package, upgrade)
    with (upgrade / 'README.md').open('a') as stream:
        stream.write('\nInstaller upgrade fixture.\n')
    manifest(upgrade)
    run(['sh', str(upgrade / 'install.sh')], env)
    assert (state(clean) / 'current').readlink() != first_release
    assert len(list((state(clean) / 'releases').iterdir())) == 2
    assert (config / 'btop.conf').read_text() == 'lang = "en"\n'
    with (clean / '.zshrc').open('a') as stream:
        stream.write('# user changes after install\n')
    run(['sh', str(state(clean) / 'uninstall.sh')], env)
    assert not state(clean).exists()
    assert not (clean / '.local/bin/btop').exists()
    assert '# original zsh settings' in (clean / '.zshrc').read_text()
    assert '# user changes after install' in (clean / '.zshrc').read_text()
    assert '# >>> btop-zh PATH >>>' not in (clean / '.zshrc').read_text()
    assert (config / 'btop.conf').exists()
    print('PASS: upgrade, uninstall, user configuration and later profile edits preserved')
    # Existing local commands require opt-in and are restored on uninstall.
    conflict = root / 'conflict home'
    conflict.mkdir()
    commands = conflict / '.local/bin'
    commands.mkdir(parents=True)
    original = conflict / 'original-btop'
    original.write_text('#!/bin/sh\necho original-btop\n')
    original.chmod(0o755)
    (commands / 'btop').symlink_to(original)
    conflict_env = environment(conflict)
    run(['sh', str(package / 'install.sh')], conflict_env, ok=False)
    assert not state(conflict).exists()
    run(['sh', str(package / 'install.sh'), '--take-over'], conflict_env)
    assert (state(conflict) / 'backups/btop').is_symlink()
    run(['sh', str(state(conflict) / 'uninstall.sh')], conflict_env)
    assert (commands / 'btop').is_symlink()
    assert run([str(commands / 'btop')], conflict_env).strip() == 'original-btop'
    print('PASS: conflict refusal, explicit takeover, original command/symlink restored')
    # Do not overwrite a replacement command installed after us.
    run(['sh', str(package / 'install.sh'), '--take-over'], conflict_env)
    (commands / 'btop').write_text('#!/bin/sh\necho replacement-btop\n')
    run(['sh', str(state(conflict) / 'uninstall.sh')], conflict_env)
    assert run([str(commands / 'btop')], conflict_env).strip() == 'replacement-btop'
    assert (state(conflict) / 'backups/btop').is_symlink()
    print('PASS: commands changed after installation are kept, along with original backups')
    # Tampering must fail before creating any installation state.
    damaged = root / 'damaged package'
    shutil.copytree(package, damaged)
    (damaged / 'README.md').write_text('modified payload')
    corrupt_home = root / 'corrupt home'
    corrupt_home.mkdir()
    run(['sh', str(damaged / 'install.sh')], environment(corrupt_home), ok=False)
    assert not state(corrupt_home).exists()
    print('PASS: damaged payload rejected before installation')
