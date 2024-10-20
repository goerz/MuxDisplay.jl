using Test
using MuxDisplay
using IOCapture: IOCapture
using Logging
using Plots
import MuxDisplay: initialize_target_pane!, restore_target_pane
using MuxDisplay:
    send_cmd, get_pane_dimensions, requires_switching, get_current_pane, select_pane


mutable struct DummyDisplay <: MuxDisplay.AbstractMuxDisplay
    target_pane::String
    tmpdir::String
    clear::Bool
    nrows::Int64
    redraw_previous::Int64
    imgcat::String
    dry_run::Bool
    use_filenames_as_title::Bool
    smart_size::Bool
    scale::Float64
    sleep_secs::Float64
    cell_size::Tuple{Int64,Int64}
    only_write_files::Bool
    files::Vector{Tuple{String,String,Tuple{Int64,Int64}}}
    # (absolute file name, title, (width, height))
end


function DummyDisplay(;
    target_pane = "",
    imgcat = "",
    tmpdir = mktempdir(),
    dry_run = false,
    only_write_files = true,
    smart_size = true,
    scale = 1.0,
    sleep_secs = 0.0,
    cell_size = (0, 0),
    files = [],
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
        smart_size,
        scale,
        sleep_secs,
        cell_size,
        only_write_files,
        files,
    )
end

function initialize_target_pane!(::DummyDisplay) end

function restore_target_pane(::DummyDisplay) end


@testset "Dummy Display interface" begin

    c = IOCapture.capture(passthrough = false) do
        MuxDisplay.enable(;
            imgcat = "imgcat",
            target_pane = "",
            _display_type = DummyDisplay,
            only_write_files = true,
        )
        MuxDisplay.enabled(; verbose = true)
        MuxDisplay.disable(; verbose = true)
        MuxDisplay.enabled(; verbose = true)
    end
    @test contains(c.output, "Info: Activating")
    @test contains(c.output, "Info: Active")
    @test contains(c.output, "Info: Deactivating")

    MuxDisplay.enable(;
        imgcat = "imgcat",
        target_pane = "",
        _display_type = DummyDisplay,
        only_write_files = true,
        verbose = false
    )
    @test MuxDisplay.enabled(; verbose = false)
    d = Base.Multimedia.displays[end]
    @test_throws MethodError send_cmd(d, "clear")
    @test_throws MethodError get_pane_dimensions(d, "0")
    @test requires_switching(d) == false
    @test_throws MethodError get_current_pane(d)
    @test_throws MethodError select_pane(d, "0")
    MuxDisplay.disable(; verbose = false)
    @test !MuxDisplay.enabled(; verbose = false)



end


@testset "Only write files with DummyDisplay" begin
    tmpdir = mktempdir()
    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => MuxDisplay, "GKSwstype" => "100") do
            println("*** Activation")
            MuxDisplay.enable(;
                imgcat = "imgcat",
                target_pane = "",
                _display_type = DummyDisplay,
                only_write_files = true,
                tmpdir = tmpdir,
            )
            @assert MuxDisplay.enabled()
            println("*** Figure 1")
            fig1 = scatter(rand(100))
            display(fig1)
            println("*** Figure 2")
            fig2 = scatter(rand(100))
            display(fig2)
            println("*** Figure 2 with title")
            MuxDisplay.display(fig2; title = "Figure 2 (again)")
            println("*** Set to dry run")
            MuxDisplay.set_options(dry_run = true)
            MuxDisplay.display(fig2; title = "Figure 2 (dry run)")
            println("** Deactivation")
            MuxDisplay.disable()
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
