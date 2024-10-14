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
        withenv("PATH" => "", "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(;
                multiplexer = :tmux,
                nrows = 24,
                smart_size = false,
                use_pixels = false
            )
        end
    end
    @test c.error
    @test c.value isa ArgumentError
    @test contains(c.output, "Could not determine an `imgcat` program")
end


@testset "Automatic imgcat" begin

    path_dir = mktempdir()
    write_binary(path_dir, "wezterm")
    write_binary(path_dir, "imgcat")
    write_binary(path_dir, "tput")

    smart_size = false
    use_pixels = false
    multiplexer = :tmux

    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(; multiplexer, nrows = 1, smart_size, use_pixels)
        end
    end
    imgcat = "wezterm imgcat --height {height} --width {width} '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(; multiplexer, nrows = 2, smart_size, use_pixels)
        end
    end
    imgcat = "wezterm imgcat --height {height} '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(; multiplexer, nrows = 2, smart_size, use_pixels = true)
        end
    end
    imgcat = "wezterm imgcat --height {pixel_height}px --width {pixel_width}px '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

end


@testset "No wezterm" begin

    path_dir = mktempdir()
    write_binary(path_dir, "imgcat")
    write_binary(path_dir, "tput")

    smart_size = false
    use_pixels = false

    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(; multiplexer = :tmux, nrows = 1, smart_size, use_pixels)
        end
    end
    imgcat = "imgcat -H {height} -W {width} '{file}'; tput cud {height}"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(; multiplexer = :tmux, nrows = 2, smart_size, use_pixels)
        end
    end
    imgcat = "imgcat -H {height} '{file}'; tput cud {height}"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")


    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat =
                find_imgcat(; multiplexer = :wezterm, nrows = 1, smart_size, use_pixels)
        end
    end
    imgcat = "imgcat -H {height} -W {width} '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat =
                find_imgcat(; multiplexer = :wezterm, nrows = 2, smart_size, use_pixels)
        end
    end
    imgcat = "imgcat -H {height} '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => path_dir, "JULIA_DEBUG" => MultiplexerPaneDisplay) do
            imgcat = find_imgcat(;
                multiplexer = :wezterm,
                nrows = 2,
                smart_size,
                use_pixels = true
            )
        end
    end
    imgcat = "imgcat -H {pixel_height}px -W {pixel_width}px '{file}'"
    @test c.value == imgcat
    @test contains(c.output, "Debug: Using imgcat=$(repr(imgcat))")

end
