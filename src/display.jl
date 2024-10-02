using Printf: @sprintf
using FileIO: save

const MIMES = ("image/png", "image/jpeg")
const FORMATS = ("png", "jpg")

struct _TmuxPaneDisplay <: AbstractDisplay
    target_pane::String
    tmpdir::String
    imgcat_cmd::String
    tmux_cmd::String
    nrows::Int64
    dry_run::Bool
    only_write_files::Bool
    echo_filename::Bool
    clear::Bool
    sleep_secs::Float64
    files::Vector{String}  # Absolute paths of generated files
end


for (mime, fmt) in zip(MIMES, FORMATS)
    @eval begin
        function Base.display(d::_TmuxPaneDisplay, m::MIME{Symbol($mime)}, @nospecialize(x))
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
                n_show = min(d.nrows, length(d.files))
                files = d.files[end-(n_show-1):end]
                display_files(
                    d.target_pane,
                    d.imgcat_cmd,
                    d.tmux_cmd,
                    files;
                    nrows = d.nrows,
                    echo_filename = d.echo_filename,
                    clear = d.clear,
                    dry_run = d.dry_run,
                    sleep_secs = d.sleep_secs,
                )
            end
            return nothing
        end
        Base.displayable(::_TmuxPaneDisplay, ::MIME{Symbol($mime)}) = true
    end
end


Base.displayable(::_TmuxPaneDisplay, ::MIME) = false


function Base.display(d::_TmuxPaneDisplay, @nospecialize(x))
    for mime in MIMES
        if showable(mime, x)
            return display(d, mime, x)
        end
    end
    throw(MethodError(display, (d, x)))
end
