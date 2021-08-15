# OpenML.jl

| Linux | Coverage | Documentation |
| :-----------: | :------: | :-------: |
| [![Build status](https://github.com/JuliaAI/OpenML.jl/workflows/CI/badge.svg)](https://github.com/JuliaAI/OpenML.jl/actions)| [![codecov.io](http://codecov.io/github/JuliaAI/OpenML.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaAI/OpenML.jl?branch=master) |  [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaAI.github.io/OpenML.jl/stable) |

Partial implementation of the [OpenML](https://www.openml.org) API for
Julia. At present this package allows querying and
downloading of OpenML datasets. 

For further integration with the
[MLJ](https://JuliaAI.github.io/MLJ.jl/dev/) machine
learning framework (such as uploading MLJ runs) see
[MLJOpenML.jl](https://github.com/JuliaAI/MLJOpenML.jl).


The code in this repository is based on contributions of Diego Arenas
to [MLJBase.jl](https://github.com/JuliaAI/MLJBase.jl) which do not
appear in the commit history of this repository.

Package documentation is [here](https://JuliaAI.github.io/OpenML.jl/dev).

## Summary of functionality

- `OpenML.list_tags()`: for listing all dataset tags
        
- `OpenML.list_datasets(; tag=nothing, filter=nothing, output_format=...)`: for listing available datasets

- `OpenML.describe_dataset(id)`: to describe a particular dataset

- `OpenML.load(id; parser=:arff)`: to download a dataset


## Installation

```julia
using Pkg
Pkg.add("OpenML")
```

If running the demonstration below:

```julia
Pkg.add("DataFrames") 
Pkg.add("ScientificTypes")
```

## Sample usage

```julia
using OpenML # or using MLJ
using DataFrames

OpenML.list_tags()
```

Listing all datasets with the "OpenML100" tag which also have `n`
instances and `p` features, where `100 < n < 1000` and `1 < p < 10`:

```julia
ds = OpenML.list_datasets(
          tag = "OpenML100",
          filter = "number_instances/100..1000/number_features/1..10",
          output_format = DataFrame)
```

Describing and loading one of these datasets:

```julia
OpenML.describe_dataset(15)
table = OpenML.load(15)
```

Converting to a data frame:

```julia
df = DataFrame(table)
```

Inspecting it's schema:

```julia
using ScientificTypes
schema(table)
```
