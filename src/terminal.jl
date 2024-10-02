# TODO: Detect the shell: https://stackoverflow.com/questions/3327013/how-to-determine-the-current-interactive-shell-that-im-in-command-line
# TODO: ZSH: https://unix.stackexchange.com/questions/343088/what-is-the-equivalent-of-stty-echo-for-zsh

INITIALIZE = Dict{String,Vector{String}}("bash" => ["PS1=''", "stty -echo", "clear"],)

RESTORE = Dict{String,Vector{String}}("bash" => ["PS1='> '", "stty echo", "clear"],)
