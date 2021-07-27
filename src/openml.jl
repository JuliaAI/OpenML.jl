using HTTP
using JSON
using CSV
import ScientificTypes: Continuous, Count, Textual, Multiclass, coerce, autotype
using Markdown

const API_URL = "https://www.openml.org/api/v1/json"

# Data API
# The structures are based on these descriptions
# https://github.com/openml/OpenML/tree/master/openml_OS/views/pages/api_new/v1/xsd
# https://www.openml.org/api_docs#!/data/get_data_id

# TODO:
# - Use e.g. DataDeps to cache data locally
# - Put the ARFF parser to a separate package or use ARFFFiles when
#   https://github.com/cjdoris/ARFFFiles.jl/issues/4 is fixed.

"""
Returns information about a dataset. The information includes the name,
information about the creator, URL to download it and more.

- 110 - Please provide data_id.
- 111 - Unknown dataset. Data set description with data_id was not found in the database.
- 112 - No access granted. This dataset is not shared with you.
"""
function load_Dataset_Description(id::Int; api_key::String="")
    url = string(API_URL, "/data/$id")
    try
        r = HTTP.request("GET", url)
        if r.status == 200
            return JSON.parse(String(r.body))
        elseif r.status == 110
            println("Please provide data_id.")
        elseif r.status == 111
            println("Unknown dataset. Data set description with data_id was not found in the database.")
        elseif r.status == 112
            println("No access granted. This dataset is not shared with you.")
        end
    catch e
        println("Error occurred : $e")
        return nothing
    end
    return nothing
end

function _parse(openml, val)
    val == "?" && return missing
    openml ∈ ("real", "numeric", "integer") && return Meta.parse(val)
    return val
end

emptyvec(::Type{String}, length) = fill("", length)
emptyvec(T::Any, length) = zeros(T, length)
function _vec(idxs, vals::AbstractVector{<:Union{Missing, T}}, length) where T
    result = emptyvec(T, length)
    for k in eachindex(idxs)
        result[idxs[k]] = vals[k]
    end
    result
end

_scitype(scitype, ::DataType) = scitype
_scitype(scitype, ::Type{Union{Missing, T}}) where T = Union{Missing, scitype}
function scitype(openml, inferred)
    (openml == "real" || (openml == "numeric" && inferred <: Union{Missing, <:Real})) && return _scitype(Continuous, inferred)
    (openml == "integer" || (openml == "numeric" && inferred <: Union{Missing <: Integer})) && return _scitype(Count, inferred)
    openml == "string" && return _scitype(Textual, inferred)
    openml[1] == '{' && return _scitype(Multiclass, inferred)
    error("Cannot infer the scientific type for OpenML metadata $openml and inferred type $inferred.")
end

function needs_coercion(is, shouldbe, name, verbosity)
    if (shouldbe == "numeric" && !(is <: Union{Missing, <:Number})) ||
       (shouldbe == "integer" && !(is <: Union{Missing, <:Integer})) ||
       (shouldbe == "real" && !(is <: Union{Missing, <:Real})) ||
       (shouldbe == "string" && !(is <: Union{Missing, <:AbstractString})) ||
        shouldbe[1] == '{'
        verbosity && @info "Inferred type `$is` does not match the OpenML metadata `$shouldbe` for feature `$name`. Please coerce to the desired type manually, or specify `parser = :openml` or `parser = :auto`. To suppress this message, specify `verbosity = 0`."
        true
    else
        false
    end
end

