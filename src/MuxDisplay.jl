module MuxDisplay

include("display.jl")
include("shells.jl")
include("imgcat.jl")


"""Enable display via `MuxDisplay`

```julia
MuxDisplay.enable(;
    multiplexer = :tmux,
    target_pane,  # mandatory keyword argument
    verbose = true,
    tmpdir = mktempdir(),
    mux_bin = <"tmux" | "wezterm">
    nrows = 1,
    clear = MuxDisplay.needs_clear(Val(multiplexer)),
    smart_size = true,
    scale = 1.0,
    shell = "",
    use_pixels = false,
    redraw_previous = (clear ? (nrows - 1) : 0),
    imgcat = "",
    dry_run = false,
    only_write_files = false,
    use_filenames_as_title = false,
    sleep_secs = <automatic>,
    cell_size = (0, 0),
)
```

enables [Julia's builtin display system](https://docs.julialang.org/en/v1/base/io-network/#Multimedia-I/O)
to show objects that have an `image/png` or `image/jpeg` representation the
pane of a terminal multiplexer pane, relying on a suitable terminal emulator's
ability to render images. This works by writing the data to a file in a
temporary directory and then calling a suitable `imgcat` program to show that
file in the terminal.

# Arguments

* `multiplexer`: The terminal multiplex to use for displaying graphics.
  One of `:tmux`, `:wezterm`.

* `target_pane`: A specification for which multiplexer pane to use as a
  display.  If the `multiplexer` is `:tmux`, this can either be an integer
  indicating a pane in the current tmux window, or a specification of the form
  `"session:window.pane"` to use a pane in an arbitrary window of a running
  tmux session. See The pane number can be obtained by running
  `tmux display -p '#{pane_index}'` in a particular pane (or via the `C-b q`
  shortcut) . If the `multiplexer` is `:wezterm`, this should be the WezTerm
  pane id, which can be obtained from the `WEZTERM_PANE` environment variable
  inside that pane.

* `mux_bin`: The executable for the multiplexer, `"tmux"` if `multiplexer` is
  `:tmux`, and `"wezterm"` if `multiplexer` is `:wezterm`. This can be set to
  an absolute path if the executable is not in the shell's `PATH`.

* `verbose`: If `true`, show information about the display that is being
  activated.

* `tmpdir`: The directory to which to write the temporary files for each
  invocation of `display`. The files will be consecutively numbered, e.g.,
  `001.png`, `002.png`, etc. The default `mktempdir()` results in a directory
  that is automatically deleted on exit. Passing an existing directory will
  cause the image files to persist in that folder.

* `imgcat`: The command to be used for displaying an image file. It should
  contain any of the following placeholder strings, which will be substituted
  before executing the command:

  * `{file}`: The absolute path to the temporary image file
  * `{height}`: The number of rows in the terminal reserved for drawing the
    image. This is generally the height of the output terminal window, divided
    by `nrows`, and some buffer space for printing titles.
  * `{width}`: The number of columns in the terminal reserved for drawing the
    image. If `smart_size=true`, then `{width}` may be replaced with the string
    `auto` in situations where the aspect ratio of the image is such that
    drawing it with a specific width would overflow the available `height`.
    This accounts for the behavior in iTerms's inline graphics protocol where
    `height` is ignored if a specific `width` is given.
  * `{pixel_height}`: The pixel height of the temporary image file, multiplied
    with `scale`. This does not include a "px" suffix.
  * `{pixel_width}`: The pixel width of the temporary image file, multiplied by
    `scale`.

  If given as an empty string (default), `MuxDisplay` will attempt
  to find an available executable and choose parameters based on heuristics. It
  will attempt to use either the `wezterm imgcat` command or iTerm's `imgcat`
  script. The `smart_size`, `nrows`, and `use_pixels` arguments affect the
  default `imgcat` command.

* `nrows`: The number of image rows that should fit into the pane. This affects
  the `{width}` and `{height}` placeholders in `imgcat`.

* `clear`: Whether to issue a `clear` command to the target pane before
  display. By default, this is chosen based on the multiplexer (`true` for
  `:tmux`, `false` for `:wezterm`)

* `smart_size`: If `true`, the `{width}` placeholder in `imgcat` may be
  replaced with `"auto"` if the image is determined to require a strict height
  constraint. This depends on an accurate `cell_size` (at least a `cell_size`
  with the correct aspect ratio). With the default `imgcat`, this option will
  not affect the output if `use_pixels=true`.

* `scale`: A scaling factor for the pixel dimensions of the image, used for the
  `{pixel_height}` and `{pixel_width}` placeholders in `imgcat`. A primary use
  case is `scale=2.0` to compensate for terminal applications that do not take
  into account running on a 2x "retina resolution" display. Note that `scale`
  does not scale the underlying image and has no effect if `imgcat` does not
  use the pixel-size placeholders, cf. `use_pixels`.

* `shell`: The shell running in the target pane. This determines how the pane
  is initialized (disabling the prompt, etc.) and reset. If empty, this will
  determined automatically by queriying the multiplexer for the process
  running in the pane, with a fallback to `"bash"`.

* `use_pixels`: If `true`, default to an `imgcat` command that uses the pixel
  dimensions of the image, i.e., the `{pixel_height}` and `{pixel_width}`
  placeholders instead of the `{height}` and `{width}` placeholders. This may
  be combined with `scale`. A consequence of `use_pixels=true` is that the
  images will be displayed at their fixed original size, which may overflow the
  number of rows and columns available in the terminal.

  This option has no effect if `imgcat` is given manually, as it only
  determines the specific options used for calling iTerm's `imgcat` command or
  `wezterm imgcat`.

* `redraw_previous`: If set to an integer > 1, for each call to `display`,
  first redraw the given number of previous images. This accounts for the lack
  of scrollback in tmux, allowing to compare the current image with previous
  images. If using this option, it is recommended to also use `clear = true`.

* `dry_run`: If true, to not write any files and do not display any images.
  To be used for debugging in combination with
  `ENV["JULIA_DEBUG"] = MuxDisplay`

* `only_write_files`: If true, write image files to `tempdir`, but do not
  display them in the target pane. This allows to use `MuxDisplay`
  without an actual multiplexer running, under the assumption that the image
  files can be viewed independently.

* `use_filenames_as_title`: If true, print the filename of the temporary file
  before rendering the image. Note that more descriptive titles can be used by
  calling [`MuxDisplay.display`](@ref).

* `sleep_secs`: The number of seconds to sleep after drawing each image. This
  defaults to a heuristic value. If `multiplexer=:tmux`, and `target_pane` is a
  pane in the current window, `MuxDisplay` needs to actively switch
  to the target pane, issue the `imgcat` command, wait for the image to render,
  and then switch back to the current pane. If `sleep_secs` to too short so
  that switching back to the current pane happens before the rendering is
  complete, the image will be shown in the wrong place. Also, when using
  `redraw_previous` to draw multiple images, there may need be be a delay for
  on image to finish rendering before issuing the command to draw the next
  image. Typical values are on the order of 0.2-0.5 seconds, possibly longer
  on laggy connections.

* `cell_size`: A tuple of for the height and width in pixels of a single
  cell (character) in the terminal. If given as the default `(0, 0)`, this
  will be automatically determined by sending the "16t" xterm control sequence
  to the terminal. This could also be determined manually be dividing the pixel
  size of the terminal window by its size (columns, rows). Only the ratio of
  height to width matters here, and for many monospaced fonts, this is roughly
  2:1. The `cell_size` is used for the `smart_size` option.
"""
function enable(;
    target_pane,
    multiplexer = :tmux,
    nrows = 1,
    clear = needs_clear(Val(multiplexer)),
    smart_size = true,
    redraw_previous = (clear ? (nrows - 1) : 0),
    tmpdir = mktempdir(),
    imgcat = "",
    cell_size = (0, 0),
    only_write_files = false,
    use_pixels = false,
    scale = 1.0,
    shell = "",
    verbose = true,
    _display_type = DISPLAY_TYPES[multiplexer],  # internal (for testing)
    kwargs...
)
    disable(; verbose = false)
    if imgcat == ""
        imgcat = find_imgcat(; multiplexer, nrows, smart_size, use_pixels,)
    end
    display = _display_type(;
        target_pane,
        tmpdir,
        imgcat,
        nrows,
        clear,
        smart_size,
        scale,
        shell,
        redraw_previous,
        only_write_files,
        cell_size,
        kwargs...
    )
    if verbose
        @info "Activating $(summary(display))" display.tmpdir display.imgcat
    end
    if !display.only_write_files
        initialize_target_pane!(display)
    end
    Base.Multimedia.pushdisplay(display)
    return nothing
