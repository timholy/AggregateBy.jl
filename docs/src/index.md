```@meta
CurrentModule = ByOperations
DocTestSetup = quote
    using ByOperations
end
```

# Installation

This package is not yet registered, so you'll have to enter package mode with `]` and then:

```julia
(@v1.10) pkg> dev https://github.com/timholy/ByOperations.jl
```

# Tutorial

All examples assume that you've executed `using ByOperations` in the current session.

To count all the letters in a string:

```jldoctest
julia> count(By(), "Hello")
Dict{Char, Int64} with 4 entries:
  'H' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

If you also want to ignore case, then use

```jldoctest
julia> count(By(lowercase), "HelLo")
Dict{Char, Int64} with 4 entries:
  'h' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

and all characters will be converted to lowercase before counting them.

Or, combine multiple `sum(f, itr)` statements into a single command:

```jldoctest
julia> sum(By(isodd), 1:11)
Dict{Bool, Int64} with 2 entries:
  0 => 30
  1 => 36
```

or collect such items for further analysis:

```jldoctest
julia> push!(By(isodd), 1:11)
Dict{Bool, Vector{Int64}} with 2 entries:
  0 => [2, 4, 6, 8, 10]
  1 => [1, 3, 5, 7, 9, 11]
```