"""
Returns a Vector of NamedTuples.
Receives an `HTTP.Message.response` that has an
ARFF file format in the `body` of the `Message`.
"""
function convert_ARFF_to_columntable(response, verbosity, parser; kwargs...)
    featureNames = Symbol[]
    dataTypes = String[]
    io = IOBuffer(response.body)
    for line in eachline(io)
        if length(line) > 0
            if line[1:1] != "%"
                d = []
                if occursin("@attribute", lowercase(line))
                    splitline = split(line)
                    push!(featureNames, Symbol(splitline[2]))
                    push!(dataTypes, lowercase(join(splitline[3:end], "")))
                elseif occursin("@relation", lowercase(line))
                    nothing
                elseif occursin("@data", lowercase(line))
                    # it means the data starts
                    break
                end
            end
        end
    end
    while io.data[io.ptr] ∈ (0x0a, 0x25) # skip empty new lines and comments
        readline(io)
    end
    if io.data[io.ptr] == 0x7b # sparse ARFF file
        tmp = [(Int[], Union{Missing, type ∈ ("numeric", "real") ? Float64 : type == "integer" ? Int :  String}[]) for type in dataTypes]
        i = 0
        for line in eachline(io)
            if line[1:1] != "%"
                splitline = split(line[2:end-1], ",")
                splitline == [""] && continue
                i += 1
                for entry in splitline
                    idx_string, val = split(entry)
                    idx = parse(Int, idx_string) + 1
                    push!(tmp[idx][1], i)
                    push!(tmp[idx][2], _parse(dataTypes[idx], val))
                end
            end
        end
        tmpd = Dict(featureNames[k] => _vec(tmp[k][1], identity.(tmp[k][2]), i)
                    for k in eachindex(featureNames))
        inferred = [eltype(tmpd[k]) for k in featureNames]
        result = CSV.Tables.DictColumnTable(CSV.Tables.Schema(featureNames, inferred),
                                            tmpd)
    else
        result = CSV.File(io;
                          header = featureNames,
                          comment = "%",
                          missingstring = "?",
                          quotechar = ''',
                          escapechar = '\\',
                          kwargs...)
        inferred = CSV.gettypes(result)
        result = CSV.Tables.dictcolumntable(result)
    end
    if parser != :csv && length(featureNames) > 2000
        @info "Parser $parser is very slow for more than 2000 features. Returning result of csv parser."
        parser = :csv
    end
    idxs = needs_coercion.(inferred, dataTypes, featureNames, parser == :csv && verbosity > 0)
    if parser ∈ (:openml, :auto)
        result = coerce(result, [name => scitype(type, inferred)
                                 for (name, type, inferred) in
                                 zip(featureNames[idxs], dataTypes[idxs], inferred[idxs])]...)
    end
    if parser == :auto
        result = coerce(result, autotype(result))
    end
    return result
end

"""
    MLJOpenML.load(id; verbosity = 1, parser = :csv, kwargs...)

Load the OpenML dataset with specified `id`, from those listed by
[`list_datasets`](@ref) or on the [OpenML site](https://www.openml.org/search?type=data).
If `parser = :csv` the types of the columns are automatically detected by the
`CSV.read` function. A message is shown, if `verbosity > 0` and the detected
type does not match the OpenML metadata. If `parser = :openml` the OpenML metadata
is used to `coerce` the columns to scientific types according to the rules:

| metadata | inferred type | scientific type |
|----------|---------------|-----------------|
|numeric   | <: Real       | Continuous      |
|numeric   | <: Integer    | Count           |
|real      | <: Any        | Continuous      |
|integer   | <: Any        | Count           |
|string    | <: Any        | Textual         |
|{ANYTHING}| <: Any        | Multiclass      |

See [here](https://waikato.github.io/weka-wiki/formats_and_processing/arff_developer/)
for info on the OpenML metadata.

With `parser = :auto`, the `autotype`'s of the output of `parser = :openml` are
used to coerce the data further.

For data with more than 2000 features (columns) `parser = :csv` is used always,
because `parser = :openml` can be much slower.

Extra `kwargs` are passed to the CSV parser, `CSV.File(...)`.

Returns a table.

# Examples

```julia
using DataFrames
table = MLJOpenML.load(61);
df = DataFrame(table);
```
"""
function load(id::Int; verbosity = 1, parser = :csv, kwargs...)
    response = load_Dataset_Description(id)
    arff_file = HTTP.request("GET", response["data_set_description"]["url"])
    return convert_ARFF_to_columntable(arff_file, verbosity, parser; kwargs...)
end


"""
Returns a list of all data qualities in the system.

- 412 - Precondition failed. An error code and message are returned
- 370 - No data qualities available. There are no data qualities in the system.
"""
function load_Data_Qualities_List()
    url = string(API_URL, "/data/qualities/list")
    try
        r = HTTP.request("GET", url)
        if r.status == 200
            return JSON.parse(String(r.body))
        elseif r.status == 370
            println("No data qualities available. There are no data qualities in the system.")
        end
    catch e
        println("Error occurred : $e")
        return nothing
    end
    return nothing
end

"""
Returns a list of all data qualities in the system.

- 271 - Unknown dataset. Data set with the given data ID was not found (or is not shared with you).
- 272 - No features found. The dataset did not contain any features, or we could not extract them.
- 273 - Dataset not processed yet. The dataset was not processed yet, features are not yet available. Please wait for a few minutes.
- 274 - Dataset processed with error. The feature extractor has run into an error while processing the dataset. Please check whether it is a valid supported file. If so, please contact the API admins.
"""
function load_Data_Features(id::Int; api_key::String = "")
    if api_key == ""
        url = string(API_URL, "/data/features/$id")
    end
    try
        r = HTTP.request("GET", url)
        if r.status == 200
            return JSON.parse(String(r.body))
        elseif r.status == 271
            println("Unknown dataset. Data set with the given data ID was not found (or is not shared with you).")
        elseif r.status == 272
            println("No features found. The dataset did not contain any features, or we could not extract them.")
        elseif r.status == 273
            println("Dataset not processed yet. The dataset was not processed yet, features are not yet available. Please wait for a few minutes.")
        elseif r.status == 274
            println("Dataset processed with error. The feature extractor has run into an error while processing the dataset. Please check whether it is a valid supported file. If so, please contact the API admins.")
        end
    catch e
        println("Error occurred : $e")
        return nothing
    end
    return nothing
end

"""
Returns the qualities of a dataset.

- 360 - Please provide data set ID
- 361 - Unknown dataset. The data set with the given ID was not found in the database, or is not shared with you.
- 362 - No qualities found. The registered dataset did not contain any calculated qualities.
- 363 - Dataset not processed yet. The dataset was not processed yet, no qualities are available. Please wait for a few minutes.
- 364 - Dataset processed with error. The quality calculator has run into an error while processing the dataset. Please check whether it is a valid supported file. If so, contact the support team.
- 365 - Interval start or end illegal. There was a problem with the interval start or end.
"""
function load_Data_Qualities(id::Int; api_key::String = "")
    if api_key == ""
        url = string(API_URL, "/data/qualities/$id")
    end
    try
        r = HTTP.request("GET", url)
        if r.status == 200
            return JSON.parse(String(r.body))
        elseif r.status == 360
            println("Please provide data set ID")
        elseif r.status == 361
            println("Unknown dataset. The data set with the given ID was not found in the database, or is not shared with you.")
        elseif r.status == 362
            println("No qualities found. The registered dataset did not contain any calculated qualities.")
        elseif r.status == 363
            println("Dataset not processed yet. The dataset was not processed yet, no qualities are available. Please wait for a few minutes.")
        elseif r.status == 364
            println("Dataset processed with error. The quality calculator has run into an error while processing the dataset. Please check whether it is a valid supported file. If so, contact the support team.")
        elseif r.status == 365
            println("Interval start or end illegal. There was a problem with the interval start or end.")
        end
    catch e
        println("Error occurred : $e")
        return nothing
    end
    return nothing
end

"""
    load_List_And_Filter(filters; api_key = "")

See [OpenML API](https://www.openml.org/api_docs#!/data/get_data_list_filters).
"""
function load_List_And_Filter(filters::String; api_key::String = "")
    if api_key == ""
        url = string(API_URL, "/data/list/$filters")
    end
    try
        r = HTTP.request("GET", url)
        if r.status == 200
            return JSON.parse(String(r.body))
        elseif r.status == 370
            println("Illegal filter specified.")
        elseif r.status == 371
            println("Filter values/ranges not properly specified.")
        elseif r.status == 372
            println("No results. There where no matches for the given constraints.")
        elseif r.status == 373
            println("Can not specify an offset without a limit.")
        end
    catch e
        println("Error occurred : $e")
        return nothing
    end
    return nothing
end

qualitynames(x) = haskey(x, "name") ? [x["name"]] : []

"""
    list_datasets(; tag = nothing, filters = "" api_key = "", output_format = NamedTuple)

Lists all active OpenML datasets, if `tag = nothing` (default).
To list only datasets with a given tag, choose one of the tags in [`list_tags()`](@ref).
An alternative `output_format` can be chosen, e.g. `DataFrame`, if the
`DataFrames` package is loaded.

A filter is a string of `<data quality>/<range>` or `<data quality>/<value>`
pairs, concatenated using `/`, such as

```julia
    filter = "number_features/10/number_instances/500..10000"
```

The allowed data qualities include `tag`, `status`, `limit`, `offset`,
`data_id`, `data_name`, `data_version`, `uploader`,
`number_instances`, `number_features`, `number_classes`,
`number_missing_values`.

For more on the format and effect of `filters` refer to the [openml
API](https://www.openml.org/api_docs#!/data/get_data_list_filters).

# Examples
```
julia> using DataFrames

julia> ds = MLJOpenML.list_datasets(
               tag = "OpenML100",
               filter = "number_instances/100..1000/number_features/1..10",
               output_format = DataFrame
)

julia> sort!(ds, :NumberOfFeatures)
```
"""
function list_datasets(; tag = nothing, filter = "", filters=filter,
                         api_key = "", output_format = NamedTuple)
    if tag !== nothing
        if is_valid_tag(tag)
            filters *= "/tag/$tag"
        else
            @warn "$tag is not a valid tag. See `list_tags()` for a list of tags."
            return
        end
    end
    data = MLJOpenML.load_List_And_Filter(filters; api_key = api_key)
    datasets = data["data"]["dataset"]
    qualities = Symbol.(union(vcat([vcat(qualitynames.(entry["quality"])...) for entry in datasets]...)))
    result = merge((id = Int[], name = String[], status = String[]),
                   NamedTuple{tuple(qualities...)}(ntuple(i -> Union{Missing, Int}[], length(qualities))))
    for entry in datasets
        push!(result.id, entry["did"])
        push!(result.name, entry["name"])
        push!(result.status, entry["status"])
        for quality in entry["quality"]
            push!(getproperty(result, Symbol(quality["name"])),
                  Meta.parse(quality["value"]))
        end
        for quality in qualities
            if length(getproperty(result, quality)) < length(result.id)
                push!(getproperty(result, quality), missing)
            end
        end
    end
    output_format(result)
end

is_valid_tag(tag::String) = tag ∈ list_tags()
is_valid_tag(tag) = false

"""
    list_tags()

List all available tags.
"""
function list_tags()
    url = string(API_URL, "/data/tag/list")
    try
        r = HTTP.request("GET", url)
        return JSON.parse(String(r.body))["data_tag_list"]["tag"]
    catch
        return nothing
    end
end

"""
    describe_dataset(id)

Load and show the OpenML description of the data set `id`.
Use [`list_datasets`](@ref) to browse available data sets.

# Examples
```
julia> MLJOpenML.describe_dataset(6)
  Author: David J. Slate Source: UCI
  (https://archive.ics.uci.edu/ml/datasets/Letter+Recognition) - 01-01-1991 Please cite: P.
  W. Frey and D. J. Slate. "Letter Recognition Using Holland-style Adaptive Classifiers".
  Machine Learning 6(2), 1991

    1. TITLE:

  Letter Image Recognition Data

  The objective is to identify each of a large number of black-and-white
  rectangular pixel displays as one of the 26 capital letters in the English
  alphabet.  The character images were based on 20 different fonts and each
  letter within these 20 fonts was randomly distorted to produce a file of
  20,000 unique stimuli.  Each stimulus was converted into 16 primitive
  numerical attributes (statistical moments and edge counts) which were then
  scaled to fit into a range of integer values from 0 through 15.  We
  typically train on the first 16000 items and then use the resulting model
  to predict the letter category for the remaining 4000.  See the article
  cited above for more details.
```
"""
describe_dataset(id) =  Markdown.parse(load_Dataset_Description(id)["data_set_description"]["description"])

# Flow API

# Task API

# Run API