end


"""Check whether MuxDisplay is active.

```
MuxDisplay.enabled(; verbose=true)
```

returns `true` if the currently active display
(`Base.Multimedia.displays[end]`) is provided by `MuxDisplay`. If
`verbose=true`, also show some information about the configuration of the
display.
"""
function enabled(; verbose = true)
    ds = Base.Multimedia.displays
    if length(ds) > 1 && (ds[end] isa AbstractMuxDisplay)
        display = ds[end]
        if verbose
            @info "Active $(summary(display))" display.tmpdir display.imgcat
        end
        return true
    else
        return false
    end
end


"""Modify an active display.

```
MuxDisplay.set_options(; verbose, kwargs...)
```

overrides the keyword arguments originally given in
[`MuxDisplay.enable`](@ref) for the currently active display for
all future invocations of `display`.
"""
function set_options(; verbose = true, kwargs...)
    if enabled(; verbose = false)
        display = Base.Multimedia.displays[end]
        disable(verbose = false)
        for (key, value) in kwargs
            setfield!(display, key, value)
        end
        if verbose
            @info "Updating display to $(summary(display))" display.tmpdir display.imgcat
        end
        if !display.only_write_files
            initialize_target_pane!(display)
        end
        Base.Multimedia.pushdisplay(display)
    else
        if verbose
            @error "MuxDisplay is not active"
        end
    end
    return nothing
