```@meta
CurrentModule = AggregateBy
DocTestSetup = quote
    using AggregateBy
end
```

# How it works

If `aggregate` is some aggregation command, then

```julia
julia> aggregate(By(fkey, fval), itr)    # itr is an iterable container
```

performs aggregations using `operator(dict[fkey(x)], fval(x))` where `operator(a, b)` is associated with `aggregate`. First, let's see a few more examples, this time explaining how they work.

## Examples and their explanation

```jldoctest
julia> count(By(), "Hello")
Dict{Char, Int64} with 4 entries:
  'H' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

Here, the aggregation command is `count`, and the `fkey` in `By(fkey)` is the default value `identity` (`identity(x) = x`).
Consequently, each character got aggregated (by counting) into a container indexed by the character itself.
Counting aggregates `x` as `dict[fkey(x)] + 1`, i.e., the `operation` is `+(<dict-entry>, 1)`.
Note that `count` ignores any supplied `fval`.

To sum a list by some property of its items:

```jldoctest
julia> sum(By(isodd, abs2), 1:5)
Dict{Bool, Int64} with 2 entries:
  0 => 20
  1 => 35
```

`abs2(x::Real)` just squares `x`, and we note that 2² + 4² == 20 (the even numbers in `1:5`) and 1² + 3² + 5² == 35 (the odd numbers in `1:5`).
This example illustrates an important point: `fkey` is applied to each item to generate the key, and `fval` is applied to each item before excuting the aggregation operation. `sum` aggregates `dict[fkey(x)] + fval(x)`.

A third supported aggregation is `collect`:

```jldoctest
julia> collect(By(isodd), 1:11)
Dict{Bool, Vector{Int64}} with 2 entries:
  0 => [2, 4, 6, 8, 10]
  1 => [1, 3, 5, 7, 9, 11]
```

In other words, this aggregates via `push!(dict[fkey(x)], fval(x))`: `dict[fkey(x)]` returns the aggregated-list for key `fkey(x)`, and then `fval(x)` is `push!`ed onto the list.

## Supported aggregations

This table summaries the supported aggregations and their associated operators (`operator(a, b)`, where `a = dict[fkey(x)]` is the current state of the aggregator for the given key and `b = fval(x))` is the new value):

| Aggregator | Operator |
|:---------- |:-------- |
| `count(by, itr)` | `(a, b) -> a + 1` |
| `sum(by, itr)` | `(a, b) -> a + b` |
| `collect(by, itr)` | `(a, b) -> push!(a, b)` |
| `minimum(by, itr)` | `(a, b) -> min(a, b)` |
| `maximum(by, itr)` | `(a, b) -> max(a, b)` |

## Controlling the output type

If desired, you can control the key- and value-type of the returned `Dict` with `By{K,V}(fkey, fval)`.
This can be useful if you want to add items of a different type later, or to help performance in cases where Julia's type-inference fails (see [Internals and advanced usage](@ref)).
