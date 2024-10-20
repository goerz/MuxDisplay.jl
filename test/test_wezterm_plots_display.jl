using Test
using MuxDisplay
using IOCapture: IOCapture
using Logging
using Plots


@testset "WezTerm Plots dry run" begin

    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => MuxDisplay, "GKSwstype" => "100") do
            MuxDisplay.enable(
                multiplexer = :wezterm,
                target_pane = "1",
                tmpdir = ".",
                nrows = 1,
                dry_run = true,
                use_filenames_as_title = true,
                imgcat = "imgcat -H {height} -W {width} '{file}'"
            )
            fig1 = scatter(rand(100))
            display(fig1)
            fig2 = scatter(rand(100))
            display(fig2)
            MuxDisplay.set_options(;
                nrows = 2,
                redraw_previous = 1,
                use_filenames_as_title = false,
            )
            display(fig2)
            MuxDisplay.disable()
        end
    end
    expected_lines = [
        # Activation
        "Activating WezTermPaneDisplay for 1 row(s) using wezterm target 1 (dry run)",
        # Initializing the pane
        "`wezterm cli send-text --no-paste --pane-id 1` (dry run)",
        "PS1=''",
        "stty -echo",
        "clear",
        # Showing fig1
        "Saving image/png representation of Plots.Plot{Plots.GRBackend} object",
        "001.png",
        "wezterm cli list --format json",
        "echo 001.png; imgcat -H 22 -W 78 './001.png'",
        # Showing fig2
        "002.png",
        "echo 002.png; imgcat -H 22 -W 78 './002.png'",
        # Set options
        "Info: Updating display to WezTermPaneDisplay for 2 row(s) using wezterm target 1 (redraw previous 1, dry run)",
        # Re-showing fig2
        "Saving image/png representation of Plots.Plot{Plots.GRBackend} object to ./003.png (dry run)",
        "imgcat -H 10 -W 78 './003.png'",
        # Deactivation
        "Deactivating WezTermPaneDisplay",
        "PS1='> '",
        "stty echo",
    ]
    for line in expected_lines
        res = @test contains(c.output, line)
        if res isa Test.Fail
            @error "Test failure" line
            if isdefined(Main, :Infiltrator)
                Main.infiltrate(@__MODULE__, Base.@locals, @__FILE__, @__LINE__)
            end
        end
    end

end


@testset "WezTerm Plots dummy binary" begin

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
                multiplexer = :wezterm,
                mux_bin = joinpath(@__DIR__, "bin", "wezterm.sh"),
                tmpdir,
                target_pane = "1",
                nrows = 1,
                use_filenames_as_title = true,
                imgcat = joinpath(@__DIR__, "bin", "imgcat.sh") *
                         " -W {width} -H {height} '{file}'",
            )
            fig1 = scatter(rand(100))
            display(fig1)
            fig2 = scatter(rand(100))
            display(fig2)
            d = Base.Multimedia.displays[end]
            MuxDisplay.disable()
            return d
        end
    end
    # The wezterm.sh dummy script checks that it receives only expected input.
    # So running through without an error is a strong test.
    @test contains(c.output, "Set display cell_size = (20, 10)")

    @test c.value isa MuxDisplay.WezTerm.WezTermPaneDisplay
    tmpdir = c.value.tmpdir
    @test isfile(joinpath(tmpdir, "001.png"))
    @test isfile(joinpath(tmpdir, "002.png"))

end
