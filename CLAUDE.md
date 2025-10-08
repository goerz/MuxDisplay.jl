# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MuxDisplay.jl is a Julia package that enables displaying graphics from Julia REPLs running inside terminal multiplexers (tmux, WezTerm) by redirecting image output to dedicated panes. This is particularly useful for remote development scenarios where traditional GUI image display is not practical.

## Common Development Commands

### Development REPL
```bash
make devrepl
# or: julia --project=test -i devrepl.jl
```

### Testing
```bash
make test                    # Run full test suite with coverage
julia --project=test -e 'include("devrepl.jl"); include("test/runtests.jl")'  # Run tests directly
```

### Documentation

```bash
make docs                    # Build documentation
julia --project=test docs/make.jl  # Build docs directly
```

### Code Formatting

```bash
make codestyle              # Apply JuliaFormatter to entire project
```

### Cleaning

```bash
make clean                  # Clean build/doc/testing artifacts
make distclean             # Restore to clean checkout state
```

## Architecture

### Core Components

- **src/MuxDisplay.jl**: Main module with public API (`enable()`, `disable()`, `display()`)
- **src/display.jl**: Abstract display system, defines `AbstractMuxDisplay` and core display logic
- **src/tmux.jl**: Tmux-specific implementation (`TmuxPaneDisplay`)
- **src/wezterm.jl**: WezTerm-specific implementation (`WezTermPaneDisplay`)
- **src/imgcat.jl**: Image display utilities and `imgcat` command detection
- **src/shells.jl**: Shell detection and interaction utilities

### Key Concepts

The package hooks into Julia's multimedia display system to intercept image objects, writes them to temporary files, and uses external `imgcat` programs to display them in specified multiplexer panes. It supports both tmux and WezTerm multiplexers with different display strategies.

### Test Structure

Tests are tied together in the `test/runtests.jl` file. The actual tests are implemented in the various `test/test_*.jl` file, by topic. Each test file can contain multiple `@testset` blocks.

Each of the `test_*.jl` files are included in `test/runtests.jl` with a block following the scheme

```julia
    println("\n* Title")
    @time @safetestset "sluggified_title" begin
        include("test_sluggified_title.jl")
    end
```

Any tests that check output or errors / exceptions use `IOCapture`, e.g.,

```julia
c = IOCapture.capture(passthrough = false) do
    throw(ArgumentError("message"))
end
@test c.error
@test c.value isa ArgumentError
@test contains(c.output, "message")
```

### Development Environment

The project uses a `test/` environment for development dependencies (Revise, JuliaFormatter, Coverage tools). The `devrepl.jl` script sets up this environment and provides development utilities including coverage analysis.


## Dependencies

Key dependencies:
- FileIO/ImageIO: Image file handling
- JSON: Configuration and data serialization
- Development tools: Revise, JuliaFormatter, Coverage analysis tools
