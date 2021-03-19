using Documenter, MLJOpenML

makedocs(
    modules = [MLJOpenML],
    sitename = "MLJOpenML.jl",
)

deploydocs(
    repo = "github.com/alan-turing-institute/MLJOpenML.jl.git",
)
