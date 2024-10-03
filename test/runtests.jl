using Test
using SafeTestsets

# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "MultiplexerPaneDisplay" begin

    println("\n* Plots Display")
    @time @safetestset "test_plots_display" begin
        include("test_plots_display.jl")
    end

end

nothing  # avoid noise when doing `include("test/runtests.jl")`
