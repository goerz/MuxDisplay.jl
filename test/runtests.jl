using Test
using SafeTestsets

# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "MultiplexerPaneDisplay" begin

    println("\n* Tmux Plots Display")
    @time @safetestset "test_tmux_plots_display" begin
        include("test_tmux_plots_display.jl")
    end

    println("\n* WezTerm Plots Display")
    @time @safetestset "test_wezterm_plots_display" begin
        include("test_wezterm_plots_display.jl")
    end

    println("\n* Manual display")
    @time @safetestset "test_manual_display" begin
        include("test_manual_display.jl")
    end

    # TODO: only write files mode

end

nothing  # avoid noise when doing `include("test/runtests.jl")`
