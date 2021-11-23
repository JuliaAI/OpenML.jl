module OpenML

using HTTP
using JSON
import ARFFFiles
using Markdown
if VERSION > v"1.3.0"
    using Pkg.Artifacts
end

export OpenML

include("data.jl")

end # module
