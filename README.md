# MCBEPlay (local fork)

Server GUI and process wrapper for Minecraft Bedrock Dedicated Server on Windows.

This is a **local fork** of [foxynotail/MCBEPlay](https://github.com/foxynotail/MCBEPlay) (v3.5, GPL-3.0), not an official release. Credit: [FoxyNoTail](https://foxynotail.com). License: [GPL-3.0](LICENSE). Version: **3.5.4-local**. Repo: [ZanderCowboy/MCBEPlay](https://github.com/ZanderCowboy/MCBEPlay).

It is not a signed public app. Windows may warn on the committed `.exe` files (SmartScreen / “unknown publisher”). That is expected. Rebuild with `compile.ps1` if you want binaries produced on that PC.

This repo is **only** the AutoIt GUI (`mcbeplay`) and the hidden BDS helper (`bds`). It does not include Bedrock Dedicated Server, Discord bots, or scheduled tasks. Those live elsewhere (on this machine: `C:\MinecraftServer`).

## Why this fork exists

Stock 3.5 is incompatible with Bedrock Dedicated Server 1.26+:

- BDS logs `Profiler config ('bootstrap.json') load result: success=1, errorMessage=(null)` on a successful INFO load. Stock 3.5 matches the substring `ERROR` and kills the process.
- After a clean quit, `cmd /K` leaves a prompt such as `C:\MinecraftServer>`. Stock 3.5 treats any line containing `server_dir` as a crash and loops restarts.
- A trailing newline in `command.txt` plus `_BDSStdIn($command & @LF)` submits a blank second command. BDS logs that as `Unknown command: .` at ERROR level; 3.5.1-local treated any ERROR line as fatal and killed the GUI.

This fork only treats a BDS log level of `ERROR` as fatal (and ignores `Unknown command:`), trims `command.txt` before stdin, and only treats `CrashReporter` / `EXCEPTION` (non-INFO) as a crash.

**3.5.3-local** adds 10 / 5 / 1 minute in-game restart warnings from the GUI auto-restart timer (10-second windows so a skipped tick cannot miss the 5-minute message).

**3.5.4-local** waits up to 5 minutes for `Server started.` (including `Waiting for Minecraft services...`) and actually retries failed starts instead of logging success and exiting.

## How it works

Two processes must stay in the **same folder** as `options.txt`:

| File | Role |
|---|---|
| `mcbeplay.exe` (from `mcbeplay.au3`) | GUI. Starts/stops/restarts, timers, chat warnings. Launches `bds` by relative name, so the working directory must be that folder. |
| `bds.exe` (from `bds.au3`) | Hidden helper. Starts `bedrock_server.exe` via `cmd /K`, reads stdout, writes stdin from `tmp\command.txt`. |
| `options.txt` | Live config. Paths to BDS, worlds, saves, and logs. Read from `@ScriptDir` (the folder the running `.exe` / `.au3` is in). |

IPC files under `tmp\` (`command.txt`, `working.txt`, `members.txt`, …) are created at runtime. Logs and world backups go where `options.txt` points, not into this git repo.

```
mcbeplay.exe  --launches-->  bds.exe  --launches-->  bedrock_server.exe
     ^                         ^
     +---- options.txt --------+
     +---- tmp\ (IPC) ---------+
```

## Repo layout

```
mcbeplay.au3      GUI entry point
bds.au3           Hidden BDS helper entry point
mcbeplay.exe      Prebuilt GUI (clone-and-run)
bds.exe           Prebuilt helper (clone-and-run)
compile.ps1       Aut2Exe rebuild (no UPX, embeds icon.ico)
icon.ico
options.txt       Template only — placeholder paths, not a live install
inc\              Shared includes, globals, options parser, timers
func\             Start/stop/save/backup/restart and log helpers
gui\              Window, buttons, console, auto-restart UI
LICENSE           GPL-3.0
```

`.gitignore` excludes other `*.exe` files, `tmp\`, `logs\`, `saves\`, and `BDS\`. `mcbeplay.exe` and `bds.exe` are tracked so a clone can run without AutoIt.

## Set up on a new PC

Clone, copy the two committed `.exe` files plus a live `options.txt`, point that at BDS, run. AutoIt is only needed if you will change source.

### 1. Prerequisites

- Windows.
- A Bedrock Dedicated Server folder from Mojang (separate download). This repo does not vendor BDS.
- [AutoIt](https://www.autoitscript.com/site/autoit/downloads/) **3.3.16.x or newer** only if you will rebuild (this fork is built with **3.3.18.0**). The installer includes Aut2Exe, Au3Check, and SciTE. Default path: `C:\Program Files (x86)\AutoIt3\`.

### 2. Clone

```powershell
git clone https://github.com/ZanderCowboy/MCBEPlay.git
cd MCBEPlay
```

Put the clone anywhere you like. Source and the live install should be **different folders**.

### 3. Create a live folder and point `options.txt` at BDS

Pick a live directory (example: `C:\MCBEPlay`). Copy **this repo’s** `options.txt` into that folder **once**, then edit the live copy. Never copy it back over a running install.

Keys you must set to real paths on that PC:

| Key | Meaning |
|---|---|
| `server_title` | Window title suffix |
| `server_file` | Usually `bedrock_server.exe` |
| `server_dir` | Folder that contains `bedrock_server.exe` and `server.properties` |
| `world_dir` | Usually `server_dir\worlds` |
| `save_dir` | Where MCBEPlay writes world backups |
| `log_dir` | Where MCBEPlay writes `log.txt` and `sessions\` |

Leave `auto_save=false` and `rollback=false` until [BDS-2733](https://bugs.mojang.com/browse/BDS-2733) is fixed. If something else (Discord manager, Task Scheduler) restarts the stack, keep `keepalive=false` so a planned stop is not immediately undone.

The `options.txt` in git is a **template** with placeholder paths (`C:\MCBEPlay\BDS`, …). It is not the live config on this machine.

### 4. Copy the prebuilt binaries

From the clone, copy **only** `mcbeplay.exe` and `bds.exe` into the live folder. Do not overwrite live `options.txt`, `logs`, or `saves`.

### 5. Run

Start `mcbeplay.exe` **from the live folder** (working directory = that folder). The GUI then starts `bds.exe`, which starts BDS.

Confirm a session log under `log_dir\sessions\` gets past the profiler line to `Server started.`

## Develop

Edit the `.au3` files in the clone. Entry points:

- `mcbeplay.au3` — GUI
- `bds.au3` — helper (included into the same globals/options as the GUI)

Shared code is pulled in through `inc\init.au3` → `inc\functions.au3` / `gui\`.

### Syntax check

```powershell
& "${env:ProgramFiles(x86)}\AutoIt3\Au3Check.exe" -q .\mcbeplay.au3
& "${env:ProgramFiles(x86)}\AutoIt3\Au3Check.exe" -q .\bds.au3
```

Both should exit 0. Sources are kept Au3Check-clean (`#ignorefunc` / `#forcedef` where includes are split across files).

### Run uncompiled

1. Point a **local** `options.txt` in the clone at a test BDS (or temporarily copy the live one; do not commit it).
2. Set `Global $debug_mode = True` in `inc\globals.au3` so the GUI launches `bds.au3` via AutoIt instead of `bds.exe`.
3. Open `mcbeplay.au3` in SciTE (bundled with AutoIt) and press F5, or:

```powershell
& "${env:ProgramFiles(x86)}\AutoIt3\AutoIt3.exe" .\mcbeplay.au3
```

Working directory must be the folder that contains `mcbeplay.au3`, `bds.au3`, and `options.txt`. Set `$debug_mode` back to `False` before compiling a release.

### Rebuild

From the clone, with AutoIt installed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\compile.ps1
```

That rebuilds `mcbeplay.exe` and `bds.exe` **without UPX**, embedding `icon.ico` via Aut2Exe `/icon`. `bds.exe` stays a GUI-subsystem binary so it remains hidden like the original. `compile.ps1` looks for Aut2Exe in `Program Files (x86)` then `Program Files`.

### After a source change

1. Au3Check both entry points.
2. `compile.ps1`
3. Commit the new `mcbeplay.exe` and `bds.exe` with the source change so clones stay runnable.
4. Stop the live stack, copy the two new `.exe` files, start again.

Live binaries only update when you copy them.

### Version bump

Keep these in sync, then rebuild and commit the two `.exe` files:

- `mcbeplay.au3` header (`Version:Local`)
- `bds.au3` header (`Version:Local`)
- `inc\globals.au3` — `$MCBEPlay` (this is the GUI window title)
- `README.md`

## This machine

Example layout used in production here. Another PC can use any paths as long as live `options.txt` matches.

| Role | Path |
|---|---|
| Source (this repo) | `C:\Programming\Projects\MCBEPlay` |
| Live GUI / `bds.exe` | `C:\MCBEPlay` |
| Bedrock Dedicated Server | `C:\MinecraftServer` (`server_dir` / `world_dir` in the **live** `options.txt`) |
| Discord monitors | `C:\MinecraftServer\discord` (separate project; not required to build or run MCBEPlay) |

Discord webhooks are **not** part of this app. Do not copy this repo's `options.txt` over the live file.

## Deploy (this machine)

Copy **only** the two `.exe` files into `C:\MCBEPlay`. Never overwrite live `options.txt`, `logs`, or `saves`.

1. Stop the server (`C:\MinecraftServer\stop.bat`). Confirm `mcbeplay`, `bds`, and `bedrock_server` are gone.
2. Backup the current binaries if you want a rollback (`mcbeplay.exe.bak-<version>`, `bds.exe.bak-<version>`).
3. Copy the new `mcbeplay.exe` and `bds.exe` into `C:\MCBEPlay`.
4. Start with `C:\MinecraftServer\start.bat`.
5. Confirm a session log gets past the profiler line to `Server started.`

On another PC, replace those `.bat` files with whatever you use to stop/start the live folder.

## Known issues (upstream)

Bug [BDS-2733](https://bugs.mojang.com/browse/BDS-2733) can prevent copying two world files during a backup while the server is running. Keep auto-save off until that is resolved, or only back up after a clean stop.
