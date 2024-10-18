# TODO: Detect the shell: https://stackoverflow.com/questions/3327013/how-to-determine-the-current-interactive-shell-that-im-in-command-line
# TODO: ZSH: https://unix.stackexchange.com/questions/343088/what-is-the-equivalent-of-stty-echo-for-zsh

const INITIALIZE = Dict{String,Vector{String}}("bash" => ["PS1=''", "stty -echo", "clear"],)

const RESTORE = Dict{String,Vector{String}}("bash" => ["PS1='> '", "stty echo", "clear"],)


function initialize_target_pane!(display)
    # TODO: Save the environment, so we can restore PS1 on exit. Run
    # `printenv`, parse the output, and store it as en `env` dict in the
    # display.
    for cmd in INITIALIZE["bash"]
        send_cmd(display, cmd)
    end
    if display.cell_size == (0, 0)
        set_cell_size!(display)
    end
end


function set_cell_size!(display)
    try
        cmd = raw"IFS=';' read -rs -d t -p $'\e[16t' -a CELL_SIZE"
        send_cmd(display, cmd)
        cellsize_file = joinpath(display.tmpdir, "cellsize")
        sleep(5 * display.cell_size_timeout)
        cmd = "echo \${CELL_SIZE[1]}x\${CELL_SIZE[2]} > $cellsize_file"
        send_cmd(display, cmd)
        h, w = display.cell_size
        if display.dry_run
            @debug "Set display cell_size = ($h, $w) (dry run)"
        else
            for attempt = 1:10
                # The "echo" command is asynchronous, so we may have to wait
                # for the output file to actually exist
                if !isfile(cellsize_file)
                    sleep(attempt * display.cell_size_timeout)
                end
            end
            # If `cellsize_file` still doesn't exist, we'll throw an exception
            h, w = parse.(Int64, split(read(cellsize_file, String), "x"))
            @debug "Set display cell_size = ($h, $w)"
        end
        display.cell_size = (h, w)
    catch exception
        @warn "Cannot determine terminal cell size" exception display.cell_size
    end
end


function restore_target_pane(display)
    # TODO: restore PS1 properly.
    for cmd in RESTORE["bash"]
        send_cmd(display, cmd)
    end
end
