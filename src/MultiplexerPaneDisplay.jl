module MultiplexerPaneDisplay

include("display.jl")
include("terminal.jl")

# imgcat_cmd = "wezterm imgcat --height {height} '{file}'"
# imgcat_cmd = "wezterm imgcat --height {height} --width {width} '{file}'"
# imgcat_cmd = "wezterm imgcat '{file}'"
# imgcat_cmd = "imgcat -H {height} -W {width} '{file}'; tput cud {height}"
# imgcat_cmd = "imgcat -H {height} '{file}'; tput cud {height}"

# Using tput:
#  move up (`tput cuu [N]`), move down (`tput cud [N]`), move right (`tput cuf [N]`), move left (`tput cub [N]`).

# TODO: MultiplexerPaneDisplay.display function that allows titles


"""Enable the MultiplexerPaneDisplay"""
function enable(; multiplexer = :tmux, verbose = true, kwargs...)
    # TODO: preference file for defaults
    disable(; verbose = false)
    display = DISPLAY_TYPES[multiplexer](; kwargs...)
    if verbose
        @info "Activating $(summary(display))" display.tmpdir display.imgcat_cmd
    end
    initialize_target_pane(display)
    Base.Multimedia.pushdisplay(display)
    return nothing
end


function enabled(; verbose = true)
    ds = Base.Multimedia.displays
    if length(ds) > 1 && (ds[end] isa AbstractMultiplexerPaneDisplay)
        display = ds[end]
        if verbose
            @info "Active $(summary(display))" display.tmpdir display.imgcat_cmd
        end
        return true
    else
        return false
    end
end


function Base.convert(
    ::Type{Dict{Symbol,Any}},
    display::T
) where {T<:AbstractMultiplexerPaneDisplay}
    return Dict{Symbol,Any}(name => getfield(display, name) for name in fieldnames(T))
end


"""Modify an active MultiplexerPaneDisplay"""
function set_options(; verbose = true, kwargs...)
    if enabled(; verbose = false)
        display = Base.Multimedia.displays[end]
        disable(verbose = false)
        display_kwargs = merge(convert(Dict{Symbol,Any}, display), kwargs)
        display = typeof(display)(; display_kwargs...)
        if verbose
            @info "Updating display to $(summary(display))" display.tmpdir display.imgcat_cmd
        end
        initialize_target_pane(display)
        Base.Multimedia.pushdisplay(display)
    else
        if verbose
            @error "MultiplexerPaneDisplay is not active"
        end
    end
    return nothing
end


"""Disable an active MultiplexerPaneDisplay"""
function disable(; verbose = true)
    if enabled(; verbose = false)
        display = Base.Multimedia.displays[end]
        Base.Multimedia.popdisplay()
        if verbose
            @info "Deactivating $(summary(display))"
        end
        restore_target_pane(display)
    else
        if verbose
            @warn "MultiplexerPaneDisplay is not active"
        end
    end
    return nothing
end


# TODO: restore target pane at Julia exit?


include("tmux.jl")  # submodule Tmux
include("wezterm.jl")  # submodule WezTerm

using .Tmux: TmuxPaneDisplay
using .WezTerm: WezTermPaneDisplay

const DISPLAY_TYPES = Dict(:tmux => TmuxPaneDisplay, :wezterm => WezTermPaneDisplay)


end
