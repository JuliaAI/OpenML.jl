# MLJOpenML.jl

| Linux | Coverage |
| :-----------: | :------: |
| [![Build status](https://github.com/JuliaAI/MLJOpenML.jl/workflows/CI/badge.svg)](https://github.com/JuliaAI/MLJOpenML.jl/actions)| [![codecov.io](http://codecov.io/github/JuliaAI/MLJOpenML.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaAI/MLJOpenML.jl?branch=master) |

A package providing integration of [OpenML](https://www.openml.org) with the
[MLJ](https://alan-turing-institute.github.io/MLJ.jl/dev/) machine
learning framework.

Based entirely on Diego Arenas' original code contribution to MLJBase.jl.


## Installation

```julia
using Pkg
Pkg.add("MLJOpenML")
```

## Sample usage

Load the iris data set from OpenML:

```julia
using MLJOpenML
rowtable = MLJOpenML.load(61)
```

Convert to a `DataFrame`:

```julia
Pkg.add("DataFrames")
using DataFrames
df = DataFrame(rowtable)
```

Browsing and filtering datasets:

```julia
using DataFrames
ds = MLJOpenML.list_datasets(output_format = DataFrame)
MLJOpenML.describe_dataset(6)
MLJOpenML.list_tags() # lists valid tags
ds = MLJOpenML.list_datasets(tag = "OpenML100", 
                             filter = "number_instances/100..1000/number_features/1..10",
                             output_format = DataFrame)
```

## Documentation

Documentation is provided in the [OpenML
Integration](https://alan-turing-institute.github.io/MLJ.jl/dev/openml_integration/)
section of the
[MLJManual](https://alan-turing-institute.github.io/MLJ.jl/dev/)


