# Background

## Image protocols

* iTerm
* Kitty
* Sixel

## Terminals

* Wezterm
* iTerm2
* Kitty
* Blink (iOS)


## Multiplexers

Persistent sessions, running remotely. Multiple windows/panes. We need panes as image targets.

`screen` is not suitable. The "standard" multiplexer is `tmux`. WezTerm.

Maybe `zellij`, but haven't tried it.

Things that could be made to work as a kind of multiplexer is anything that has the notion of a pane and that is scriptable, in the sense that we can make a specific pane execute commands via issuing commands from an unrelated terminal on the same machine.


### Tmux


### WezTerm


## Shells

It is helpful to disable the prompt and echoing.

### Bash

### Zsh
