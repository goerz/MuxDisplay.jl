using Printf: @sprintf
using FileIO: load, save, Stream, DataFormat

const MIMES = ("image/png", "image/jpeg")
const FORMATS = ("png", "jpg")


# All fields required, see subtyptes (but this is private API)
abstract type AbstractMuxDisplay <: AbstractDisplay end


# send a command to the target pane and press Enter
function send_cmd(d::AbstractMuxDisplay, cmd)
    throw(MethodError(send_cmd, (d, cmd)))
end

# get the pane dimensions
function get_pane_dimensions(d::AbstractMuxDisplay, pane)
    throw(MethodError(get_pane_dimensions, (d, pane)))
end

# get the shell (front-running process)
function get_shell(d::AbstractMuxDisplay; pane = d.target_pane)
    throw(MethodError(get_shell, (d,)))
end

requires_switching(::AbstractMuxDisplay) = false

# get get the current pane for displays that require switching)
function get_current_pane(d::AbstractMuxDisplay)
    throw(MethodError(get_current_pane, (d,)))
end

# switch panes (only for displays the require switching)
function select_pane(d::AbstractMuxDisplay, pane)
    throw(MethodError(select_pane, (d, pane)))
end



for (mime, fmt) in zip(MIMES, FORMATS)
    @eval begin

        function Base.display(
            d::AbstractMuxDisplay,
            m::MIME{Symbol($mime)},
            @nospecialize(x);
            # keyword arguments are internal / undocumented, see
            # `MuxDisplay.display` function for the user-facing
            # function that supports these explicitly
            clear = d.clear,
            title = "",
            nrows = d.nrows,
            redraw_previous = d.redraw_previous,
            imgcat = d.imgcat,
            use_filenames_as_title = d.use_filenames_as_title,
            smart_size = d.smart_size,
            target_pane = d.target_pane,
            cell_size = d.cell_size,
            sleep_secs = d.sleep_secs,
            scale = d.scale,
            dry_run = d.dry_run,
        )
            @debug "Base.display(::$(typeof(d)), ::$(typeof(m)), ::$(typeof(x)))"
            n = length(d.files) + 1
            filename = @sprintf("%03d.", n) * $fmt
            file = joinpath(d.tmpdir, filename)
            buff = IOBuffer()
            show(buff, m, x)
            seekstart(buff)
            img = load(Stream{DataFormat{Symbol($(uppercase(fmt)))}}(buff))
            image_pixel_height, image_pixel_width = size(img)
            try
                if dry_run
                    @debug "Saving $m representation of $(typeof(x)) object to $file (dry run)" image_pixel_width image_pixel_height
                else
                    @debug "Saving $m representation of $(typeof(x)) object to $file" image_pixel_width image_pixel_height
                    save(file, img)
                end
            catch exc
                @debug "Failed to display on $(typeof(d))" exception = exc
                throw(MethodError(Base.display, (d, x)))
                # fall back to another display
            end
            if (title == "") && use_filenames_as_title
                title = filename
            end
            push!(d.files, (file, title, (image_pixel_width, image_pixel_height)))
            if d.only_write_files
                if (title == filename) || (title == "")
                    println("[$file]")
                else
                    println("[$file: $title]")
                end
            else
                display_files(
                    d;
                    clear,
                    nrows,
                    redraw_previous,
                    imgcat,
                    smart_size,
                    target_pane,
                    cell_size,
                    sleep_secs,
                    scale,
                    dry_run
                )
            end
            return nothing
        end

        Base.displayable(::AbstractMuxDisplay, ::MIME{Symbol($mime)}) = true

    end
end


Base.displayable(::AbstractMuxDisplay, ::MIME) = false


function Base.display(d::AbstractMuxDisplay, @nospecialize(x))
    for mime in MIMES
        if showable(mime, x)
            return Base.display(d, mime, x)
        end
    end
    throw(MethodError(Base.display, (d, x)))
end


# display pending files(s)
function display_files(
    d::AbstractMuxDisplay;
    clear = d.clear,
    nrows = d.nrows,
    redraw_previous = d.redraw_previous,
    imgcat = d.imgcat,
    smart_size = d.smart_size,
    target_pane = d.target_pane,
    cell_size = d.cell_size,
    sleep_secs = d.sleep_secs,
    scale = d.scale,
    dry_run = d.dry_run,
)
    cell_height, cell_width = cell_size
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
    for i = a:b
        file, title, (image_pixel_width, image_pixel_height) = d.files[i]
        has_title = (length(title) > 0)
        height::Int64 = (pane_height ÷ nrows) - 2
        if has_title
            height = height - (textwidth(title) ÷ pane_width)
        end
        width_str = string(width)
        height_str = string(height)
        if smart_size && !dry_run
            if (cell_width > 0) && (cell_height > 0)
                area_pixel_width = width * cell_width
                area_pixel_height = height * cell_height
                width_scale = area_pixel_width / image_pixel_width
                projected_height =
                    ceil(Int64, (width_scale * image_pixel_height) / cell_height)
                @debug "Applying smart size" area_pixel_width area_pixel_height width_scale projected_height height width
                if projected_height > height
                    @debug "Using `width=\"auto\"` because projected_height  > height"
                    width_str = "auto"
                end
            else
                @debug "Skip smart_size for unknown cell size = $(cell_size)"
            end
        end
        cmd_str = replace(
            imgcat,
            "{file}" => file,
            "{width}" => width_str,
            "{height}" => height_str,
            "{pixel_width}" => string(Int(round(scale * image_pixel_width))),
            "{pixel_height}" => string(Int(round(scale * image_pixel_height))),
        )
        if has_title
            cmd_str = Base.shell_escape("echo", title) * "; " * cmd_str
        end
        send_cmd(d, cmd_str)
        if sleep_secs > 0
            @debug "Sleep for $sleep_secs secs"
            dry_run || sleep(sleep_secs)
        end
    end
    if requires_switching(d)
        select_pane(d, current_pane)
    end
end
