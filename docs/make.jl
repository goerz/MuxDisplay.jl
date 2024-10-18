using Documenter
using Pkg
using MuxDisplay


PROJECT_TOML = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
VERSION = PROJECT_TOML["version"]
NAME = PROJECT_TOML["name"]
AUTHORS = join(PROJECT_TOML["authors"], ", ") * " and contributors"
GITHUB = "https://github.com/goerz/MuxDisplay.jl"

println("Starting makedocs")

PAGES = [
    "Home" => "index.md",
    "Background" => "background.md",
    "Scenarios" => "scenarios.md",
    "Howto" => "howto.md",
    "API" => "api.md",
]

makedocs(
    authors = AUTHORS,
    linkcheck = (get(ENV, "DOCUMENTER_CHECK_LINKS", "1") != "0"),
    # Link checking is disabled in REPL, see `devrepl.jl`.
    #warnonly=[:linkcheck,],
    sitename = "MuxDisplay.jl",
    format = Documenter.HTML(
        prettyurls = true,
        canonical = "https://goerz.github.io/MuxDisplay.jl",
        footer = "[$NAME.jl]($GITHUB) v$VERSION docs powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).",
    ),
    pages = PAGES,
)

println("Finished makedocs")

deploydocs(; repo = "github.com/goerz/MuxDisplay.jl.git", push_preview = true)
