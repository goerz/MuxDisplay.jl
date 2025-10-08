# Howto FAQ

## Images are shown in the wrong place in tmux

Images may appear in incorrect panes due to timing issues when `MuxDisplay` switches between panes. Set `sleep_secs` to a value greater than 0 (typically 0.2-0.5 seconds) to allow proper pane switching. For persistent issues, use a dedicated tmux session for image display instead of split panes.

## I'm seeing "weird errors"

Random errors during image display are often caused by timing issues between multiplexer commands. Increase the value of `sleep_secs` to allow more time between operations, especially over slower network connections.

## Images overflow the size of the pane

Images should automatically fit the pane size when `smart_size=true` is enabled. If overflow occurs, check that the `cell_size` parameter accurately reflects your terminal's character dimensions and set it manually if necessary.

The underlying issue is that iTerm protocol `imgcat` commands ignore the height parameter when width is specified. Set a custom `imgcat` command that uses only height or only width to avoid this limitation.

## Tmux does not have scrollback for images

Unlike WezTerm, tmux doesn't preserve images when scrolling. To view multiple images simultaneously, use options like `nrows=2` and `redraw_previous=1` to display several plots at once. You may need to configure a custom `imgcat` command that uses only the height parameter for proper sizing.

## Images disappear when I switch windows in tmux

This behavior is a fundamental limitation of tmux's design. Images are not preserved when switching between tmux windows or sessions. Use a dedicated tmux session for image display that can be viewed in a separate terminal window, or switch to WezTerm multiplexer which maintains image persistence.

## I can't keep track of which image is from which command

Use the `MuxDisplay.display` function with the `title` option to add descriptive labels to your images. This is particularly helpful when displaying multiple plots or when using `redraw_previous` to show several images simultaneously.

## The prompt is overwriting the image

This issue occurs when using `clear=false` or `redraw_previous` options. Since `MuxDisplay` disables shell prompts, overlapping output manifests as images appearing stacked on top of each other. Include `tput` commands in your custom `imgcat_cmd` to properly position the cursor and prevent output overlap.
