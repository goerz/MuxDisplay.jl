# MultiplexerPaneDisplay

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://goerz.github.io/MultiplexerPaneDisplay.jl/dev/)
[![Build Status](https://github.com/goerz/MultiplexerPaneDisplay.jl/workflows/CI/badge.svg)](https://github.com/goerz/MultiplexerPaneDisplay.jl/actions)
[![Coverage](https://codecov.io/gh/goerz/MultiplexerPaneDisplay.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/goerz/MultiplexerPaneDisplay.jl)

Everyone loves literate programming. [Jupyter notebooks](https://jupyter.org) are probably the most widely used platform for numerical exploration. However, for those used to working in the terminal, the browser environment can be very limiting. The browser text boxes lack the power of a full text editor ([Neovim](https://neovim.io)) and are needlessly mouse-driven (i.e., "slow").

Scientific computing tends to require the use of remote workstations or clusters to access computational resources beyond those of a laptop and to manage long-running computations. [VS Code](https://code.visualstudio.com) has some support for [remote development](https://code.visualstudio.com/docs/remote/remote-overview), but for many, the terminal with a multiplexer like [tmux](https://github.com/tmux/tmux/wiki) provides the ultimate productivity. It also allows using the same development environment whether working locally or on a remote workstation.

Suppose you are working remotely from your MacBook on a Linux workstation, accessible via [SSH](https://www.cloudflare.com/learning/access-management/what-is-ssh/). You have to keep records of your explorations, so you are running a [JupyterLab](https://jupyterlab.readthedocs.io) instance. You could access that Jupyter server on your laptop through [port forwarding](https://igb.mit.edu/mini-courses/advanced-utilization-of-igb-computational-resources/ssh-port-forwarding/ssh-port-forwarding-jupyter-notebooks), but that has all the drawbacks of a web interface. So, you use the [jupytext extension](https://jupytext.readthedocs.io) to link your `.ipynb` files to `.jl` (or `.md`) files that automatically sync, and edit those `.jl` files with Neovim inside a tmux session running on the workstation. Now, in order to actually run the code, you open a Julia REPL in a tmux split-pane, and use the [vim-slime](https://github.com/jpalardy/vim-slime) plugin to send snippets of code from the `.jl` version of the notebook to the REPL.

Things get a little tricky once the code generates graphics, e.g., via [Plots.jl](https://github.com/JuliaPlots/Plots.jl). One possibility is to use [SSH X-forwarding](https://unix.stackexchange.com/questions/12755/). But, this requires having to [install an X-server](https://www.xquartz.org) on your MacBook, and depends on a fast network. Plus (and this applies when plotting _locally_ from the REPL as well), you only get one plot at a time. Another possibility is the amazing [UnicodePlots.jl](https://github.com/JuliaPlots/UnicodePlots.jl). Works great, but has obvious limitations. Now, [modern terminals](https://www.youtube.com/watch?v=9DgQqDnYNyQ) like [WezTerm](https://wezfurlong.org/wezterm/index.html), [iTerm2](https://iterm2.com/), and [Kitty](https://sw.kovidgoyal.net/kitty/) actually support showing high-resolution graphics with their own [iTerm inline graphics protocol](https://iterm2.com/documentation-images.html), the [Kitty terminal graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/), or the standardized (but rather inefficient) [Sixel protocol](https://en.wikipedia.org/wiki/Sixel) that is [supported by quite a number of terminals](https://www.arewesixelyet.com).

There are packages like [ITerm2Images](https://github.com/eschnett/ITerm2Images.jl), [KittyTerminalImages](https://github.com/simonschoelly/KittyTerminalImages.jl), and [SixelTerm](https://github.com/eschnett/SixelTerm.jl) that hook into [Julia's multimedia display system](https://docs.julialang.org/en/v1/base/io-network/#Multimedia-I/O) to automatically show inline graphics. These work extremely well if the REPL runs in a terminal like [WezTerm](https://wezfurlong.org/wezterm/index.html) (which supports all three image protocols). Sizing can be an issue. `KittyTerminalImages` has a [nice option](https://github.com/simonschoelly/KittyTerminalImages.jl?tab=readme-ov-file#setting-the-scale) to control the size of the images.

However, we are working inside `tmux`, and this throws a monkey wrench into things. Inline graphics protocols require tmux to support [OSC](https://en.wikipedia.org/wiki/ANSI_escape_code#OSC_(Operating_System_Command)_sequences) "[passthrough](https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it)", which is available as of [tmux 3.3](https://github.com/tmux/tmux/releases/tag/3.3) and requires `set -gq allow-passthrough on` in your `.tmux.conf` file. The program emitting the escape sequences for image display must be aware that it is running inside tmux and must modify their output accordingly. Programs like [`wezterm imgcat`](https://wezfurlong.org/wezterm/cli/imgcat.html) and [iTerm's `imgcat`](https://iterm2.com/utilities/imgcat) do this, but, e.g., [`KittyTerminalImages` does not](https://github.com/simonschoelly/KittyTerminalImages.jl?tab=readme-ov-file#todo-list). Sixel support requires [tmux 3.4](https://github.com/tmux/tmux/releases/tag/3.4) and `tmux` must be built with `--enable-sixel` (which, e.g., [`brew install tmux`](https://formulae.brew.sh/formula/tmux) on macOS has enabled). Of course, you should also make sure tmux is generally set up correctly, see the [FAQ](https://github.com/tmux/tmux/wiki/FAQ). Even with image support inside tmux, if you are using panes (horizontal or vertical splits within the same window), images often end up in the wrong place. This seems to heavily depend on your terminal emulator, and can ruin "inline" images. Scrolling inside `tmux` or switching between tabs (["windows"](https://github.com/tmux/tmux/wiki/Getting-Started#sessions-windows-and-panes)) will always make the graphics disappear.

Instead of throwing up our hands, we might as well lean into our multiplexer. Instead of *inline* graphics, we'll use a dedicated pane to show images. This is what the `MultiplexerPaneDisplay` package provides, hooking into Julia's display pipelines in a similar way as `KittyTerminalImages`, etc. Instead of directly emitting the image, it sends instructions to the multiplexer to execute an external image viewer (like `imgcat`) in a specific pane. With `tmux`, this still requires passthrough to be set up correctly, but it gets around many of the practical issues with image display in tmux.

* On the remote workstation, start a tmux session. Split the window into panes, with Neovim running on the left, and the Julia REPL on the right, with another pane above it for plotting (pane index `1`, cf. the [`C-b q` shortcut](https://github.com/tmux/tmux/wiki/Getting-Started#changing-the-active-pane))
* Make sure to have an `imgcat` program in your `PATH` on the workstation and that `MultiplexerPaneDisplay` is installed in your base Julia environment
* In the REPL, run `using MultiplexerPaneDisplay; MultiplexerPaneDisplay.enable(target_pane="1")`
* Issue plot commands from the REPL (e.g., from the Neovim pane on the left via `vims-slime`)

The plots will show up in the top right pane.

If you have issues with the images not being properly placed in the target pane, either get a [better terminal emulator](https://wezfurlong.org/wezterm/), or use a separate dedicated tmux session (session name, e.g., `Plots`) that you can open in a separate window. You would then connect to that session with `MultiplexerPaneDisplay.enable(target_pane="Plots:0.0")`. For an even smoother experience, or if your tmux is too old (or you can't figure out how to set up passthrough), consider using the [WezTerm multiplexing feature](https://wezfurlong.org/wezterm/multiplexing.html) to open a remote WezTerm pane that can be used for plotting.

* On the remote workstation, start a tmux session. Split the window into panes, with Neovim running on the left, and the Julia REPL on the right. There is no plotting pane this time.
* Make sure to have the `wezcat` program in your `PATH` on the workstation, in a version that matches your _local_ WezTerm terminal. This is necessary both for the multiplexer and to provide the `wezterm imgcat` program.
* In your local WezTerm terminal (which you've used to ssh into the workstation), open a second window with a tab in the [`SSHMUX:workstation` domain](https://wezfurlong.org/wezterm/multiplexing.html#ssh-domains). Run `printenv | grep WEZTERM_PANE` there to figure out the (remote) pane ID. Let's say it's `10`.
* In the REPL, run `using MultiplexerPaneDisplay; MultiplexerPaneDisplay.enable(multiplexer=:wezterm, target_pane="10")`
* As before, issue plot commands from the REPL (e.g., from the Neovim pane on the left via `vims-slime`)

Note that we are still using `tmux` as our main multiplexer, since [WezTerm doesn't have an exact match for the concept of tmux sessions](https://wezfurlong.org/wezterm/recipes/workspaces.html). Of course, if you don't generally use multiple tmux sessions on your remote workstation, you could just _replace_ `tmux` with the WezTerm multiplexer, and your life will be much easier (the solutions for _inline_ plotting will actually work out of the box).

In our little scenario, you have some conference travel later in the week, where you want to continue working on your remote tmux session. You're not checking luggage, so you are only bringing your iPad for the trip. To connect to your workstation, you use the [Blink Shell iOS app](https://blink.sh) (probably the best-engineered and feature-rich iOS app ever, despite its unassuming appearance). We won't be able to use the WezTerm multiplexer. Blink supports the iTerm inline graphics protocol but seems to have a lot of issues with image placement. It works okay with a dedicated `Plots` tmux session and a little tweaking. You will need to have the [iTerm `imgcat` script](https://iterm2.com/utilities/imgcat) in your `PATH` on the workstation.

* Connect to your remote tmux session (with two panes, Neovim on the left and the Julia REPL on the right) in Blink
* On your iPad, open a second Blink window in slide-over mode
* In the slide-over window, also connect to the workstation, and start a separate tmux session with `tmux new-session -s Plots`.
* In the full-screen Blink window, in the Julia REPL, run `MultiplexerPaneDisplay.enable(target_pane="Plots:0.0", clear=false, imgcat_cmd="imgcat -H {height} '{file}'; tput cud {height}")`

The `tput` part of the `imgcat_cmd` command compensates for an issue with the `imgcat` script in conjunction with Blink that fails to move the cursor below the image. It may take a few plots for the slide-over window to find its groove (we're working around bugs here, but the end result is that you get a quasi-scrolling plot window). If the slide-over window is too small, you can put it in a proper split view instead.



## Installation

```
] add https://github.com/goerz/MultiplexerPaneDisplay.jl.git
```

It is recommended to install `MultiplexerPaneDisplay` into your main Julia environment, together with other development tools such as [Revise](https://github.com/timholy/Revise.jl), [Infiltrator](https://github.com/JuliaDebug/Infiltrator.jl), [BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl), etc.


## Prerequisites

Locally:

* A modern terminal with image support, like [WezTerm](https://wezfurlong.org/wezterm/index.html)


Remotely (or locally, when not using a remote workstation via SSH):

* [`tmux >=3.3`](https://github.com/tmux/tmux)
* Recommended: `wezterm` binary (for multiplexing), in the same version as the local WezTerm.
* The [iTerm `imgcat` script](https://iterm2.com/utilities/imgcat), are an equivalent script for the image protocol supported by your terminal. Note that the `wezterm` binary also provides the `wezterm imgcat` command (also using the iTerm protocol). It is recommended to have both installed, as they both have their own slightly unique behavior that works better in different contexts and with respect to bugs in specific terminal emulators.

## Usage

```
using MultiplexerPaneDisplay

MultiplexerPaneDisplay.enable(target_pane=1)
```

will set up the tmux pane index `1` in your current tmux window as the display for any object that has a `image/png` or `image/jpeg` representation. Most notably, that would be a plot generated by [Plots.jl](https://docs.juliaplots.org/) or [Makie.jl](https://docs.makie.org/).
