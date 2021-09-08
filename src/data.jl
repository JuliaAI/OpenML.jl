const API_URL = "https://www.openml.org/api/v1/json"

# Data API
# The structures are based on these descriptions
# https://github.com/openml/OpenML/tree/master/openml_OS/views/pages/api_new/v1/xsd
# https://www.openml.org/api_docs#!/data/get_data_id


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

"""
    OpenML.load(id; parser = :arff)

Load the OpenML dataset with specified `id`, from those listed by
[`list_datasets`](@ref) or on the [OpenML site](https://www.openml.org/search?type=data).
With `parser = :arff` (default) the ARFFFiles.jl parser is used.
With `parser = :auto` the output of the ARFFFiles parser is coerced to
automatically detected scientific types.

Datasets are saved as julia artifacts so that they persist locally once loaded. 

Returns a table.

# Examples

```julia
using DataFrames
table = OpenML.load(61);
df = DataFrame(table);
```
"""
function load(id::Int; parser = :arff)
    if VERSION > v"1.3.0"
        dir = first(Artifacts.artifacts_dirs())
        toml = joinpath(dir, "OpenMLArtifacts.toml")
        hash = artifact_hash(string(id), toml)
        if hash === nothing || !artifact_exists(hash)
            hash = Artifacts.create_artifact() do artifact_dir
                url = load_Dataset_Description(id)["data_set_description"]["url"]
                download(url, joinpath(artifact_dir, "$id.arff"))
            end
            bind_artifact!(toml, string(id), hash)
        end
        filename = joinpath(artifact_path(hash), "$id.arff")
    else
        url = load_Dataset_Description(id)["data_set_description"]["url"]
        filename = tempname()
        download(url, filename)
    end
    data = ARFFFiles.load(filename)
    if parser == :auto
        return coerce(data, autotype(data))
    else
        return data
    end
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

julia> ds = OpenML.list_datasets(
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
    data = OpenML.load_List_And_Filter(filters; api_key = api_key)
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
julia> OpenML.describe_dataset(6)
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
