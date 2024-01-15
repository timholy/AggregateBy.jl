# AggregateBy

[![Build Status](https://github.com/timholy/AggregateBy.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/timholy/AggregateBy.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/timholy/AggregateBy.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/timholy/AggregateBy.jl)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://timholy.github.io/AggregateBy.jl/dev)

AggregateBy supports simple aggregation operations on iterable containers. Functions that might be called `countby` and `groupby` are instead composed of an aggregation and `By(f)` selector.

## Examples

All examples assume that you've executed `using AggregateBy` in the current session.

To count all the letters in a string:

```julia
julia> count(By(), "Hello")
Dict{Char, Int64} with 4 entries:
  'H' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

If you also want to ignore case, then use

```julia
julia> count(By(lowercase), "HelLo")
Dict{Char, Int64} with 4 entries:
  'h' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

and all characters will be converted to lowercase before counting them.

Or, combine multiple `sum(f, itr)` statements into a single command:

```julia
julia> sum(By(isodd), 1:11)
Dict{Bool, Int64} with 2 entries:
  0 => 30
  1 => 36
```

or collect such items for further analysis:

```julia
julia> push!(By(isodd), 1:11)
Dict{Bool, Vector{Int64}} with 2 entries:
  0 => [2, 4, 6, 8, 10]
  1 => [1, 3, 5, 7, 9, 11]
```

If desired, you can control the key- and value-type of the returned `Dict` with `By{K,V}(f)`.
See the [documentation](https://timholy.github.io/AggregateBy.jl/dev) for further details.
