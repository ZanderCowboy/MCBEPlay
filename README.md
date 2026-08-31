# MCBEPlay (local fork)

Server GUI and management for Minecraft Bedrock Dedicated Server on Windows.

This is a **local fork** of [foxynotail/MCBEPlay](https://github.com/foxynotail/MCBEPlay) (v3.5, GPL-3.0), not an official release. Credit: [FoxyNoTail](https://foxynotail.com). Version: **3.5.4-local**.

Stock 3.5 is incompatible with Bedrock Dedicated Server 1.26+:

- BDS logs `Profiler config ('bootstrap.json') load result: success=1, errorMessage=(null)` on a successful INFO load. Stock 3.5 matches the substring `ERROR` and kills the process.
- After a clean quit, `cmd /K` leaves a prompt such as `C:\MinecraftServer>`. Stock 3.5 treats any line containing `server_dir` as a crash and loops restarts.
- A trailing newline in `command.txt` plus `_BDSStdIn($command & @LF)` submits a blank second command. BDS logs that as `Unknown command: .` at ERROR level; 3.5.1-local treated any ERROR line as fatal and killed the GUI.

This fork only treats a BDS log level of `ERROR` as fatal (and ignores `Unknown command:`), trims `command.txt` before stdin, and only treats `CrashReporter` / `EXCEPTION` (non-INFO) as a crash.

**3.5.3-local** adds 10 / 5 / 1 minute in-game restart warnings from the GUI auto-restart timer (10-second windows so a skipped tick cannot miss the 5-minute message).

**3.5.4-local** waits up to 5 minutes for `Server started.` (including `Waiting for Minecraft services...`) and actually retries failed starts instead of logging success and exiting.

It is not a signed public app. Windows may still warn if the `.exe` is copied from the internet. Building locally is the trust model.

## This machine

| Role | Path |
|---|---|
| Source (this repo) | `C:\Programming\Projects\MCBEPlay` |
| Live GUI / `bds.exe` | `C:\MCBEPlay` |
| Bedrock Dedicated Server | `C:\MinecraftServer` (`server_dir` / `world_dir` in the **live** `options.txt`) |
| Discord monitors | `C:\MinecraftServer\discord` |

Discord webhooks are **not** part of this app. Do not copy this repo's `options.txt` over the live file.

Required files in the live directory (must stay together):

- `mcbeplay.exe` — GUI
- `bds.exe` — hidden process that talks to BDS
- `options.txt` — live config

## Compile

Install [AutoIt](https://www.autoitscript.com/site/autoit/downloads/) (3.3.16.x is fine) so Aut2Exe is available. Then from this folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\compile.ps1
```

That builds `mcbeplay.exe` and `bds.exe` **without UPX**, embedding `icon.ico` via Aut2Exe `/icon`. `bds.exe` stays a GUI-subsystem binary so it remains hidden like the original.

## Deploy

Copy **only** the two `.exe` files into `C:\MCBEPlay`. Never overwrite live `options.txt`, `logs`, or `saves`.

1. Stop the server (`C:\MinecraftServer\stop.bat`). Confirm `mcbeplay`, `bds`, and `bedrock_server` are gone.
2. Backup the current binaries (`mcbeplay.exe.bak-3.5`, `bds.exe.bak-3.5`).
3. Copy the new `mcbeplay.exe` and `bds.exe` into `C:\MCBEPlay`.
4. Start with `C:\MinecraftServer\start.bat`.
5. Confirm a session log gets past the profiler line to `Server started.`

## Known issues (upstream)

Bug [BDS-2733](https://bugs.mojang.com/browse/BDS-2733) can prevent copying two world files during a backup while the server is running. Keep auto-save off until that is resolved, or only back up after a clean stop.
