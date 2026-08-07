using Documenter, OpenML, DataFrames

const  REPO = Remotes.GitHub("JuliaAI", "OpenML.jl")

makedocs(
    modules = [OpenML,],
    sitename = "OpenML.jl",
    warnonly = [:cross_references, :missing_docs],
    repo = Remotes.GitHub("JuliaAI", "OpenML.jl"),
)

deploydocs(
    repo = "github.com/JuliaAI/OpenML.jl.git",
    devbranch="dev",
)
