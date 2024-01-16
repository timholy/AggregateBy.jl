# AggregateBy

[![Build Status](https://github.com/timholy/AggregateBy.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/timholy/AggregateBy.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/timholy/AggregateBy.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/timholy/AggregateBy.jl)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://timholy.github.io/AggregateBy.jl/dev)

AggregateBy supports simple aggregation operations on iterable containers. Functions that might (in other languages) be called `countby` and `groupby` are instead composed of two pieces, (1) an aggregation command and (2) a `By(fkey, fval)` elementwise operator that generates key, value pairs for aggregation. Some examples may help explain the general concept.

## Examples

These examples assume that you've executed `using AggregateBy` in the current session.

To count all the letters in a string, ignoring case, use

```julia
julia> count(By(lowercase), "HelLo")
Dict{Char, Int64} with 4 entries:
  'h' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

To collect similar items, use `push!`:

```julia
julia> push!(By(isodd), 1:11)
Dict{Bool, Vector{Int64}} with 2 entries:
  0 => [2, 4, 6, 8, 10]
  1 => [1, 3, 5, 7, 9, 11]
```

If you have a matrix `temperaturedata` where the first column holds a `DateTime` (from the `Dates` library) and the second column holds the temperature, then the hourly maximum temperature can be computed as

```julia
julia> max(By(hour ∘ first, last), eachrow(temperaturedata))
Dict{Int64, Float64} with 8 entries:
  0  => 283.019
  15 => 287.615
  21 => 289.044
  6  => 278.94
  18 => 288.265
  9  => 279.512
  12 => 280.599
  3  => 277.989
```

See the [documentation](https://timholy.github.io/AggregateBy.jl/dev) for further details and more options.
