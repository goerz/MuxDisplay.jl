# MuxDisplay

```@raw html
<iframe id="overview-video" width="560" height="315" src="https://www.youtube.com/embed/jvfhw2EI5i8?si=MAN2kf-K7FQ_0aqZ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
```

## Overview

`MuxDisplay` is a Julia package that enables display of graphics from [Julia](https://julialang.org) REPLs running inside terminal multiplexers ([tmux](https://github.com/tmux/tmux/wiki), [WezTerm](https://wezterm.org)) by redirecting image output to dedicated panes, exploiting [modern terminals'](https://www.youtube.com/watch?v=9DgQqDnYNyQ) ability for displaying images. The package hooks into [Julia's multimedia display system](https://docs.julialang.org/en/v1/base/io-network/#Multimedia-I/O) to intercept objects with an image representation, writes them to temporary files, and uses external `imgcat` programs to display them in specified multiplexer panes.

The package currently supports both [tmux](https://github.com/tmux/tmux/wiki) and [WezTerm](https://wezterm.org) multiplexers with different display strategies. For tmux, it leverages [OSC](https://en.wikipedia.org/wiki/ANSI_escape_code#OSC_(Operating_System_Command)_sequences) [passthrough](https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it) sequences ([tmux ≥3.3](https://github.com/tmux/tmux/releases/tag/3.3)) to communicate with the underlying terminal emulator. For WezTerm, it uses the native [multiplexing capabilities](https://wezterm.org/multiplexing.html) and pane targeting. Key features include configurable target panes, image sizing control, automatic terminal protocol detection, and support for multiple image display programs including [`wezterm imgcat`](https://wezterm.org/imgcat.html), [iTerm's `imgcat`](https://iterm2.com/utilities/imgcat), and [Kitty's `icat`](https://sw.kovidgoyal.net/kitty/kittens/icat/).


## Installation and Usage

`MuxDisplay` is not yet registered in the Julia General registry. Install directly from the repository:

```julia
] add https://github.com/goerz/MuxDisplay.jl.git
```

It is recommended to install `MuxDisplay` into your main Julia environment. To use, run

```julia
using MuxDisplay
```

in the REPL. Assuming _local_ usage, with `tmux` for output:

* Determine the target pane: Press `Ctrl+b q` (or your tmux prefix + `q`) to show pane numbers, or run `tmux display -p '#{pane_index}'` in the target pane
* Run e.g. `MuxDisplay.enable(target_pane="1")`  to use the target pane `1`

Or, for WezTerm:

* Open a WezTerm window, run `echo $WEZTERM_PANE` to get the WezTerm pane number
* Run, e.g., `MuxDisplay.enable(multiplexer=:wezterm, target_pane=1)` to use the target pane `1`

See [`MuxDisplay.enable`](@ref) and the remainder of the documentation for details.


## Related Projects

### Alternatives

* [ITerm2Images](https://github.com/eschnett/ITerm2Images.jl) – Display inline images using the [iTerm2 protocol](https://iterm2.com/documentation-images.html)
* [KittyTerminalImages](https://github.com/simonschoelly/KittyTerminalImages.jl) –  Display inline images using the [Kitty terminal graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)
* [SixelTerm](https://github.com/eschnett/SixelTerm.jl) – Displaying inline images using the [Sixel protocol](https://en.wikipedia.org/wiki/Sixel)

While these alternatives work well in direct terminal sessions, they face significant limitations inside multiplexers:

* tmux compatibility issues: `KittyTerminalImages` [does not support tmux passthrough](https://github.com/simonschoelly/KittyTerminalImages.jl?tab=readme-ov-file#todo-list); `ITerm2Images` displays at cursor location
* Image persistence problems: Images disappear when scrolling or switching tmux windows/tabs
* Placement issues: Inline images often appear in wrong locations within split panes
* Sizing limitations: Images frequently appear too small or with poor aspect ratios

`MuxDisplay` addresses these shortcomings by using dedicated multiplexer panes instead of inline display, providing persistent images with configurable sizing and intelligent pane targeting.

### Terminals and Multiplexers

* [WezTerm](https://wezterm.org/) – Primary supported terminal emulator with built-in multiplexing and comprehensive image protocol support
* [tmux](https://github.com/tmux/tmux/wiki) – Primary supported terminal multiplexer with [OSC passthrough](https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it) capabilities for image display
* [iTerm2](https://iterm2.com/) – macOS terminal emulator with native image protocol support
* [Kitty](https://sw.kovidgoyal.net/kitty/) – Cross-platform terminal emulator with its own graphics protocol
* [Blink Shell iOS app](https://blink.sh) – iOS SSH client with iTerm2 protocol support for mobile development workflows


### Workflow Software

The following software is used in the [Overview video](#overview-video), as part of a terminal-based workflow:

* [Neovim](https://neovim.io) – Text editor commonly used for editing notebook source files in the terminal-based workflow
* [Jupytext](https://jupytext.readthedocs.io) – Tool for synchronizing Jupyter notebooks with plain text formats for version control
* [`jupytext.nvim`](https://github.com/goerz/jupytext.nvim) – Neovim plugin for seamless Jupytext integration and notebook editing
* [`vim-slime`](https://github.com/jpalardy/vim-slime) – Vim/Neovim plugin for sending code snippets from editor to REPL panes
