# TODO: Detect the shell: https://stackoverflow.com/questions/3327013/how-to-determine-the-current-interactive-shell-that-im-in-command-line
# TODO: ZSH: https://unix.stackexchange.com/questions/343088/what-is-the-equivalent-of-stty-echo-for-zsh
# Ask tmux: tmux display -t 1 -p "#{pane_current_command}"
# for WezTerm: get it from the info json

const INITIALIZE = Dict{String,Vector{String}}(
    "bash" => ["stty -echo"],
    "zsh" => ["unsetopt ZLE", "stty -echo"],
)

const RESTORE = Dict{String,Vector{String}}(
    "bash" => ["stty echo"],
    "zsh" => ["stty echo", "setopt ZLE"],
)


function disable_prompt(shell::Val, display)
    @debug "Disabling prompt in target pane $(display.target_pane) for shell $shell"
    send_cmd(display, "PS1=''")
    return nothing
end


function restore_prompt(shell::Val, display)
    @debug "Re-enabling prompt in target pane $(display.target_pane) for shell $shell"
    if haskey(display.env, "PS1")
        cmd = "PS1=$(Base.shell_escape(display.env["PS1"]))"
        send_cmd(display, cmd)
    else
        @debug "Could not restore original prompt: no PS1 in display.env"
        send_cmd(display, "PS1='> '")
    end
    return nothing
end


function initialize_target_pane!(display)
    if display.shell == ""
        display.shell = get_shell(display)
    end
    if haskey(INITIALIZE, display.shell)
        set_env!(display)
        disable_prompt(Val(Symbol(display.shell)), display)
        for cmd in INITIALIZE[display.shell]
            send_cmd(display, cmd)
        end
        if display.cell_size == (0, 0)
            set_cell_size!(display)
        end
        send_cmd(display, "clear")
    else
        @error "Unknown shell $(repr(display.shell)): Switching to dry-run."
        display.dry_run = true
    end
    return nothing
end


function set_env!(display)
    empty!(display.env)
    try
        printenv_file = joinpath(display.tmpdir, "printenv")
        cmd = "printenv > $printenv_file"
        send_cmd(display, cmd)
        if !display.dry_run
            sleep(2 * display.sleep_secs)  # wait for file to be written
            env_keys = Set(("PS1",))
            for line in readlines(printenv_file)
                try
                    key, value = split(line, "="; limit = 2)
                    if key ∈ env_keys
                        display.env[key] = value
                    end
                catch
                    # Skip over multiline values for now.
                    # TODO: people might set PS1 to a multiline string, and
                    # we'll have to handle that properly
                    continue
                end
            end
            @debug "Set `display.env` from $(repr(printenv_file))" display.env
        end
    catch exception
        @warn "Cannot determine environment (printenv)" exception
    end
    return nothing
end


const CELLSIZE_C_SRC = raw"""
//  Adapted from
//  https://sw.kovidgoyal.net/kitty/graphics-protocol/#getting-the-window-size
//
//  Compile with
//
//      cc -o cellsize cellsize.c
//
#include <stdio.h>
#include <sys/ioctl.h>
#include <stdlib.h>


//  Usage:
//
//      cellsize OUTFILE
//
//  writes the pixel size of a cell (character) to OUTFILE in the format
//  "HEIGHTxWIDTH", where HEIGHT and WIDTH are integers. If called without
//  OUTFILE, write to stdout.
int main(int argc, char **argv) {
    struct winsize sz;
    ioctl(0, TIOCGWINSZ, &sz);
    int cell_width = sz.ws_xpixel / sz.ws_col;
    int cell_height = sz.ws_ypixel / sz.ws_row;
    FILE *output = stdout;
    if (argc > 1) {
        output = fopen(argv[1], "w");
        if (!output) {
            perror("Error opening file");
            return 1;
        }
    }
    fprintf(output, "%ix%i\n", cell_height, cell_width);
    if (output != stdout) {
        fclose(output);
    }
    return 0;
}
"""