end


"""Disable using `MuxDisplay` as the current display.

```julia
MuxDisplay.disable(; verbose = true)
```

disables the current display if it is managed by `MuxDisplay`. With
`verbose=true`, also print some information about the settings of the
deactivated system, or a warning if the current display is not managed by
`MuxDisplay`.
"""
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
            @warn "MuxDisplay is not active"
        end
    end
    return nothing
end


# See `Base.display` in `display.jl` for supported `kwargs`
"""Show an object with a custom title and other options.

```
MuxDisplay.display(x; title="", kwargs...)
```

shows `x` (which must have a `image/png` or `image/jpeg` representation) on the
current display, after printing the given `title` (in lieu of the filename if
the display was set up with `use_filenames_as_title = true`). Additional
keyword arguments can be `clear`, `nrows`, `redraw_previous`, `imgcat`, and
`use_filenames_as_title`, and temporarily override the corresponding options in
the display.

Note that this is a different function than `Base.display`, which does not take
keyword arguments.
"""
function display(x; title = "", kwargs...)
    if enabled(; verbose = false)
        d = Base.Multimedia.displays[end]
        for mime in MIMES
            if showable(mime, x)
                if title != ""
                    return Base.display(d, MIME(mime), x; title, kwargs...)
                else
                    return Base.display(d, MIME(mime), x; kwargs...)
                end
            end
        end
    end
    println(title)
    Base.display(x)
end


# TODO: restore target pane at Julia exit?

needs_clear(::Val) = true

include("tmux.jl")  # submodule Tmux
include("wezterm.jl")  # submodule WezTerm

using .Tmux: TmuxPaneDisplay
using .WezTerm: WezTermPaneDisplay

const DISPLAY_TYPES = Dict(:tmux => TmuxPaneDisplay, :wezterm => WezTermPaneDisplay)


end
