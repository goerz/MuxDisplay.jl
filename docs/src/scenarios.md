# Scenarios and Workflows

## Choice of terminal

* iTerm2
* Wezterm
* Kitty
* Blink

## Choice of multiplexer

* tmux - no scrollbar, so you may want to emulate scrollback with `redraw_previous`  to show multiple images

* wezterm - scrollback! But you need to install it in matching versions everywhere


## Choice of imgcat program

* iTerm `imgcat`
* `wezterm imgcat`


## Setup Examples


### Running Wezterm locally, no tmux


### Using a tmux display pane

Very dependent on finding the right `imgcat` command.


### Using a tmux display session

Avoids some of the most common issues with using a pane.


### Combining tmux and wezterm multiplexers

This gives the best results, if you're running WezTerm locally.


## Using Blink on iOS with tmux

See "Using a tmux display session", slide-over or split view
