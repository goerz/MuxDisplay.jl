# TmuxPaneDisplay

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://goerz.github.io/TmuxPaneDisplay.jl/dev/)
[![Build Status](https://github.com/goerz/TmuxPaneDisplay.jl/workflows/CI/badge.svg)](https://github.com/goerz/TmuxPaneDisplay.jl/actions)
[![Coverage](https://codecov.io/gh/goerz/TmuxPaneDisplay.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/goerz/TmuxPaneDisplay.jl)

## Installation

```
] add https://github.com/goerz/TmuxPaneDisplay.jl.git
```

## Prerequisites

* [WezTerm](https://wezfurlong.org/wezterm/index.html)
* [`tmux >=3.3`](https://github.com/tmux/tmux)

## Usage

```
using TmuxPaneDisplay

TmuxPaneDisplay.enable(target_pane=1)
```
