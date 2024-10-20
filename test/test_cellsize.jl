using Test
using MuxDisplay: MuxDisplay, install_cellsize, _is_exe as is_exe
using IOCapture: IOCapture

@testset "Install cellsize" begin
    if isnothing(Sys.which("cc"))
        @warn "No cc compiler available. Not testing install_cell_size."
    else
        tmpdir = mktempdir()
        c = IOCapture.capture(passthrough = false) do
            withenv("JULIA_DEBUG" => MuxDisplay) do
                install_cellsize(tmpdir)
            end
        end
        @test contains(c.output, "Compiling `cellsize`")
        @test contains(c.output, "Successfully generated executable")
        @test contains(c.output, "may not be in your PATH")
        @test is_exe(joinpath(tmpdir, "cellsize"))
    end
end

@testset "No c compiler" begin
    tmpdir = mktempdir()
    c = IOCapture.capture(passthrough = false) do
        withenv("PATH" => "", "JULIA_DEBUG" => MuxDisplay) do
            install_cellsize(tmpdir; cc = "ccompiler")
        end
    end
    @test contains(c.output, "The C compiler \"ccompiler\" is not available")
end


@testset "Write cellsize source" begin
    tmpdir = mktempdir()
    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => MuxDisplay) do
            install_cellsize(tmpdir; write_source = true)
        end
    end
    @test contains(c.output, "Writing cellsize src")
    @test !is_exe(joinpath(tmpdir, "cellsize"))
    @test isfile(joinpath(tmpdir, "cellsize.c"))
end
