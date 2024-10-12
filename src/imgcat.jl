# imgcat = "wezterm imgcat --height {height} '{file}'"
# imgcat = "wezterm imgcat --height {height} --width {width} '{file}'"
# imgcat = "wezterm imgcat '{file}'"
# imgcat = "imgcat -H {height} -W {width} '{file}'; tput cud {height}"
# imgcat = "imgcat -H {height} '{file}'; tput cud {height}"

# Using tput:
#  move up (`tput cuu [N]`), move down (`tput cud [N]`), move right (`tput cuf [N]`), move left (`tput cub [N]`).


function find_imgcat(multiplexer, target_pane, nrows, clear, redraw_previous, smart_size)
    wezterm = Sys.which("wezterm")
    imgcat = Sys.which("imgcat")
    tput = Sys.which("tput")
    result = ""
    if wezterm ≢ nothing
        if !smart_size && (nrows > 1)
            result = "wezterm imgcat --height {height} '{file}'"
        else
            result = "wezterm imgcat --height {height} --width {width} '{file}'"
        end
    elseif imgcat ≢ nothing
        if !smart_size && (nrows > 1)
            result = "imgcat -H {height} '{file}'"
        else
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
