# TODO: Detect the shell: https://stackoverflow.com/questions/3327013/how-to-determine-the-current-interactive-shell-that-im-in-command-line
# TODO: ZSH: https://unix.stackexchange.com/questions/343088/what-is-the-equivalent-of-stty-echo-for-zsh

const INITIALIZE = Dict{String,Vector{String}}("bash" => ["PS1=''", "stty -echo", "clear"],)

const RESTORE = Dict{String,Vector{String}}("bash" => ["PS1='> '", "stty echo", "clear"],)

function initialize_target_pane(display)
    # TODO: determine the cell dimensions (pixel width and height of one cell)
    # With that, every time we want to plot an image, we can get the pixel
    # dimensions of the available area, and choose more appropriate `height` or
    # `width` parameters for `imgcat` (if we pass a number for `--width`, the
    # `-height` is ignored!)
    # TODO: Save the environment, so we can restore PS1 on exit. Run
    # `printenv`, parse the output, and store it as en `env` dict in the
    # display.
    for cmd in INITIALIZE["bash"]
        send_cmd(display, cmd)
    end
end


function restore_target_pane(display)
    # TODO: restore PS1 properly.
    for cmd in RESTORE["bash"]
        send_cmd(display, cmd)
    end
end
