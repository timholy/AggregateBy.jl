```@meta
CurrentModule = AggregateBy
DocTestSetup = quote
    using AggregateBy
end
```

# Installation

This package is not yet registered, so you'll have to enter package mode with `]` and then:

```julia
(@v1.10) pkg> dev https://github.com/timholy/AggregateBy.jl
```

# Tutorial

These examples assume that you've executed `using AggregateBy` in the current session.

To count all the letters in a string, ignoring case, use

```jldoctest
julia> count(By(lowercase), "HelLo")
Dict{Char, Int64} with 4 entries:
  'h' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

To collect similar items, use `collect`:

```jldoctest
julia> collect(By(isodd, x -> -x), 1:11)
Dict{Bool, Vector{Int64}} with 2 entries:
  0 => [-2, -4, -6, -8, -10]
  1 => [-1, -3, -5, -7, -9, -11]
```

The next page explains how these examples work.
