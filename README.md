# ByOperations

[![Build Status](https://github.com/timholy/ByOperations.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/timholy/ByOperations.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/timholy/ByOperations.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/timholy/ByOperations.jl)

ByOperations supports simple aggregation operations on iterable containers. Functions in other languages like `countby` and `groupby` are composed of a core operation and by `By(f)` operation.

## Examples

All examples assume that you've executed `using ByOperations` in the current session.

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

## Performance and inferrability

`By` is intended for robustness and ease-of-use. Unless you tell it otherwise, while iterating over the elements of the iterable it internally aggregates to a `Dict{Any,Any}`, and then attempts to "tighten" the output container type when it returns.

However, if you know the parameters you want for the returned `Dict`, you can pass them through `By`:

```julia
julia> push!(By{Bool,Vector{Int}}(isodd), 1:11)   # output has Bool keys and Vector{Int} values
Dict{Bool, Vector{Int64}} with 2 entries:
  0 => [2, 4, 6, 8, 10]
  1 => [1, 3, 5, 7, 9, 11]
```

While it looks the same in terms of result, it was able to use "final" types throughout iteration. This example might give you a sense for the performance improvement:

```julia
julia> using BenchmarkTools

julia> by1 = By{Bool,Vector{Int}}(isodd)
By{Bool, Vector{Int64}, typeof(isodd)}(isodd)

julia> by2 = By(isodd)
By{ByOperations.UNKNOWN, ByOperations.UNKNOWN, typeof(isodd)}(isodd)

julia> @btime push!($by1, 1:11);
  253.404 ns (10 allocations: 800 bytes)

julia> @btime push!($by2, 1:11);
  2.001 μs (14 allocations: 1.36 KiB)
```

Tightening is performed only on "UNKNOWN" parameters:

```julia
julia> push!(By{Bool,Vector{Any}}(isodd), 1:11)
Dict{Bool, Vector{Any}} with 2 entries:
  0 => [2, 4, 6, 8, 10]
  1 => [1, 3, 5, 7, 9, 11]
```

The values are accumulated in a `Vector{Any}` (because we asked for that) despite the fact that a `Vector{Int}` would suffice for these particular objects.
