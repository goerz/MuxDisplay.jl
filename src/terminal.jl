# TODO: Detect the shell: https://stackoverflow.com/questions/3327013/how-to-determine-the-current-interactive-shell-that-im-in-command-line
# TODO: ZSH: https://unix.stackexchange.com/questions/343088/what-is-the-equivalent-of-stty-echo-for-zsh
# TODO: restore PS1 properly

const INITIALIZE = Dict{String,Vector{String}}("bash" => ["PS1=''", "stty -echo", "clear"],)

const RESTORE = Dict{String,Vector{String}}("bash" => ["PS1='> '", "stty echo", "clear"],)

function initialize_target_pane(display)
    for cmd in INITIALIZE["bash"]
        send_cmd(display, cmd)
    end
end


function restore_target_pane(display)
    for cmd in RESTORE["bash"]
        send_cmd(display, cmd)
    end
end
