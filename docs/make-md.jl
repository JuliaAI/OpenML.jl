using OpenML, DataFrames, ScientificTypes, DocumenterMarkdown, Documenter

makedocs(
    format = Markdown(),
    modules = [OpenML,],
    sitename = "OpenML.jl",
)
