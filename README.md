# Orbis Eden

> Formerly **NX on Orbis** (by Alejo). Continued by Mr.Kitsune9, @blorbus0866, @titotostito_, @loony_user and Claude.

An experimental port of the **Eden** Nintendo Switch emulator (a yuzu fork) to a jailbroken
**PS4 Pro** (OpenOrbis toolchain, Mesa RADV Vulkan driver for the PS4 GPU).

> **Status: experimental, being continued.** It boots, runs real games, and Mario Kart 8 Deluxe
> plays, but some colors are still wrong, loading is slow and closing the app from the PS menu can
> crash it. It is not yet a practical way to play Switch games on a PS4. Read
> [docs/STATUS.md](docs/STATUS.md) for the original goals, results and the projected performance ceiling.

| | |
|---|---|
| Console | PS4 Pro, GoldHEN; firmware 12.02 (v0.1.0) and 13.52 (continuation). The only consoles it was tested on |
| Base | Eden `5f142c79` (the commit the PS5 port ProsperoEden pins) + patches `0001`-`0046` in `patches/eden/` |
| Toolchain | OpenOrbis 0.5.4 + [orbis-sdk-v1](https://github.com/orbis-ports/orbis-porting-kit/releases/tag/orbis-sdk-v1) (orbis-compat, Mesa RADV for "Liverpool" GFX7), LLVM 18, libc++ 18 built for the PS4 |
| Release | see the [releases page](../../releases): `.pkg` (v1.01 and later) and v0.1.0 with the exact ELF (for symbolizing crash logs) |
| License | GPL-3.0-or-later (see `LICENSE` and `NOTICE.md`) |

## Not affiliated with Eden. Built with AI.

- This project is **not affiliated with, endorsed by, or supported by the Eden project** or its
  developers. **Do not report problems from this port to Eden** (issues, Discord or anywhere else).
- It was written with heavy use of AI assistants (Anthropic's Claude, and OpenAI's Codex for a
  couple of test rounds), directed and tested on the console by the author. The Eden project
  prohibits AI-generated contributions; that is why this lives here, separately, and nothing from
  it has been or will be submitted upstream.
- No keys, firmware, games or Sony system files are included. You need to dump keys and firmware
  from your own Switch (Lockpick_RCM, TegraExplorer / NXDumpTool) and your own games.

## What is new in v1.01

- New name, icon (by @titotostito_) and game menu.
- **Language wheel** in the menu: English, Portuguese and Spanish (Triangle changes it; the choice is
  saved in `/data/edenps4/lang.txt`).
- **External drive support**: games on a USB drive are listed next to the internal ones (the menu
  shows `INT` or `USBn`). It looks in `/mnt/usb0` to `/mnt/usb7`, in the root and in the folders
  `roms`, `games`, `switch` and `nsp`. *Not yet confirmed on a console.* The log line `/mnt holds:`
  in `boot.log` shows what the console exposes.
- `settings.txt` gained `cpu_accuracy=auto|accurate|unsafe`; the sampling profiler is now off
  unless `profile=on` is set.

## What works (v0.1.0, measured on the console)

- Boots with its own game picker (Up/Down + Cross) over the PS4 video output; DualShock 4 input;
  audio through `sceAudioOut` (clean, no crackle).
- **Mario Kart 8 Deluxe**: title screen and menus at 40-60 fps; races load and play (two-lap
  sessions, ~15 minutes without crashing) at **13-16 fps**, with stutters while new shaders compile.
- Cuphead reaches its menu at ~30 fps. The bundled Homebrew Menu (nx-hbmenu) runs without keys.

## What does not

- **Colors**: some are still wrong in Mario Kart 8 Deluxe (character heads, item icons, parts of
  videos and the pause screen). The released `settings.txt` is the best configuration found so far.
  Every driver-side cause tested so far was ruled out; see `docs/TECHNICAL.md`.
- **Loading**: Mario Kart 8 Deluxe takes about a minute from the menu until it plays smoothly
  (most of it is the first translation of the game's code, on a single thread).
- **Closing**: closing the app from the PS menu can crash and take a long time.
- **Speed**: the emulated CPU is the bottleneck (the GPU is never waited on). See
  `docs/STATUS.md` for the profile and the projected ceiling.
- **Memory**: a race uses ~4.5 GiB of the ~4.6 GiB of direct memory the PS4 gives the process.
  Occasional hangs or crashes when a race loads are likely memory exhaustion.

## Roadmap

- Colors: find the real cause (the PS4 Mesa build is the main suspect).
- Faster loading and better speed.
- **Nintendo Switch 2**: a goal for the future, *not supported now*. The Eden base used here has no
  Switch 2 code, and the games need far more memory than the PS4 offers. The Lichii project
  (zortos293) is an experimental emulator with Switch 2 work and is a useful reference. No Lichii
  code is included.

## Documentation

- [docs/STATUS.md](docs/STATUS.md): goals and expectations, results test by test, profiling,
  projected maximum performance, and where to continue.
- [docs/INSTALL.md](docs/INSTALL.md): installing the release and laying out your own files.
- [docs/BUILDING.md](docs/BUILDING.md): rebuilding everything from source (Windows + Git Bash).
- [docs/TECHNICAL.md](docs/TECHNICAL.md): platform findings (several are useful to any PS4
  homebrew port: the SDK's 16-bit `wmemchr`, the package layout that grants 4.4 GiB, the GPU
  driver's memory behaviour, fault handling, address-space limits).
- [docs/dev-log-es.md](docs/dev-log-es.md): the full development log in Spanish, test by test.

## Branches

- `main`: v0.1.0, the last build that reached races reliably (internally "test 24").
- `experimental-fastmem`: tests 25-29. Fastmem works (an 8 GiB view of guest memory aliasing the
  backing, JIT faults redirected to dynarmic's slow path), plus a direct-memory map in the log,
  the environment moved out of the heap after a heap-corruption crash, and a smaller GPU arena.
  It never got back into a race: loading one runs direct memory out. Notes in `docs/STATUS.md`.

## Credits

Eden and yuzu developers (the emulator), ProsperoEden (the PS5 port this started from, and the Eden
commit it pins), the orbis-ports project (orbis-compat and the PS4 Mesa RADV driver), OpenOrbis
(toolchain), switchbrew (nx-hbmenu), DejaVu fonts. Port by Alejo ([@alechurri](https://github.com/alechurri)).

### Continuation (after v0.1.0)

Picked up from the abandoned project by **Mr.Kitsune9**. Beta testers: **@blorbus0866** and
**@titotostito_** (who also made the Orbis Eden icon). **@loony_user** helped with testing and
with creating the community server. **xatyy** made Eden4, an independent Eden port for PS4 that
serves as a reference for ideas (menu, game sources, start-up speed); no Eden4 code is included.
The **Lichii** project by zortos293 is a reference for Switch 2 research; no Lichii code is included. Target console: PS4 Pro (firmware 13.52). The color experiment
(patch 0028, `a2b10=sample|write` in `settings.txt`), the stability patch (0029) and the Linux
build scripts in `ci/` were written with **Claude** (Anthropic), directed by Mr.Kitsune9. As
with v0.1.0, these changes are experimental and are not affiliated with the Eden project.
Status of this continuation: untested on a console until someone reports results.
