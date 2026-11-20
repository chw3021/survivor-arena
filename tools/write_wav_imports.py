#!/usr/bin/env python3
"""Write Godot WAV .import stubs (PCM, BGM loop)."""
from __future__ import annotations

import hashlib
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main() -> None:
    assets = os.path.join(ROOT, "assets")
    for dirpath, _, names in os.walk(assets):
        for name in names:
            if not name.endswith(".wav"):
                continue
            path = os.path.join(dirpath, name)
            rel = os.path.relpath(path, ROOT).replace("\\", "/")
            source = "res://" + rel
            h = hashlib.md5(source.encode()).hexdigest()
            uid = "uid://b" + h[:15]
            dest = f"res://.godot/imported/{name}-{h}.sample"
            loop = 1 if "/bgm/" in source else 0
            text = (
                "[remap]\n\n"
                'importer="wav"\n'
                'type="AudioStreamWAV"\n'
                f'uid="{uid}"\n'
                f'path="{dest}"\n\n'
                "[deps]\n\n"
                f'source_file="{source}"\n'
                f'dest_files=["{dest}"]\n\n'
                "[params]\n\n"
                "force/8_bit=false\n"
                "force/mono=false\n"
                "force/max_rate=false\n"
                "force/max_rate_hz=44100\n"
                "edit/trim=false\n"
                "edit/normalize=false\n"
                f"edit/loop_mode={loop}\n"
                "edit/loop_begin=0\n"
                "edit/loop_end=-1\n"
                "compress/mode=0\n"
            )
            out = path + ".import"
            with open(out, "w", encoding="utf-8", newline="\n") as f:
                f.write(text)
            print("wrote", out, "loop", loop)


if __name__ == "__main__":
    main()
