using Test
using MuxDisplay
using IOCapture: IOCapture
using Logging
using Plots

@testset "display with title" begin

    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => MuxDisplay, "GKSwstype" => "100") do
            println("*** Enable")
            MuxDisplay.enable(
                multiplexer = :tmux,
                target_pane = "test:0.0",
                tmpdir = ".",
                nrows = 1,
                dry_run = true,
                use_filenames_as_title = true,
                clear = true,
                redraw_previous = true,
                imgcat = "imgcat -H {height} -W {width} '{file}'"
            )
            println("*** Fig 1")
            fig1 = scatter(rand(100))
            MuxDisplay.display(fig1; title = "first plot")
            println("*** Fig 2")
            fig2 = scatter(rand(100))
            MuxDisplay.display(fig2; title = "second plot")
            println("*** Fig 1 with options")
            MuxDisplay.display(
                fig1;
                title = "first plot (with options)",
                clear = true,
                nrows = 2,
                redraw_previous = false,
                imgcat = "imgcat -H {height} '{file}'"
            )
            println("*** Fig 2 with options")
            MuxDisplay.display(
                fig2;
                title = "second plot (with options)",
                clear = false,
                nrows = 2,
                redraw_previous = false,
                imgcat = "imgcat -H {height} '{file}'"
            )
            println("*** Fig 1 with default title")
            MuxDisplay.display(fig1)
            println("*** Fig 2 with no title")
            MuxDisplay.display(fig2, use_filenames_as_title = false)
            println("*** Fig 2 with empty title (filename default kicks in)")
            MuxDisplay.display(fig2, title = "")
            println("*** Disable")
            MuxDisplay.disable()
        end
    end
    expected_lines = [
        "echo 'first plot'; imgcat -H 22 -W 78 './001.png'",
        "echo 'second plot'; imgcat -H 22 -W 78 './002.png'",
        "echo 'first plot (with options)'; imgcat -H 10 './003.png'",
        "echo 'second plot (with options)'; imgcat -H 10 './004.png'",
        "echo 005.png; imgcat -H 22 -W 78 './005.png'",
        "\"imgcat -H 22 -W 78 './006.png'\"",  # no echo
        "echo 007.png; imgcat -H 22 -W 78 './007.png'",
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
