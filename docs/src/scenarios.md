# Scenarios and Workflows

## Terminal Emulator Choice

WezTerm is the recommended terminal emulator for `MuxDisplay` workflows. It supports both iTerm2 and Sixel protocols, includes a built-in `wezterm imgcat` command, and offers native multiplexing capabilities. The GPU acceleration provides good performance, and it works consistently across platforms. The iTerm2 project is a mature emulator on macOS with native image protocol, including its own `imgcat` utilities. Kitty provides advanced graphics capabilities with its own protocol and good performance, but requires more setup for multiplexer compatibility. It works well on Linux and macOS. Blink Shell enables mobile workflows on iOS/iPadOS but has placement issues in multiplexed environments. It works best with dedicated tmux sessions rather than split panes.

## Multiplexer Choice

Tmux is the standard choice for persistent remote sessions and cross-platform consistency. It supports OSC passthrough (≥3.3) for image protocols but images disappear when scrolling or switching windows. Use `redraw_previous` to show multiple images for comparison.

WezTerm multiplexing provides better image persistence with scrollback but requires matching versions on local and remote systems. It's simpler when you don't need the session management features of tmux.

Combining both multiplexers offers the best of both worlds: tmux for session management and WezTerm panes for image display with proper scrollback.

## Image Display Programs

`wezterm imgcat` is the preferred choice when available. It handles tmux passthrough correctly and works consistently across different terminal emulators using the iTerm2 protocol.

iTerm's `imgcat` script works well in many situations, particularly in Blink Shell, but may have placement issues depending on the terminal emulator and multiplexer combination.

`kitty icat` works within the Kitty terminal and can handle scrollback properly, but only functions correctly in the actual Kitty terminal environment.

## Scenario 1: Local Development with WezTerm

For local development, use WezTerm without any multiplexer for the simplest setup. `MuxDisplay` is simply pointed to a local WezTerm pane to use as a canvas, via `MuxDisplay.enable(multiplexer=:wezterm, target_pane=pane_id)` where `pane_id` comes from the `WEZTERM_PANE` environment variable.

## Scenario 2: Remote Development with tmux Display Pane

For traditional remote development workflows, create a tmux layout with your editor on the left, REPL on the right, and a display pane above the REPL. Use `MuxDisplay.enable(target_pane="1")` targeting the display pane by index.

This setup works well when image placement is reliable, but images disappear when scrolling. Consider using `redraw_previous=2` to show multiple plots for comparison.

## Scenario 3: Remote Development with tmux Display Session

Create a separate tmux session dedicated to image display (e.g., `tmux new-session -s Plots`). Use `MuxDisplay.enable(target_pane="Plots:0.0")` to target this session.

This approach avoids most placement issues and provides better isolation. It works particularly well when viewing the plots session in a separate terminal window.

## Scenario 4: Hybrid tmux + WezTerm Setup

Use tmux for your main development session and a separate WezTerm window for image display. Create a WezTerm SSH domain connection to the remote host and use `MuxDisplay.enable(multiplexer=:wezterm, target_pane=pane_id)`.

This configuration provides the session management benefits of tmux with the superior image handling of WezTerm, including proper scrollback and persistence.

## Scenario 5: Mobile Development with Blink Shell

On iOS/iPadOS with Blink Shell, use a dedicated tmux session for plots similar to Scenario 3. Open the main tmux session in one Blink window and create `tmux new-session -s Plots` in a slide-over window.

Configure with `MuxDisplay.enable(target_pane="Plots:0.0", nrows=3, clear=false)` for the narrow slide-over format, or `nrows=2` for split-view. The `clear=false` option exploits Blink's somewhat "buggy" behavior to create a scrolling effect.
