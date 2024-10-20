module WezTerm

import JSON

import ..AbstractMuxDisplay
import ..send_cmd
import ..get_pane_dimensions
import ..needs_clear
import ..get_shell


mutable struct WezTermPaneDisplay <: AbstractMuxDisplay
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
    smart_size::Bool
    scale::Float64
    shell::String
    sleep_secs::Float64
    cell_size::Tuple{Int64,Int64}
    files::Vector{Tuple{String,String,Tuple{Int64,Int64}}}
    # (absolute file name, title, (width, height))
    env::Dict{String,String}
    # output of `printenv`, split into lines
end


function WezTermPaneDisplay(;
    target_pane,
    imgcat,
    tmpdir,
    mux_bin = "wezterm",
    nrows = 1,
    clear = needs_clear(Val(:wezterm)),
    smart_size = true,
    scale = 1.0,
    shell = "bash",
    redraw_previous = (clear ? (nrows - 1) : 0),
    dry_run = false,
    only_write_files = false,
    use_filenames_as_title = false,
    sleep_secs = ((redraw_previous > 0) ? 0.3 : 0.1),
    cell_size = (0, 0),
    files = [],  # internal
    env = Dict{String,String}(), # internal
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
        smart_size,
        scale,
        shell,
        sleep_secs,
        cell_size,
        files,
        env,
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


function get_shell(d::WezTermPaneDisplay; pane = d.target_pane)
    wezterm = d.mux_bin
    wezterm_info = get_wezterm_info(wezterm; d.dry_run)
    shell = "bash"
    if d.dry_run
        @debug "found wezterm pane $pane shell $shell (dry run)"
    else
        for pane_info in wezterm_info
            if string(pane_info["pane_id"]) == string(pane)
                shell = pane_info["title"]
                @debug "found wezterm pane $pane shell $(shell)"
                return shell
            end
        end
        @error "Cannot find WezTerm pane $pane."
    end
    return shell
end

end
