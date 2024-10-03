# MultiplexerPaneDisplay

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://goerz.github.io/MultiplexerPaneDisplay.jl/dev/)
[![Build Status](https://github.com/goerz/MultiplexerPaneDisplay.jl/workflows/CI/badge.svg)](https://github.com/goerz/MultiplexerPaneDisplay.jl/actions)
[![Coverage](https://codecov.io/gh/goerz/MultiplexerPaneDisplay.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/goerz/MultiplexerPaneDisplay.jl)


## Installation

```
] add https://github.com/goerz/MultiplexerPaneDisplay.jl.git
```

## Prerequisites

* [WezTerm](https://wezfurlong.org/wezterm/index.html)
* [`tmux >=3.3`](https://github.com/tmux/tmux)

## Usage

```
using MultiplexerPaneDisplay

MultiplexerPaneDisplay.enable(target_pane=1)
```
