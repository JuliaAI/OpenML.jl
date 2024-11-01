const API_URL = "https://www.openml.org/api/v1/json"

struct OpenMLAPIError <: Exception
    msg::String
end
function Base.showerror(io::IO, e::OpenMLAPIError)
    print(io, e.msg)
end


# Data API. See REST API on https://www.openml.org/apis
function get(query)
    try
        r = HTTP.request("GET", string(API_URL, query))
        return JSON.parse(String(r.body))
    catch e
        if isa(e, HTTP.StatusError) && e.status == 412
            error_string = String(e.response.body)
            err = try
                JSON.parse(error_string)["error"]
            catch
                @error(error_string)
                throw(OpenMLAPIError("Malformed query \"$query\"."))
            end
            msg = err["message"]
            code = err["code"]
            additional_msg = haskey(err, "additional_message") ? err["additional_message"] : ""
            if code == "111"
                additional_msg *= "Check if there is a dataset with id $(last(split(query, '/'))).\nSee e.g. OpenML.list_datasets(). "
            end
            throw(OpenMLAPIError(msg * ". " * additional_msg * "(error code $code)"))
        else
            rethrow()
        end
    end
    return nothing
end

"""
    OpenML.load_Dataset_Description(id::Int)

Returns information about a dataset. The information includes the name,
information about the creator, URL to download it and more.
"""
load_Dataset_Description(id::Int) = get("/data/$id")

"""
    OpenML.load(id; maxbytes = nothing)

Load the OpenML dataset with specified `id`, from those listed by
[`list_datasets`](@ref) or on the [OpenML site](https://www.openml.org/search?type=data).

Datasets are saved as julia artifacts so that they persist locally once loaded.

Returns a table.

# Examples

```julia
using DataFrames
table = OpenML.load(61)
df = DataFrame(table) # transform to a DataFrame
using ScientificTypes
df2 = coerce(df, autotype(df)) # corce to automatically detected scientific types

peek_table = OpenML.load(61, maxbytes = 1024) # load only the first 1024 bytes of the table
```
"""
function load(id::Int; maxbytes = nothing)
    fname = joinpath(download_cache, "$id.arff")
    if !isfile(fname)
        @info "Downloading dataset $id."
        download(load_Dataset_Description(id)["data_set_description"]["url"], fname)
    end
    open(fname) do io
        reader = ARFFFiles.loadstreaming(io)
        return ARFFFiles.readcolumns(reader; maxbytes=maxbytes)
    end
end


"""
    load_Data_Qualities_List()

Returns a list of all data qualities in the system.
"""
load_Data_Qualities_List() = get("/data/qualities/list")

"""
    load_Data_Qualities(id::Int)

Returns the qualities of dataset `id`.
"""
load_Data_Qualities(id::Int) = get("/data/qualities/$id")

"""
    load_Data_Features(id::Int)

Returns a list of all data qualities for dataset `id`.
"""
load_Data_Features(id::Int) = get("/data/features/$id")

"""
    load_List_And_Filter(filters)

See [OpenML API](https://www.openml.org/api_docs#!/data/get_data_list_filters).
"""
load_List_And_Filter(filters::String) = get("/data/list/$filters")

qualitynames(x) = haskey(x, "name") ? [x["name"]] : []

"""
    list_datasets(; tag = nothing, filters = "", output_format = NamedTuple)

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
function list_datasets(; tag = nothing, filter = "", filters = filter,
                         output_format = NamedTuple)
    if tag !== nothing
        if is_valid_tag(tag)
            filters *= "/tag/$tag"
        else
            @warn "$tag is not a valid tag. See `list_tags()` for a list of tags."
            return
        end
    end
    data = OpenML.load_List_And_Filter(filters)
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
    result = get("/data/tag/list")
    if !isnothing(result)
        return result["data_tag_list"]["tag"]
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
function describe_dataset(id)
    result = load_Dataset_Description(id)
    result === nothing && return
    description = result["data_set_description"]["description"]
    if isa(description, AbstractString)
        Markdown.parse(description)
    else
        "No description found."
    end
end

# Flow API

# Task API

# Run API
