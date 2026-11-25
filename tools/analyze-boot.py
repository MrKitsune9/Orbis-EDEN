#!/usr/bin/env python3
"""Summarises an Orbis Eden boot.log: phases, load times, fps over time, per-thread CPU use.

Usage:  python tools/analyze-boot.py boot.log
Read-only; it only prints. Works with logs from v0.1.x and v1.01.
"""
import re
import sys


def main(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    rx = re.compile(r"^\[\s*([\d.]+)\]\s?(.*)$")
    events = []
    for ln in lines:
        m = rx.match(ln)
        if m:
            events.append((float(m.group(1)), m.group(2)))
    if not events:
        print("no timestamped lines found")
        return

    print(f"{path}: {len(events)} lines, {events[0][0]:.1f}s .. {events[-1][0]:.1f}s\n")
    for t, text in events:
        if text.startswith("eden-ps4 starting") or text.startswith("PS4 build:") or text.startswith("hardware:"):
            print(f"[{t:7.1f}] {text[:150]}")

    print("\nPhases:")
    chosen = None
    for t, text in events:
        if text.startswith("== "):
            print(f"  {t:7.1f}s  {text}")
        if text.startswith("menu: game") and "chosen" in text:
            chosen = t
            print(f"  {t:7.1f}s  game chosen in the menu")
        if text.startswith("load timer:"):
            print(f"  {t:7.1f}s  {text}")
        if text.startswith("!! no new frame"):
            print(f"  {t:7.1f}s  {text}")
    if chosen is None:
        chosen = next((t for t, x in events if x.startswith("game ") and " of " in x), events[0][0])

    print("\nGame speed over time (seconds since the game was chosen):")
    first = fps30 = None
    for t, text in events:
        m = re.match(r"status: game ([\d.]+) fps, speed (\d+)%, frame ([-\w.]+) ms.*?(\d+) MiB direct free", text)
        if m:
            fps = float(m.group(1))
            print(f"  {t - chosen:7.1f}s  {fps:5.1f} fps  speed {m.group(2)}%  free {m.group(4)} MiB")
            if first is None and fps > 0.5:
                first = t - chosen
            if fps30 is None and fps >= 30:
                fps30 = t - chosen
    print(f"\nFirst frames: {'%.0f s' % first if first is not None else 'never'}; "
          f"30 fps or more: {'%.0f s' % fps30 if fps30 is not None else 'never'} (status lines are 5-10 s apart)")

    prof = {}
    for t, text in events:
        m = re.match(r"profile \[(.+?)\]: (\d+) samples, busy (\d+)% \(jit (\d+)% of busy\), waiting (\d+)%", text)
        if m:
            prof.setdefault(m.group(1), []).append((t, int(m.group(3)), int(m.group(4)), int(m.group(5))))
    if prof:
        print("\nProfiler (busy %, jit % of busy, waiting %) per sample window:")
        for name, rows in prof.items():
            print(f"  {name:<14}" + "  ".join(f"{b}/{j}/{w}" for _, b, j, w in rows))

    bad = [(t, x) for t, x in events if x.startswith("!!") or re.search(r"fatal|unhandled|terminate called|SIGSEGV at|crash report", x, re.I)]
    if bad:
        print(f"\nWarnings and crashes ({len(bad)}):")
        for t, x in bad[:12]:
            print(f"  {t:7.1f}s  {x[:140]}")
    mnt = next((x for _, x in events if x.startswith("/mnt holds")), None)
    if mnt:
        print("\n" + mnt)
    for _, x in events:
        if x.startswith("USB") or x.startswith("save backup") or x.startswith("per-game settings"):
            print(x)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1])
