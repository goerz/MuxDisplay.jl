module Tmux

import ..AbstractMultiplexerPaneDisplay
import ..display_files
import ..send_cmd


struct TmuxPaneDisplay <: AbstractMultiplexerPaneDisplay
    target_pane::String
    tmpdir::String
    imgcat_cmd::String
    bin::String
    nrows::Int64
    redraw_previous::Int64
    dry_run::Bool
    only_write_files::Bool
    echo_filename::Bool
    clear::Bool
    sleep_secs::Float64
    files::Vector{String}  # Absolute paths of generated files
end


const _imgcat_cmd = "wezterm imgcat --height {height} --width {width} '{file}'"


# TODO: documentation
function TmuxPaneDisplay(;
    target_pane,
    tmpdir = mktempdir(),
    imgcat_cmd = _imgcat_cmd,
    bin = "tmux",
    nrows = 1,
    clear = true,
    redraw_previous = (clear ? (nrows - 1) : 0),
    dry_run = false,
    only_write_files = false,
    echo_filename = true,
    sleep_secs = (contains(target_pane, ":") ? 0.0 : 0.5),
    files = String[],  # internal
)
    # TODO: check that target_pane is either "session:window.pane" or "pane"
    TmuxPaneDisplay(
        String(target_pane),
        tmpdir,
        imgcat_cmd,
        bin,
        nrows,
        redraw_previous,
        dry_run,
        only_write_files,
        echo_filename,
        clear,
        sleep_secs,
        files
    )
end


function Base.summary(io::IO, d::TmuxPaneDisplay)
    msg = "TmuxPaneDisplay for $(d.nrows) row(s) using $(d.bin) target $(d.target_pane)"
    attribs = String[]
    if !d.echo_filename
        push!(attribs, "echo off")
    end
    if !d.clear
        push!(attribs, "do not clear")
    end
    if d.only_write_files
        push!(attribs, "only write files")
    end
    if d.redraw_previous > 0
        push!(attribs, "redraw previous $(d.redraw_previous)")
    end
    if d.dry_run
        push!(attribs, "dry run")
    end
    if length(attribs) > 0
        msg *= " (" * join(attribs, ", ") * ")"
    end
    write(io, msg)
end


function send_cmd(d::TmuxPaneDisplay, cmd_str::AbstractString)
    target_pane = d.target_pane
    tmux_cmd = d.bin
    cmd = `$tmux_cmd send-keys -t $target_pane $cmd_str Enter`
    if d.dry_run
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


function display_files(d::TmuxPaneDisplay)
    dry_run = d.dry_run
    tmux_cmd = d.bin
    target_pane = d.target_pane
    current_pane = get_current_pane(tmux_cmd; dry_run)
    select_pane(tmux_cmd, target_pane; dry_run)
    if d.clear
        send_cmd(d, "clear")
    end
    width, height = get_pane_dimensions(tmux_cmd, target_pane; dry_run)
    width = width - 2
    height::Int64 = (height ÷ d.nrows) - 2
    if d.echo_filename
        height = height - 1
    end
    n_show = min(d.redraw_previous + 1, length(d.files))
    files_to_show = d.files[end-(n_show-1):end]
    for file in files_to_show
        cmd_str = replace(
            d.imgcat_cmd,
            "{file}" => file,
            "{width}" => width,
            "{height}" => height
        )
        if d.echo_filename
            cmd_str = "echo \"$(basename(file))\"; " * cmd_str
        end
        send_cmd(d, cmd_str)
        sleep_secs = d.sleep_secs
        if sleep_secs > 0
            @debug "Sleep for $sleep_secs secs"
            dry_run || sleep(sleep_secs)
        end
    end
    select_pane(tmux_cmd, current_pane; dry_run)
end

end
