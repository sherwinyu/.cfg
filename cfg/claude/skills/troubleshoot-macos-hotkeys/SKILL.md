---
name: troubleshoot-macos-hotkeys
description: Diagnose and repair macOS keyboard shortcuts, remappings, and app-launch hotkeys across physical keyboards, macOS HID delivery, Karabiner-Elements, virtual HID devices, Hammerspoon, and target applications. Use when a hotkey or keyboard layer stops working; Caps Lock, Hyper, Meh, or Zoot remaps fail; Karabiner or Hammerspoon may be unhealthy; a shortcut works with literal modifiers but not a remapped key; or keyboard automation breaks after sleep, wake, login, upgrade, or permission changes.
---

# Troubleshoot macOS Hotkeys

Treat a hotkey as an event pipeline, not as one feature:

```text
physical keys
  → macOS HID/input subsystem
  → remapper (Karabiner)
  → virtual key or modifier chord
  → consumer (Hammerspoon or the target app)
  → action
```

Diagnose the pipeline by testing boundaries. Do not start by restarting everything.

## Core Rules

- Distinguish source configuration, deployed configuration, process liveness, service health, and end behavior.
- Treat “process exists” as a weak signal. A process can accept a connection yet fail every request.
- Prefer a boundary probe that bypasses half the pipeline. It gives more information than inspecting another config file.
- Inspect an action before injecting its hotkey. Do not trigger destructive, security-sensitive, or externally visible actions merely as a diagnostic.
- Escalate recovery from the narrowest failed component to the privileged service that owns the state.
- Separate the proven proximate cause from hypotheses about why the service entered that state.
- Preserve user changes and avoid editing configuration until evidence shows the configuration is wrong.

## Diagnostic Workflow

### 1. Define the expected event

Identify:

- The physical key sequence.
- The chord the remapper should emit.
- The process that consumes the chord.
- The action the consumer should run.

Search the actual config instead of guessing names:

```bash
rg -n -i 'hotkey|hyper|zoot|caps_lock|calendar' <karabiner-config> <hammerspoon-config>
```

Verify that both sides agree on the exact modifier set and key. For example, `Zoot` might mean `Ctrl+Option+Cmd`, while `Hyper` might also include `Shift`.

### 2. Verify deployed state

Confirm that the running tools can see the intended config:

- Resolve Hammerspoon config symlinks.
- Inspect the selected Karabiner profile, not only the TypeScript or source generator.
- Inspect the generated `~/.config/karabiner/karabiner.json` rule.
- Confirm device conditions include the keyboard currently in use.

Useful commands:

```bash
readlink ~/.hammerspoon
jq -r '.profiles[] | [.name, (.selected // false)] | @tsv' \
  ~/.config/karabiner/karabiner.json

'/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli' \
  --show-current-profile-name
```

A correct source file does not prove that it was generated, selected, or loaded.

### 3. Map the live process topology

Inspect the live components:

```bash
pgrep -ifl 'Hammerspoon|Karabiner'
launchctl print gui/$(id -u) | rg -i -C 2 'karabiner|hammerspoon'
launchctl print system | rg -i -C 2 'karabiner|pqrs'
```

Expect Karabiner to span multiple privilege and process boundaries:

- A root core daemon that grabs physical devices.
- A user core-service agent.
- A console-user server.
- A virtual HID driver/service that emits replacement events.

Check the installed Karabiner version before reasoning from process names. Recent releases renamed or removed legacy processes such as `karabiner_grabber` and `karabiner_session_monitor`; absence alone is not a failure.

### 4. Split the pipeline with a boundary probe

Bypass Karabiner and send the final chord directly when its action is safe. For `Ctrl+Option+Cmd+C`:

```bash
osascript -e \
  'tell application "System Events" to key code 8 using {control down, option down, command down}'
```

Interpret the result:

- Direct chord works: the consumer and action work. Investigate physical input, Karabiner, the active profile, device conditions, and the virtual-HID path.
- Direct chord fails: investigate Hammerspoon, whether the hotkey is loaded, conflicts, permissions, and the target action.

This probe is the highest-value test in the workflow. It is binary search across the event pipeline.

### 5. Test service health, not just liveness

Exercise a real Karabiner request:

```bash
'/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli' \
  --list-connected-devices
```

Allow only a few seconds. Cancel it and clean up the stuck process if it hangs. A hung device query indicates a runtime or IPC problem even when every Karabiner process appears in `pgrep`.

Inspect current logs:

