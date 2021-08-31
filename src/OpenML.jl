module OpenML 

using HTTP
using JSON
import ARFFFiles
import ScientificTypes: Continuous, Count, Textual, Multiclass, coerce, autotype
using Markdown
using Pkg.Artifacts

export OpenML

include("data.jl")

end # module
