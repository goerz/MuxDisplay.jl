# imgcat = "wezterm imgcat --height {height} '{file}'"
# imgcat = "wezterm imgcat --height {height} --width {width} '{file}'"
# imgcat = "wezterm imgcat '{file}'"
# imgcat = "imgcat -H {height} -W {width} '{file}'; tput cud {height}"
# imgcat = "imgcat -H {height} '{file}'; tput cud {height}"

# Using tput:
#  move up (`tput cuu [N]`), move down (`tput cud [N]`), move right (`tput cuf [N]`), move left (`tput cub [N]`).


function find_imgcat(multiplexer, target_pane, nrows, clear, redraw_previous)
    wezterm = Sys.which("wezterm")
    imgcat = Sys.which("imgcat")
    tput = Sys.which("tput")
    result = ""
    if wezterm ≢ nothing
        if nrows > 1
            result = "wezterm imgcat --height {height} '{file}'"
        else
            # TODO: The --height actually has no effect if --width is given
            # In he long run, we'll have to be smarter about this, but that
            # probably implies supporting "auto", and sending "auto" depending
            # on how the pixel dimensions of the image compare to the pixel
            # dimension of the terminal (based on cell_dimensions)
            result = "wezterm imgcat --height {height} --width {width} '{file}'"
        end
    elseif imgcat ≢ nothing
        if nrows > 1
            result = "imgcat -H {height} '{file}'"
        else
            # TODO: The -W has no effect, see above
            result = "imgcat -H {height} -W {width} '{file}'"
        end
        if (multiplexer == :tmux) && (tput ≢ nothing)
            result *= "; tput cud {height}"
        end
    else
        @error "Could not determine an `imgcat` program. Please supply `imgcat` manually."
    end
    if result == ""
        throw(ArgumentError("Invalid `imgcat`"))
    else
        @debug "Using imgcat=$(repr(result))"
    end
    return result
end
