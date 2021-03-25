# MLJOpenML.jl

| Linux | Coverage |
| :-----------: | :------: |
| [![Build status](https://github.com/JuliaAI/MLJOpenML.jl/workflows/CI/badge.svg)](https://github.com/JuliaAI/MLJOpenML.jl/actions)| [![codecov.io](http://codecov.io/github/JuliaAI/MLJOpenML.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaAI/MLJOpenML.jl?branch=master) |

A package providing integration of [OpenML](https://www.openml.org) with the
[MLJ](https://alan-turing-institute.github.io/MLJ.jl/dev/) machine
learning framework.


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

```
Pkg.add("DataFrames")
using DataFrames
df = DataFrame(rowtable)
```

## Documentation

Documentation is provided in the [OpenML
Integration](https://alan-turing-institute.github.io/MLJ.jl/dev/openml_integration/)
section of the
[MLJManual](https://alan-turing-institute.github.io/MLJ.jl/dev/)


