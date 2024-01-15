```@meta
CurrentModule = AggregateBy
DocTestSetup = quote
    using AggregateBy
end
```

# How it works

An object `item` is aggregated using key `f(item)`, i.e. if `operation` is some aggregation operation, then

```julia
julia> operation(By(f), itr)    # itr is an iterable container
```

performs aggregations of the form `operation(dict[f(x)], x)`. Let's see a few more examples, this time explaining how they work.

## Examples and their explanation

```jldoctest
julia> count(By(), "Hello")
Dict{Char, Int64} with 4 entries:
  'H' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

Here, the aggregation operation is `count`, and the `f` in `By(f)` is the default value `identity` (`identity(x) = x`).
Consequently, each character got aggregated (by counting) into a container indexed by the character itself.
Counting aggregates `x` as `dict[f(x)] + 1`, i.e., the `operation` is `+(<dict-entry>, 1)`.

To sum a list by some property of its items:

```jldoctest
julia> sum(By(isodd), 1:11)
Dict{Bool, Int64} with 2 entries:
  0 => 30
  1 => 36
```

Note that 30 is the sum of all even numbers in the range, and 36 is the sum of all odd numbers in the range.
This example illustrates an important point: `f` is applied to each item to generate the *key*, but aggregation uses the raw item. In code, `sum` aggregates `dict[f(x)] + x`, whereas `count` aggregates `dict[f(x)] + 1`.

A third supported aggregation is `push!`:

```jldoctest
julia> push!(By(isodd), 1:11)
Dict{Bool, Vector{Int64}} with 2 entries:
  0 => [2, 4, 6, 8, 10]
  1 => [1, 3, 5, 7, 9, 11]
```

In other words, this aggregates via `push!(dict[f(x)], x)`: `dict[f(x)]` returns the aggregated-list for key `f(x)`, and then `x` is `push!`ed onto the list.

If desired, you can control the key- and value-type of the returned `Dict` with `By{K,V}(f)`.
