# Base PS4 (Fat / Slim) support

**Status: never tested on a base PS4.** The port was built and measured only on a PS4 Pro, firmware
12.02, GoldHEN. Nothing below has been run on a console; it is what the code and the earlier
measurements suggest, plus a diagnostic so the first base-PS4 test produces facts instead of guesses.

## What probably carries over

- **Memory (likely the same).** The package layout that the earlier tests found gets about 4.4 GiB of
  direct memory on the Pro. That figure matches what a base PS4's game budget is, which suggests the
  Pro was handing this app the base-mode budget, not its extra memory. This is an inference, not a
  measurement: the first base-PS4 `boot.log` will show the real number.
- **GPU (same family).** The driver is Mesa RADV for "Liverpool" (GFX7), the base PS4's GPU; the Pro's
  GPU is a bigger relative of it.
- **CPU (slower).** The Pro ran this app at about 2.1 GHz; a base PS4 runs 1.6 GHz. `STATUS.md`
  projected a quarter slower again, i.e. MK8D races around 10-12 fps at best. Lighter games are the
  realistic target.
- **Cores.** A base PS4 gives games fewer CPU cores than a Pro (the profile showed 3-4 busy). Eden's
  thread count is chosen from what the system reports; the log line below shows it.

## What changed in the frontend (no Eden patch needed)

1. `boot.log` now has one line near the top, written before anything else is set up:

   ```
   hardware: <console model>; direct memory N MiB total, N MiB free at start; N hardware threads; cpu loop (100M steps) N ms
   ```

   The model is only reported if the system call is available in the SDK; otherwise it says so.
   The CPU loop is a fixed amount of integer work: compare the milliseconds between consoles (lower
   is faster), do not read it as a clock speed.

2. **GPU arena sized from the memory actually free.** It stays at 1280 MiB (what the Pro needs for
   MK8D races) when the free direct memory at start is within 200 MiB of the Pro's ~4400 MiB. If a
   console reports clearly less, the difference comes off the arena, never below 768 MiB, and a line
   in `boot.log` says so. `settings.txt` with `env=ORBIS_ARENA_MIB=<n>` overrides it either way.

   A smaller arena helps the app start and run menus; it will not make an MK8D race fit. Races
   already ran the Pro's memory down to ~100 MiB.

## What a base-PS4 tester should send

- `/data/edenps4/boot.log` (the `hardware:` line is the first thing in it) and `boot.old.log`
- `/data/edenps4/mesa.log` and `/data/edenps4/log/eden_log.txt`
- the console model (CUH-1xxx Fat, CUH-2xxx Slim), firmware version, GoldHEN version
- how far it got: menus, a game's title screen, in-game, and the fps the `status:` lines report

## Things this does not address

- GoldHEN support for each firmware is outside this project.
- Firmware 13.52 (and any firmware other than 12.02) is untested either way.
- Performance. A slower CPU is slower; the fastmem work in `STATUS.md` is the main speed lever and is
  still unresolved.
