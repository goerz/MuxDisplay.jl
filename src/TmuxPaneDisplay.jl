module TmuxPaneDisplay

include("display.jl")
include("tmux.jl")
include("terminal.jl")

imgcat_cmd = "wezterm imgcat --height {height} '{file}'"
# imgcat_cmd = "wezterm imgcat --height {height} --width {width} '{file}'"
# imgcat_cmd = "wezterm imgcat '{file}'"
# imgcat_cmd = "imgcat -H {height} -W {width} '{file}'; tput cud {height}"
# imgcat_cmd = "imgcat -H {height} '{file}'; tput cud {height}"

# Using tput:
#  move up (`tput cuu [N]`), move down (`tput cud [N]`), move right (`tput cuf [N]`), move left (`tput cub [N]`).


"""Enable the TmuxPaneDisplay"""
function enable(;
    target_pane,
    tmpdir = mktempdir(),
    imgcat_cmd = imgcat_cmd,
    tmux_cmd = "tmux",
    nrows = 1,
    dry_run = false,
    only_write_files = false,
    echo_filename = true,
    clear = true,
    verbose = true,
    sleep_secs = (contains(target_pane, ":") ? 0.0 : 0.5)
)
    # TODO: preference file for defaults
    files = String[]
    disable(; verbose = false)
    display = _TmuxPaneDisplay(
        String(target_pane),
        tmpdir,
        imgcat_cmd,
        tmux_cmd,
        nrows,
        dry_run,
        only_write_files,
        echo_filename,
        clear,
        sleep_secs,
        files
    )
    verbose && _activation_msg(display)
    Base.Multimedia.pushdisplay(display)
    for cmd in INITIALIZE["bash"]
        send_cmd(tmux_cmd, target_pane, cmd; dry_run)
    end
    return nothing
end


function _activation_msg(display; verb = "Activating")
    msg = "$verb TmuxPaneDisplay for $(display.nrows) row(s) using $(display.tmux_cmd) target $(display.target_pane)"
    if display.echo_filename
        msg *= " (echo on)"
    else
        msg *= " (echo off)"
    end
    if display.dry_run
        msg *= " (dry run)"
    end
    if !display.clear
        msg *= " (clear = false)"
    end
    if display.only_write_files
        msg *= " (only write files)"
    end
    @info msg display.tmpdir display.imgcat_cmd
end


function enabled(; verbose = true)
    ds = Base.Multimedia.displays
    if length(ds) > 1 && (ds[end] isa _TmuxPaneDisplay)
        if verbose
            _activation_msg(ds[end]; verb = "Active")
        end
        return true
    else
        return false
    end
end

# function rewind(n=1)
# end

# function compare(n=1)
# end
#

"""Modify an active TmuxPaneDisplay"""
function set_options(; verbose = true, kwargs...)
    if enabled(; verbose = false)
        d = Base.Multimedia.displays[end]
        disable(verbose = false)
        allowed_kwargs = Set((
            :tmpdir,
            :imgcat_cmd,
            :tmux_cmd,
            :nrows,
            :dry_run,
            :only_write_files,
            :echo_filename,
            :clear,
            :sleep_secs,
            :tmpdir,
        ))
        for key in keys(kwargs)
            if key ∉ allowed_kwargs
                throw(ArgumentError("Invalid keyword argument $key"))
            end
        end
        d_new = _TmuxPaneDisplay(
            d.target_pane,
            get(kwargs, :tmpdir, d.tmpdir),
            get(kwargs, :imgcat_cmd, d.imgcat_cmd),
            get(kwargs, :tmux_cmd, d.tmux_cmd),
            get(kwargs, :nrows, d.nrows),
            get(kwargs, :dry_run, d.dry_run),
            get(kwargs, :only_write_files, d.only_write_files),
            get(kwargs, :echo_filename, d.echo_filename),
            get(kwargs, :clear, d.clear),
            get(kwargs, :sleep_secs, d.sleep_secs),
            haskey(kwargs, :tmpdir) ? String[] : d.files
        )
        verbose && _activation_msg(d_new)
        Base.Multimedia.pushdisplay(d_new)
        for cmd in INITIALIZE["bash"]
            send_cmd(d_new.tmux_cmd, d_new.target_pane, cmd; d_new.dry_run)
        end
    else
        if verbose
            @error "TmuxPaneDisplay is not active"
        end
    end
end


"""Disable an active TmuxPaneDisplay"""
function disable(; verbose = true)
    if enabled(; verbose = false)
        d = Base.Multimedia.displays[end]
        Base.Multimedia.popdisplay()
        if verbose
            _activation_msg(d; verb = "Deactivating")
        end
        for cmd in RESTORE["bash"]
            send_cmd(d.tmux_cmd, d.target_pane, cmd; dry_run = d.dry_run)
        end
    else
        if verbose
            @warn "TmuxPaneDisplay is not active"
        end
    end
    return nothing
end



end
