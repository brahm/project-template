#!/usr/bin/env python3
"""Rebuilds what the kit derives from the skills of the template.

Usage: tools/build-kit.py [--check]

Each skill of project-template/.claude/skills is zipped into
desktop/claude-skills/NAME.zip, the form Claude desktop takes as an upload.
A zip whose skill no longer exists is removed. The zips are built the same
way every time (fixed dates, sorted entries), so a rebuild without a change
to a skill changes no file.

--check builds nothing: it fails when a zip is missing, stale or left
over, which is how tools/test-kit.sh and the CI notice that a skill was
edited without running this script.
"""
import io
import pathlib
import sys
import zipfile

KIT = pathlib.Path(__file__).resolve().parent.parent
SKILLS = KIT / 'project-template' / '.claude' / 'skills'
ZIPS = KIT / 'desktop' / 'claude-skills'
EPOCH = (1980, 1, 1, 0, 0, 0)       # the earliest date a zip can hold


def build(skill):
    """The bytes of the zip of one skill folder: the folder, then its files in order."""
    data = io.BytesIO()
    with zipfile.ZipFile(data, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        folder = zipfile.ZipInfo(skill.name + '/', EPOCH)
        folder.external_attr = (0o40755 << 16) | 0x10
        z.writestr(folder, b'')
        for path in sorted(p for p in skill.rglob('*') if p.is_file()):
            info = zipfile.ZipInfo(f'{skill.name}/{path.relative_to(skill).as_posix()}', EPOCH)
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, path.read_bytes(), compresslevel=9)
    return data.getvalue()


def main(argv):
    if argv not in ([], ['--check']):
        sys.exit(__doc__)
    check = bool(argv)
    wanted = {s.name + '.zip': build(s) for s in sorted(SKILLS.iterdir()) if (s / 'SKILL.md').is_file()}
    have = {p.name for p in ZIPS.glob('*.zip')}
    problems = []
    for name, data in wanted.items():
        path = ZIPS / name
        if not path.exists() or path.read_bytes() != data:
            if check:
                problems.append(f'desktop/claude-skills/{name} is {"stale" if path.exists() else "missing"}')
            else:
                path.write_bytes(data)
                print(f'wrote desktop/claude-skills/{name}')
    for name in sorted(have - set(wanted)):
        if check:
            problems.append(f'desktop/claude-skills/{name} has no skill any more')
        else:
            (ZIPS / name).unlink()
            print(f'removed desktop/claude-skills/{name}')
    if problems:
        print('\n'.join(problems), file=sys.stderr)
        sys.exit('Run tools/build-kit.py and commit what it writes.')
    print(f'{len(wanted)} skill zips are current')


if __name__ == '__main__':
    main(sys.argv[1:])
