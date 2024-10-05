using Printf: @sprintf
using FileIO: save

const MIMES = ("image/png", "image/jpeg")
const FORMATS = ("png", "jpg")


# All fields required, see subtyptes (but this is private API)
abstract type AbstractMultiplexerPaneDisplay <: AbstractDisplay end


# send a command to the target pane and press Enter
function send_cmd(d::AbstractMultiplexerPaneDisplay, cmd)
    throw(MethodError(send_cmd, (d, cmd)))
end

# get the pane dimensions
function get_pane_dimensions(d::AbstractMultiplexerPaneDisplay, pane)
    throw(MethodError(get_pane_dimensions, (d, pane)))
end

requires_switching(::AbstractMultiplexerPaneDisplay) = false

# get get the current pane for displays that require switching)
function get_current_pane(d::AbstractMultiplexerPaneDisplay)
    throw(MethodError(get_current_pane, (d,)))
end

# switch panes (only for displays the require switching)
function select_pane(d::AbstractMultiplexerPaneDisplay, pane)
    throw(MethodError(select_pane, (d, pane)))
end



for (mime, fmt) in zip(MIMES, FORMATS)
    @eval begin

        function Base.display(
            d::AbstractMultiplexerPaneDisplay,
            m::MIME{Symbol($mime)},
            @nospecialize(x);
            # keyword arguments are internal / undocumented, see
            # `MultiplexerPaneDisplay.display` function for the user-facing
            # function that supports these explicitly
            clear = d.clear,
            title = "",
            nrows = d.nrows,
            redraw_previous = d.redraw_previous,
            imgcat = d.imgcat,
            use_filenames_as_title = d.use_filenames_as_title,
        )
            @debug "Base.display(::$(typeof(d)), ::$(typeof(m)), ::$(typeof(x)))"
            n = length(d.files) + 1
            filename = @sprintf("%03d.", n) * $fmt
            file = joinpath(d.tmpdir, filename)
            try
                if d.dry_run
                    @debug "Saving $m representation of $(typeof(x)) object to $file (dry run)"
                else
                    @debug "Saving $m representation of $(typeof(x)) object to $file"
                    save(file, x)
                end
            catch exc
                @debug "Failed to display on $(typeof(d))" exception = exc
                throw(MethodError(Base.display, (d, x)))
                # fall back to another display
            end
            push!(d.files, file)
            if d.only_write_files
                if (title == filename) || (title == "")
                    println("[$file]")
                else
                    println("[$file: $title]")
                end
            else
                if (title == "") && use_filenames_as_title
                    title = filename
                end
                display_files(d; clear, title, nrows, redraw_previous, imgcat)
            end
            return nothing
        end

        Base.displayable(::AbstractMultiplexerPaneDisplay, ::MIME{Symbol($mime)}) = true

    end
end


Base.displayable(::AbstractMultiplexerPaneDisplay, ::MIME) = false


function Base.display(d::AbstractMultiplexerPaneDisplay, @nospecialize(x))
    for mime in MIMES
        if showable(mime, x)
            return Base.display(d, mime, x)
        end
    end
    throw(MethodError(Base.display, (d, x)))
end


# display pending files(s)
function display_files(
    d::AbstractMultiplexerPaneDisplay;
    clear = d.clear,
    title = "",  # tite for d.files[end]
    nrows = d.nrows,
    redraw_previous = d.redraw_previous,
    imgcat = d.imgcat,
)
    dry_run = d.dry_run
    target_pane = d.target_pane
    current_pane = nothing
    if requires_switching(d)
        current_pane = get_current_pane(d)
        select_pane(d, target_pane)
    end
    if clear
        send_cmd(d, "clear")
    end
    pane_width, pane_height = get_pane_dimensions(d, target_pane)
    width = pane_width - 2
    n_show = min(redraw_previous + 1, length(d.files))
    a = lastindex(d.files) - n_show + 1
    b = lastindex(d.files)
    @assert lastindex(d.titles) == (lastindex(d.files) - 1)
    push!(d.titles, title)
    for i = a:b
        file = d.files[i]
        title = d.titles[i]  # redefine title as title for figure `i`
        has_title = (length(title) > 0)
        height::Int64 = (pane_height ÷ nrows) - 2
        if has_title
            height = height - (textwidth(title) ÷ pane_width)
        end
        cmd_str =
            replace(imgcat, "{file}" => file, "{width}" => width, "{height}" => height)
        if has_title
            cmd_str = Base.shell_escape("echo", title) * "; " * cmd_str
        end
        send_cmd(d, cmd_str)
        sleep_secs = d.sleep_secs
        if sleep_secs > 0
            @debug "Sleep for $sleep_secs secs"
            dry_run || sleep(sleep_secs)
        end
    end
    if requires_switching(d)
        select_pane(d, current_pane)
    end
end
