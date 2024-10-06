using Test
using MultiplexerPaneDisplay
using IOCapture: IOCapture
using Logging
using Plots
import MultiplexerPaneDisplay: initialize_target_pane, restore_target_pane
using MultiplexerPaneDisplay:
    send_cmd, get_pane_dimensions, requires_switching, get_current_pane, select_pane


struct DummyDisplay <: MultiplexerPaneDisplay.AbstractMultiplexerPaneDisplay
    target_pane::String
    tmpdir::String
    clear::Bool
    nrows::Int64
    redraw_previous::Int64
    imgcat::String
    dry_run::Bool
    use_filenames_as_title::Bool
    only_write_files::Bool
    files::Vector{String}  # Absolute paths of generated files
    titles::Vector{String}  # Title for each file
end


function DummyDisplay(;
    target_pane = "",
    imgcat = "",
    tmpdir = mktempdir(),
    dry_run = false,
    only_write_files = true,
    files = String[],
    titles = String[],
    kwargs...
)
    DummyDisplay(
        target_pane,
        tmpdir,
        false,
        1,
        0,
        imgcat,
        dry_run,
        false,
        only_write_files,
        files,
        titles
    )
end

function initialize_target_pane(::DummyDisplay) end

function restore_target_pane(::DummyDisplay) end


@testset "Dummy Display interface" begin

    c = IOCapture.capture(passthrough = false) do
        MultiplexerPaneDisplay.enable(;
            imgcat = "imgcat",
            target_pane = "",
            _display_type = DummyDisplay
        )
        MultiplexerPaneDisplay.enabled(; verbose = true)
        MultiplexerPaneDisplay.disable(; verbose = true)
        MultiplexerPaneDisplay.enabled(; verbose = true)
    end
    @test contains(c.output, "Info: Activating")
    @test contains(c.output, "Info: Active")
    @test contains(c.output, "Info: Deactivating")

    MultiplexerPaneDisplay.enable(;
        imgcat = "imgcat",
        target_pane = "",
        _display_type = DummyDisplay,
        verbose = false
    )
    @test MultiplexerPaneDisplay.enabled(; verbose = false)
    d = Base.Multimedia.displays[end]
    @test_throws MethodError send_cmd(d, "clear")
    @test_throws MethodError get_pane_dimensions(d, "0")
    @test requires_switching(d) == false
    @test_throws MethodError get_current_pane(d)
    @test_throws MethodError select_pane(d, "0")
    MultiplexerPaneDisplay.disable(; verbose = false)
    @test !MultiplexerPaneDisplay.enabled(; verbose = false)



end


@testset "Only write files with DummyDisplay" begin
    tmpdir = mktempdir()
    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => MultiplexerPaneDisplay, "GKSwstype" => "100") do
            println("*** Activation")
            MultiplexerPaneDisplay.enable(;
                imgcat = "imgcat",
                target_pane = "",
                _display_type = DummyDisplay,
                tmpdir = tmpdir,
            )
            @assert MultiplexerPaneDisplay.enabled()
            println("*** Figure 1")
            fig1 = scatter(rand(100))
            display(fig1)
            println("*** Figure 2")
            fig2 = scatter(rand(100))
            display(fig2)
            println("*** Figure 2 with title")
            MultiplexerPaneDisplay.display(fig2; title = "Figure 2 (again)")
            println("*** Set to dry run")
            MultiplexerPaneDisplay.set_options(dry_run = true)
            MultiplexerPaneDisplay.display(fig2; title = "Figure 2 (dry run)")
            println("** Deactivation")
            MultiplexerPaneDisplay.disable()
        end
    end
    expected_lines = [
        "[$(joinpath(tmpdir, "001.png"))]",
        "[$(joinpath(tmpdir, "002.png"))]",
        "[$(joinpath(tmpdir, "003.png")): Figure 2 (again)]",
        "[$(joinpath(tmpdir, "004.png")): Figure 2 (dry run)]",
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
    @test isfile(joinpath(tmpdir, "001.png"))
    @test isfile(joinpath(tmpdir, "002.png"))
    @test isfile(joinpath(tmpdir, "003.png"))
    @test !isfile(joinpath(tmpdir, "004.png"))
end
