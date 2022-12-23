module OpenML

using HTTP
using JSON
import ARFFFiles
using Markdown
using Scratch

export OpenML

download_cache = ""

include("data.jl")

function __init__()
    global download_cache = @get_scratch!("datasets")
end

end # module
