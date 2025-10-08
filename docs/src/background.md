# Background

Terminal image display involves three conceptual layers that work together to render graphics in text-based environments:

1. **Terminal Emulator**: The application that renders text and graphics (iTerm2, WezTerm, Kitty, Blink Shell). This layer implements image protocols and handles the actual display of visual content.

2. **Multiplexer**: Optional session management layer (tmux, WezTerm multiplexing) that enables persistent sessions with multiple windows and panes. This layer must support protocol passthrough and pane targeting for image display.

3. **Display Program**: The application generating image output; typically image viewers like `imgcat`, `icat`. This layer creates the image data and sends it through the appropriate protocol.

`MuxDisplay` operates by coordinating these layers: it hooks into Julia's display system, uses multiplexer panes as a canvas, and relies on external `imgcat` programs to communicate with the terminal emulator (layer 3).


## Image protocols

Modern terminal emulators have evolved beyond simple text display to support high-resolution graphics through specialized protocols. These protocols enable applications to embed images, plots, and other visual content directly within terminal sessions.

### iTerm2 Inline Images Protocol

The [iTerm2 inline images protocol](https://iterm2.com/documentation-images.html) was one of the first widely adopted terminal graphics standards. It uses OSC (Operating System Command) escape sequences to transmit base64-encoded image data. It can work over SSH connections with the proper passthrough, and has positioning and sizing controls.

Originally developed for iTerm2 on macOS, this protocol is now supported by [WezTerm](https://wezterm.org/imgcat.html), [Blink Shell](https://docs.blink.sh/basics/tips-and-tricks#inline-images), and other terminal emulators.

### Kitty Graphics Protocol

The [Kitty graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/) offers more advanced features than the iTerm2 protocol, including pixel-perfect positioning, alpha blending, and animation support. It provides better performance for complex graphics operations and fine-grained control over image placement.

The protocol is primarily supported by Kitty terminal, with growing adoption in other emulators like [Ghostty](https://ghostty.org/docs/features). `MuxDisplay` can use Kitty's `icat` command.

### Sixel Protocol

[Sixel](https://en.wikipedia.org/wiki/Sixel) is a standardized bitmap graphics format originally developed by DEC in 1987 that has seen renewed adoption in modern terminal emulators. It's efficient for simple bitmap graphics and relatively simple to implement.

See [Are We Sixel Yet?](https://www.arewesixelyet.com/) for the current support status in various terminal emulators, including xterm, WezTerm, VS Code, and tmux (if compiled with `--enable-sixel`). While less feature-rich than modern protocols, Sixel's standardized nature makes it a reliable fallback option. `MuxDisplay` can utilize `img2sixel` or similar tools when Sixel is the preferred protocol.

## Terminals

### WezTerm

[WezTerm](https://wezterm.org/) is a GPU-accelerated, cross-platform terminal emulator that supports both iTerm2 and Sixel protocols. It includes a built-in `wezterm imgcat` command and offers native multiplexing capabilities with SSH domains and workspaces.

`MuxDisplay` works well with WezTerm both as a terminal emulator and as a multiplexer, though image protocols aren't fully handled by multiplexer sessions.

### iTerm2

[iTerm2](https://iterm2.com/) is _the_ traditional third-party macOS terminal emulator and originator of the inline images protocol. It natively supports its own protocol with comprehensive format support. `MuxDisplay` works well with iTerm2, utilizing the included `imgcat` utility. The terminal provides excellent integration with macOS and comprehensive shell utilities. macOS only.

### Kitty

[Kitty](https://sw.kovidgoyal.net/kitty/) is a GPU-based terminal emulator with its own advanced graphics protocol supporting pixel-perfect positioning, alpha blending, and sophisticated animation capabilities. It also supports Sixel. `MuxDisplay` can use Kitty's `icat` command when available. The terminal offers high performance and works on Linux, macOS, and some BSD distributions.

### Blink Shell (iOS)

[Blink Shell](https://blink.sh/) is a professional terminal for iOS/iPadOS that supports the iTerm2 image protocol over SSH connections. It works with `imgcat` utilities but has limitations: image display only works over SSH (not Mosh) and display within terminal multiplexers is less reliable. `MuxDisplay` can work with Blink Shell in specific configurations, particularly when using dedicated tmux sessions for image display.


## Multiplexers

Terminal multiplexers enable persistent sessions with multiple windows and panes. For `MuxDisplay`, multiplexers must support targeted pane commands and passthrough capabilities for graphics protocols. Currently `tmux` and `WezTerm` are supported.

### Tmux

[Tmux](https://github.com/tmux/tmux/wiki) is the de facto standard terminal multiplexer. For image display, tmux 3.3+ supports OSC passthrough with `set -gq allow-passthrough on`, and tmux 3.4+ supports Sixel with `--enable-sixel`.

`MuxDisplay` uses tmux's comprehensive pane addressing (`session:window.pane`) and command injection capabilities. Tmux can still have issues with image placement in certain configurations, and images disappearing when scrolling.

### WezTerm Multiplexing

[WezTerm](https://wezterm.org/multiplexing.html) provides native multiplexing with built-in iTerm2 and Sixel protocol support. It offers SSH domains for remote multiplexing and uses the `WEZTERM_PANE` environment variable for pane identification. `MuxDisplay` benefits from WezTerm's integrated approach - no passthrough complications and direct pane control. The single application handles both terminal emulation and multiplexing with consistent cross-platform behavior.

### Other Multiplexers

GNU Screen lacks modern image protocol support, while [Zellij](https://zellij.dev/) offers Sixel support but has a less mature ecosystem. It may be supported in future versions of `MuxDisplay`. For `MuxDisplay`, tmux and WezTerm provide the most reliable image display capabilities.


## Shells

For clean image display in dedicated panes, `MuxDisplay` configures shells to minimize visual clutter by disabling prompts and command echoing.

### Bash

`MuxDisplay` automatically configures bash with `PS1=""` to remove prompts, `set +v` to disable echo, and `stty -echo` to disable terminal echo. Shell state can be restored when needed.

### Zsh

`MuxDisplay` configures `zsh` similarly, using `PS1=""`, `RPS1=""`, `setopt no_verbose`, and additional zsh-specific options like `setopt no_prompt_subst` to disable advanced prompt features.

The package automatically detects shell type by querying the multiplexer for the running process, with fallback to bash if detection fails. This enables automatic selection of appropriate initialization commands for clean image display.