"""Compile the `cellsize` program from C-source

```julia
install_cellsize(path="~/bin"; cc="cc", write_source=false)
```

produces the executable `cellsize` inside the given `path` folder by compiling
C source with the `cc` compiler.

The resulting executable can be called as

```
cellsize OUTFILE
```

and writes the pixel size of a cell (character) to `OUTFILE` in the format
`HEIGHTxWIDTH`, where `HEIGHT` and `WIDTH` are integers. If called without
`OUTFILE`, write to stdout.


If `write_source` is given as `true`, write the C source code for the
`cellsize` executable to `cellsize.c` inside `path`, but do not compile it.
"""
function install_cellsize(
    path = joinpath(ENV["HOME"], "bin");
    cc = "cc",
    write_source = false
)
    path = abspath(path)
    mkpath(path)
    c_file = joinpath(path, "cellsize.c")
    bin_file = joinpath(path, "cellsize")
    if _is_exe(bin_file) && !write_source
        @info "$bin_file already exists"
        return bin_file
    else
        @debug "Writing cellsize src to $(repr(c_file))"
        write(c_file, CELLSIZE_C_SRC)
        if write_source
            return c_file
        else
            if !(path in split(ENV["PATH"], ":"))
                @warn "The specified path=$(repr(path)) to install `cellsize` in may not be in your PATH=$(ENV["PATH"])"
            end
            if isnothing(Sys.which(cc))
                @error "The C compiler $(repr(cc)) is not available. Cannot compile `cellsize`."
            else
                cmd = `$cc -o $bin_file $c_file`
                @info "Compiling `cellsize` with $cmd"
                run(cmd)
                if _is_exe(bin_file)
                    @info "Successfully generated executable $bin_file"
                else
                    error("Failed to generate executable $bin_file")
                end
            end
            @debug "Removing $c_file"
            rm(c_file)
            return bin_file
        end
    end
end


function _is_exe(file)
    isfile(file) || (return false)
    mode = stat(file).mode
    return (mode & 0o111) != 0
end



function set_cell_size!(display)
    h, w = display.cell_size
    try
        cellsize_bin = Sys.which("cellsize")
        cellsize_file = joinpath(display.tmpdir, "cellsize")
        if isnothing(cellsize_bin)
            @warn "The `cellsize` executable is not available. It is strongly recommend it that you install it with `MuxDisplay.install_cellsize(path; cc=\"cc\")`, where `path` is a folder in your PATH (e.g., `~/bin`). This requires the C compiler `cc`."
            if display.shell != "bash"
                @warn "Obtaining cell size via bash `read` command. This will likely fail in a non-bash shell"
            end
            cmd = raw"IFS=';' read -rs -d t -p $'\e[16t' -a CELL_SIZE"
            send_cmd(display, cmd)
            sleep(2 * display.sleep_secs)
            cmd = "echo \${CELL_SIZE[1]}x\${CELL_SIZE[2]} > $cellsize_file"
            send_cmd(display, cmd)
        else
            send_cmd(display, "$cellsize_bin $cellsize_file")
        end
        if display.dry_run
            @debug "Set display cell_size = ($h, $w) (dry run)"
        else
            sleep(2 * display.sleep_secs)  # wait for file to be written
            h, w = parse.(Int64, split(read(cellsize_file, String), "x"))
            @debug "Set display cell_size = ($h, $w)"
        end
    catch exception
        @warn "Cannot determine terminal cell size" exception display.cell_size
    end
    display.cell_size = (h, w)
    return nothing
end


function restore_target_pane(display)
    restore_prompt(Val(Symbol(display.shell)), display)
    if haskey(RESTORE, display.shell)
        for cmd in RESTORE[display.shell]
            send_cmd(display, cmd)
        end
        send_cmd(display, "clear")
    else
        @debug "Skipping restore: unknown shell $(repr(display.shell))"
    end
    return nothing
end
