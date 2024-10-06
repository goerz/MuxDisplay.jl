module WezTerm

import JSON

import ..AbstractMultiplexerPaneDisplay
import ..send_cmd
import ..get_pane_dimensions
import ..find_imgcat
import ..needs_clear


struct WezTermPaneDisplay <: AbstractMultiplexerPaneDisplay
    target_pane::String
    tmpdir::String
    imgcat::String
    mux_bin::String
    nrows::Int64
    redraw_previous::Int64
    dry_run::Bool
    only_write_files::Bool
    use_filenames_as_title::Bool
    clear::Bool
    sleep_secs::Float64
    files::Vector{String}  # Absolute paths of generated files
    titles::Vector{String}  # Title for each file
end


function WezTermPaneDisplay(;
    target_pane,
    imgcat,
    tmpdir = mktempdir(),
    mux_bin = "wezterm",
    nrows = 1,
    clear = needs_clear(Val(:wezterm)),
    redraw_previous = (clear ? (nrows - 1) : 0),
    dry_run = false,
    only_write_files = false,
    use_filenames_as_title = true,
    sleep_secs = ((redraw_previous > 0) ? 0.2 : 0.0),
    files = String[],  # internal
    titles = String[],  # internal
)
    # TODO: check that target_pane is valid
    WezTermPaneDisplay(
        string(target_pane),
        tmpdir,
        imgcat,
        mux_bin,
        nrows,
        redraw_previous,
        dry_run,
        only_write_files,
        use_filenames_as_title,
        clear,
        sleep_secs,
        files,
        titles,
    )
end


needs_clear(::Val{:wezterm}) = false


function Base.summary(io::IO, d::WezTermPaneDisplay)
    msg = "WezTermPaneDisplay for $(d.nrows) row(s) using $(d.mux_bin) target $(d.target_pane)"
    attribs = String[]
    if d.clear
        push!(attribs, "clear")
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


function send_cmd(d::WezTermPaneDisplay, cmd_str::AbstractString)
    target_pane = d.target_pane
    wezterm = d.mux_bin
    cmd = `$wezterm cli send-text --no-paste --pane-id $target_pane`
    if d.dry_run
        @debug "$cmd (dry run)" stdin = cmd_str
    else
        @debug "$cmd" stdin = cmd_str
        open(cmd, "w") do process
            println(process, cmd_str)
        end
    end
end


function get_wezterm_info(wezterm; dry_run = false)
    cmd = `$wezterm cli list --format json`
    if dry_run
        @debug "$cmd (dry run)"
        return []
    else
        open(cmd, "r") do process
            output = read(process, String)
            data = JSON.parse(output)
            @debug "$cmd" data
            return data
        end
    end
end


function get_pane_dimensions(d::WezTermPaneDisplay, pane)
    wezterm = d.mux_bin
    wezterm_info = get_wezterm_info(wezterm; d.dry_run)
    if d.dry_run
        @debug "found wezterm pane $pane dimension 80x24 (dry run)"
        return 80, 24
    else
        for pane_info in wezterm_info
            if string(pane_info["pane_id"]) == string(pane)
                height = pane_info["size"]["rows"]
                width = pane_info["size"]["cols"]
                @debug "found wezterm pane $pane dimension $(width)x$(height)"
                return width, height
            end
        end
        @error "Cannot find WezTerm pane $pane."
        return 80, 24
    end
end


end
