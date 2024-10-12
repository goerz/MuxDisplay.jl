using Test
using MultiplexerPaneDisplay
using IOCapture: IOCapture
using Logging
using Plots

@testset "Tmux Plots dry run" begin

    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => MultiplexerPaneDisplay, "GKSwstype" => "100") do
            println("*** Activation")
            MultiplexerPaneDisplay.enable(
                multiplexer = :tmux,
                target_pane = "test:0.0",
                tmpdir = ".",
                nrows = 1,
                dry_run = true,
                use_filenames_as_title = true,
                imgcat = "imgcat -H {height} -W {width} '{file}'"
            )
            println("*** Figure 1")
            fig1 = scatter(rand(100))
            display(fig1)
            println("*** Figure 2")
            fig2 = scatter(rand(100))
            display(fig2)
            println("*** Set options")
            MultiplexerPaneDisplay.set_options(;
                nrows = 2,
                redraw_previous = 1,
                use_filenames_as_title = false
            )
            println("*** Reshow Figure 2")
            display(fig2)
            println("** Deactivation")
            MultiplexerPaneDisplay.disable()
        end
    end
    expected_lines = [
        # Activation
        "Activating TmuxPaneDisplay for 1 row(s) using tmux target test:0.0",
        # Initializing the pane
        "`tmux send-keys -t test:0.0 \"PS1=''\" Enter`",
        "`tmux send-keys -t test:0.0 'stty -echo' Enter`",
        "`tmux send-keys -t test:0.0 clear Enter`",
        raw"IFS=';' read -rs -d t -p \$'\e[16t' -a CELL_SIZE",
        raw"echo ${CELL_SIZE[1]}x${CELL_SIZE[2]} > ./cellsize",
        # Showing fig1
        "Saving image/png representation of Plots.Plot{Plots.GRBackend} object",
        "001.png",
        "`tmux display -p '#{pane_index}'` -> current pane <orig pane>",
        "`tmux select-pane -t test:0.0`",
        "`tmux send-keys -t test:0.0 clear Enter`",
        "`tmux display -p -t test:0.0 '#{pane_width}'` -> pane width 80",
        "`tmux display -p -t test:0.0 '#{pane_height}'` -> pane height 24",
        "`tmux send-keys -t test:0.0 \"echo 001.png; imgcat -H 22 -W 78 './001.png'\" Enter`",
        "`tmux select-pane -t '<orig pane>'`",
        # Showing fig2
        "002.png",
        "`tmux send-keys -t test:0.0 \"echo 002.png; imgcat -H 22 -W 78 './002.png'\" Enter`",
        # Set options
        "Info: Updating display to TmuxPaneDisplay for 2 row(s) using tmux target test:0.0 (redraw previous 1, dry run)",
        # Re-showing fig2
        "Saving image/png representation of Plots.Plot{Plots.GRBackend} object to ./003.png",
        "`tmux send-keys -t test:0.0 \"imgcat -H 10 -W 78 './003.png'\" Enter`",
        # Deactivation
        "Deactivating TmuxPaneDisplay",
        "`tmux send-keys -t test:0.0 \"PS1='> '\" Enter`",
        "`tmux send-keys -t test:0.0 'stty echo' Enter`",
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


@testset "Tmux Plots dummy binary" begin

    tmpdir = mktempdir()
    write(joinpath(tmpdir, "cellsize"), "20x10")
    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => MultiplexerPaneDisplay, "GKSwstype" => "100") do
            MultiplexerPaneDisplay.enable(;
                multiplexer = :tmux,
                mux_bin = joinpath(@__DIR__, "bin", "tmux.sh"),
                tmpdir,
                target_pane = "test:0.0",
                nrows = 1,
                smart_size = false,
                use_filenames_as_title = true,
                imgcat = joinpath(@__DIR__, "bin", "imgcat.sh") *
                         " -W {width} -H {height} '{file}'",
            )
            fig1 = scatter(rand(100))
            display(fig1)
            fig2 = scatter(rand(100))
            display(fig2)
            d = Base.Multimedia.displays[end]
            MultiplexerPaneDisplay.disable()
            return d
        end
    end
    # The tmux.sh dummy script checks that it receives only expected input.
    # So running through without an error is a strong test.
    @test contains(c.output, "Set display cell_size = (20, 10)")

    @test c.value isa MultiplexerPaneDisplay.Tmux.TmuxPaneDisplay
    tmpdir = c.value.tmpdir
    @test isfile(joinpath(tmpdir, "001.png"))
    @test isfile(joinpath(tmpdir, "002.png"))

end


@testset "Cellsize failure" begin

    tmpdir = mktempdir()
    # Do not write a cellsize file in tmpdir. This leads to a "No such file or
    # directory" error
    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => MultiplexerPaneDisplay, "GKSwstype" => "100") do
            MultiplexerPaneDisplay.enable(;
                multiplexer = :tmux,
                mux_bin = joinpath(@__DIR__, "bin", "tmux.sh"),
                tmpdir,
                target_pane = "test:0.0",
                nrows = 1,
                use_filenames_as_title = true,
                cell_size_timeout = 0.0,
                imgcat = joinpath(@__DIR__, "bin", "imgcat.sh") *
                         " -W {width} -H {height} '{file}'",
            )
            MultiplexerPaneDisplay.disable()
        end
    end
    @test contains(c.output, "Cannot determine terminal cell size")

end
