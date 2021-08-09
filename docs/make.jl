using Documenter, OpenML, DataFrames

makedocs(
    modules = [OpenML,],
    sitename = "OpenML.jl",
)

deploydocs(
    repo = "github.com/JuliaAI/OpenML.jl",
    push_preview = true
)
