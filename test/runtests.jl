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

    println("\n* Only write files")
    @time @safetestset "test_only_write_files" begin
        include("test_only_write_files.jl")
    end

    println("\n* Imgcat detection")
    @time @safetestset "test_imgcat_detection" begin
        include("test_imgcat_detection.jl")
    end

    println("\n* Smart Size")
    @time @safetestset "test_smart_size" begin
        include("test_smart_size.jl")
    end

    println("\n* Manual display")
    @time @safetestset "test_manual_display" begin
        include("test_manual_display.jl")
    end

end

nothing  # avoid noise when doing `include("test/runtests.jl")`
