using Test
using MultiplexerPaneDisplay: MultiplexerPaneDisplay, find_imgcat
using IOCapture: IOCapture
using Logging
using Plots


function write_binary(folder, name)
    file_path = joinpath(folder, name)
    open(file_path, "w") do f
        write(f, "#!/bin/bash\n")
    end
    chmod(file_path, 0o755)  # make the resulting file executable
end


@testset "No imgcat" begin
    c = IOCapture.capture(passthrough = false, rethrow = Union{}) do
        withenv("PATH" => "") do
            imgcat = find_imgcat(:tmux, "0", 24, true, false)
        end
    end
    @test contains(c.output, "Could not determine an `imgcat` program")
    @test c.error
    @test c.value isa ArgumentError
end


@testset "Automatic imgcat" begin

    path_dir = mktempdir()
    write_binary(path_dir, "wezterm")
    write_binary(path_dir, "imgcat")
    write_binary(path_dir, "tput")

    nrows = 1
    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(:tmux, "0", nrows, true, false)
        end
    end
    imgcat = "wezterm imgcat --height {height} --width {width} '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

    nrows = 2
    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(:tmux, "0", nrows, true, false)
        end
    end
    imgcat = "wezterm imgcat --height {height} '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

end


@testset "No wezterm" begin

    path_dir = mktempdir()
    write_binary(path_dir, "imgcat")
    write_binary(path_dir, "tput")

    nrows = 1
    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(:tmux, "0", nrows, true, false)
        end
    end
    imgcat = "imgcat -H {height} -W {width} '{file}'; tput cud {height}"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

    nrows = 2
    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(:tmux, "0", nrows, true, false)
        end
    end
    imgcat = "imgcat -H {height} '{file}'; tput cud {height}"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")


    nrows = 1
    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(:wezterm, "0", nrows, true, false)
        end
    end
    imgcat = "imgcat -H {height} -W {width} '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

    nrows = 2
    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(:wezterm, "0", nrows, true, false)
        end
    end
    imgcat = "imgcat -H {height} '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

end
