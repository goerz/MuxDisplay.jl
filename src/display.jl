using Printf: @sprintf
using FileIO: save

const MIMES = ("image/png", "image/jpeg")
const FORMATS = ("png", "jpg")


# Required fields:
# - tmpdir
# - files
# - only_write_files
# - imgcat_cmd
abstract type AbstractMultiplexerPaneDisplay <: AbstractDisplay end


# show pending file(s) in pane
function display_files end


# send a command to the target pane and press Enter
function send_cmd end



for (mime, fmt) in zip(MIMES, FORMATS)
    @eval begin
        function Base.display(
            d::AbstractMultiplexerPaneDisplay,
            m::MIME{Symbol($mime)},
            @nospecialize(x)
        )
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
                throw(MethodError(display, (d, x)))
                # fall back to another display
            end
            push!(d.files, file)
            if d.only_write_files
                println("[$file]")
            else
                display_files(d)
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
            return display(d, mime, x)
        end
    end
    throw(MethodError(display, (d, x)))
end
