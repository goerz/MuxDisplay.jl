function send_cmd(tmux_cmd, target_pane, cmd_str; dry_run = false)
    cmd = `$tmux_cmd send-keys -t $target_pane $cmd_str Enter`
    if dry_run
        @debug "$cmd (dry run)"
    else
        @debug "$cmd"
        run(cmd)
    end
end


function select_pane(tmux_cmd, pane; dry_run = false)
    cmd = `$tmux_cmd select-pane -t $pane`
    if dry_run
        @debug "$cmd (dry run)"
    else
        @debug "$cmd"
        run(cmd)
    end
end


function get_current_pane(tmux_cmd; dry_run = false)
    cmd = `$tmux_cmd display -p '#{pane_index}'`
    if dry_run
        pane = "<orig pane>"
        @debug "$cmd -> current pane $pane (dry run)"
    else
        pane = strip(read(cmd, String))
        @debug "$cmd -> current pane $pane"
    end
    return pane
end


function get_pane_dimensions(tmux_cmd, pane; dry_run = false)
    cmd = `$tmux_cmd display -p -t $pane '#{pane_width}'`
    if dry_run
        width = 80
        @debug "$cmd -> pane width $width (dry run)"
    else
        width = parse(Int64, strip(read(cmd, String)))
        @debug "$cmd -> pane width $width"
    end
    cmd = `$tmux_cmd display -p -t $pane '#{pane_height}'`
    if dry_run
        height = 24
        @debug "$cmd -> pane height $height (dry run)"
    else
        height = parse(Int64, strip(read(cmd, String)))
        @debug "$cmd -> pane height $height"
    end
    return width, height
end


function display_files(
    target_pane,
    imgcat_cmd,
    tmux_cmd,
    files;
    nrows = 1,
    dry_run = false,
    echo_filename = true,
    clear = true,
    sleep_secs = (contains(target_pane, ":") ? 0.0 : 0.5)
)
    current_pane = get_current_pane(tmux_cmd; dry_run)
    select_pane(tmux_cmd, target_pane; dry_run)
    if clear
        send_cmd(tmux_cmd, target_pane, "clear"; dry_run)
    end
    width, height = get_pane_dimensions(tmux_cmd, target_pane; dry_run)
    width = width - 2
    height::Int64 = (height ÷ nrows) - 2
    if echo_filename
        height = height - 1
    end
    for file in files
        cmd_str =
            replace(imgcat_cmd, "{file}" => file, "{width}" => width, "{height}" => height)
        if echo_filename
            cmd_str = "echo \"$(basename(file))\"; " * cmd_str
        end
        send_cmd(tmux_cmd, target_pane, cmd_str; dry_run)
        if sleep_secs > 0
            @debug "Sleep for $sleep_secs secs"
            dry_run || sleep(sleep_secs)
        end
    end
    select_pane(tmux_cmd, current_pane; dry_run)
end