```bash
tail -n 120 ~/.local/share/karabiner/log/console_user_server.log
tail -n 120 ~/.local/share/karabiner/log/core_service.log
tail -n 160 /var/log/karabiner/core_service.log
tail -n 120 /var/log/karabiner/virtual_hid_device_service.log
```

Healthy startup evidence includes:

- `device_grabber is started`
- `Load .../karabiner.json`
- `core_configuration is updated`
- `virtual_hid_keyboard_ready_response: true`
- The physical keyboard monitor is `started (grabbed)`
- The virtual keyboard monitor is `started (observed)`

Strong failure evidence includes a repeating cycle such as:

```text
connected
Operation timed out
Connection reset by peer
closed
connected
```

The repetition matters more than one stale log line around startup, sleep, or shutdown.

For Hammerspoon, use `hs -c` only if its IPC module is loaded. An inaccessible Hammerspoon message port does not prove Hammerspoon is unhealthy; IPC is optional. Prefer the boundary probe or Hammerspoon Console when IPC is unavailable.

## Recovery Ladder

Apply recovery only after identifying the failed side.

### 1. Restart the Karabiner user server

Use Karabiner's supported user-level restart first:

```bash
launchctl kickstart -k \
  gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server
```

Recheck logs after waiting longer than the observed failure interval. If the same timeout loop immediately returns, the server below the restarted client is still unhealthy.

### 2. Restart the current user core agent when present

Discover the label with `launchctl`; do not assume it exists on every version. A known label in Karabiner 16.1 is:

```bash
launchctl kickstart -k \
  gui/$(id -u)/org.pqrs.service.agent.Karabiner-Core-Service-rev2
```

Restart the console-user server again afterward. If both reconnect to the same timeout loop, escalate to the root daemon.

### 3. Restart the privileged core daemon

Identify the exact system label first. A known label is:

```text
system/org.pqrs.service.daemon.Karabiner-Core-Service
```

This action requires administrator authorization. Never request, record, or pipe the user's password. Use the macOS authorization dialog and explain why approval is needed:

```bash
osascript -e \
  'do shell script "launchctl kickstart -k system/org.pqrs.service.daemon.Karabiner-Core-Service" with administrator privileges with prompt "Restart Karabiner Core Service to restore keyboard remappings"'
```

Honor project notification instructions before waiting for approval. If approval is denied, stop and report the exact command the user can run.

### 4. Check permissions or reboot only if restart fails

For current Karabiner releases, inspect:

- Accessibility permission for `Karabiner-Core-Service`.
- Input Monitoring permission.
- Privileged and non-privileged App Background Activity entries.
- The Karabiner virtual HID driver extension.
- Full Disk Access only when the configuration lives in a protected or unusual location.

Prefer the Karabiner Settings setup view and official troubleshooting guidance. Treat a reboot as a broader recovery step, not the first diagnostic.

## Verify the Repair

Do not declare success after a command merely exits zero. Verify the full story:

1. Confirm the root core-service PID or start time changed.
2. Confirm fresh daemon logs show config load, device grabber start, and virtual keyboard readiness.
3. Wait longer than the former timeout cycle and confirm it does not recur.
4. Confirm `karabiner_cli --list-connected-devices` returns promptly.
5. Confirm the intended Karabiner profile remains selected.
6. Ask for or perform a safe physical-key test to prove the remapped path, not just the literal chord.

If the direct chord works but the physical remap still fails while the CLI is healthy, focus on:

- Selected profile.
- Device-specific `device_if` or `device_unless` conditions.
- Whether the current keyboard is listed and grabbed.
- Simple and complex modification conflicts.
- Modifier state stuck after sleep/wake.

## Report Findings

Lead with the failing layer and the evidence that isolated it. Include:

- Expected pipeline.
- Boundary probe result.
- Health-check result.
- Recovery performed.
- End-to-end verification performed.
- Whether any configuration changed.

State deeper causes conservatively. For example:

> Proven: the privileged Karabiner daemon stopped servicing IPC requests, so it no longer produced the chord Hammerspoon needed.
>
> Possible trigger: nearby sleep/wake and virtual-HID reconnect activity. The available evidence does not prove why the daemon wedged.

## Quick Decision Guide

```text
Physical remap fails
  ├─ Literal final chord works
  │    └─ Investigate Karabiner and everything upstream
  │         ├─ CLI hangs → runtime/IPC/daemon health
  │         └─ CLI responds → profile/device/rule conditions
  └─ Literal final chord fails
       └─ Investigate Hammerspoon, hotkey conflicts, permissions, and action
```
