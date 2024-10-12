# Howto FAQ

## Images are shown in the wrong place in tmux

Set `sleep_secs` greater than 0. Use a dedicated `tmux` session.

## Weird errors

Increase the value of `sleep_secs`.

## Images overflow the size of the pane

Shouldn't happen with `smart_size=true`. Check that `cell_size` is accurate and set it manually, if necessary.

The problem is that the iTerm-protocol-`imgcat` ignores "height" if "width" is given.

Set an `imgcat_cmd` that uses *only* the height or width

## Tmux does not have scrollback for images

Use, e.g., `nrows=2`, `redraw_previous=1`. You may have to set an `imgcat_cmd` that only uses the height.

## Images disappear when I switch windows in `tmux`

This is a fundamental restriction of tmux. Use a dedicated `tmux` session in a different window. Use WezTerm multiplexer instead.

## I can't keep track of which image is from which command

Use `MultiplexerPaneDisplay.display` with the `title` option

## The prompt is overwriting the image

Occurs only with `clear=false` or `redraw_previous`. Since we disable the prompt, this manifests as images being "on top of each other".

Use `tput` as part of the `imgcat_cmd` to solve this
