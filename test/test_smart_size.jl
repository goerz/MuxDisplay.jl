using Test
using MuxDisplay
using IOCapture: IOCapture
using Logging
using Plots
using ImageMagick


function get_image_dimensions(filename)
    w, h = ImageMagick.metadata(filename)[1]
    return (w, h)
end


@testset "Tmux smart-size" begin
    tmpdir = mktempdir()
    write(joinpath(tmpdir, "cellsize"), "20x10")
    path_dirs = Set((dirname(Sys.which("cat")), dirname(Sys.which("sed"))))
    c = IOCapture.capture(passthrough = false) do
        withenv(
            "PATH" => join(path_dirs, ":"),
            "JULIA_DEBUG" => MuxDisplay,
            "GKSwstype" => "100"
        ) do
            MuxDisplay.enable(;
                multiplexer = :tmux,
                mux_bin = joinpath(@__DIR__, "bin", "tmux.sh"),
                tmpdir,
                target_pane = "test:0.0",
                nrows = 2,
                use_filenames_as_title = true,
                smart_size = true,
                shell = "bash",
                imgcat = joinpath(@__DIR__, "bin", "imgcat.sh") *
                         " -W {width} -H {height} '{file}'",
            )
            fig1 = scatter(rand(100); size = (600, 200))
            display(fig1)
            fig2 = scatter(rand(100); size = (400, 900))  # higher than wide
            display(fig2)
            d = Base.Multimedia.displays[end]
            MuxDisplay.disable()
            return d
        end
    end
    # The tmux.sh dummy script checks that it receives only expected input.
    # So running through without an error is a strong test.
    @test contains(c.output, "Set display cell_size = (20, 10)")
    @test contains(c.output, "pane width 100") # see dummy...
    @test contains(c.output, "pane height 30") # ... tmux.sh
    @test contains(c.output, "Using `width=\"auto\"` because projected_height  > height")

    @test c.value isa MuxDisplay.Tmux.TmuxPaneDisplay
    tmpdir = c.value.tmpdir

    file1 = joinpath(tmpdir, "001.png")
    @test isfile(file1)
    w, h = get_image_dimensions(file1)
    @test 595 < w < 605
    @test 195 < h < 205
    contains(c.output, r"imgcat.sh -W 98 -H 13 .*001.png")

    file2 = joinpath(tmpdir, "002.png")
    @test isfile(file2)
    w, h = get_image_dimensions(file2)
    @test 395 < w < 405
    @test 895 < h < 905
    contains(c.output, r"imgcat.sh -W auto -H 13 .*002.png")

end
