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

performs aggregations using `operator(dict[fkey(x)], fval(x))` where `operator(a, b)` is associated with `aggregate`. Let's see a few more examples, this time diving into the details of how they work.

## Examples and their explanation

```jldoctest
julia> count(By(), "Hello")
Dict{Char, Int64} with 4 entries:
  'H' => 1
  'l' => 2
  'e' => 1
  'o' => 1
```

Here, the aggregation command is `count`, and the `fkey` is the default value `identity` (`identity(x) = x`).
Consequently, each character got aggregated (by counting) into a container indexed by the character itself.
`count` aggregates `x` as `dict[fkey(x)] + 1`: if we let `a = dict[fkey(x)]` and `b = fval(x)`, then `count`'s associated `operator` is `operator(a, b) = a + 1`. In other words, each time a key `fkey(x)` is encountered, the count for that key is incremented by 1.
Note that `count`'s `operator` doesn't use `b`, and hence `count` does not use `fval`.

For our next example, let's sum a list by some property of its items:

```jldoctest
julia> sum(By(isodd, abs2), 1:5)
Dict{Bool, Int64} with 2 entries:
  0 => 20
  1 => 35
```

Here `fkey = isodd`, and `fval = abs2`. Thus, the keys of the Dict are `Bool` (`false` for even numbers, `true` for odd numbers). `abs2(x::Real)` just squares `x`, and we note that 20 == 2² + 4² (the even numbers in `1:5`) and 35 == 1² + 3² + 5² (the odd numbers in `1:5`). For the aggregator `sum`, we have `operator(a, b) = a + b`.

## Supported aggregations

This table summaries the supported aggregations and their associated `operator(a, b)`, where `a = dict[fkey(x)]` is the current state of the aggregation for the given key and `b = fval(x))` is the new value:

| Aggregator | Operator |
|:---------- |:-------- |
| `count(by, itr)` | `(a, b) -> a + 1` |
| `sum(by, itr)` | `(a, b) -> a + b` |
| `collect(by, itr)` | `(a, b) -> push!(a, b)` |
| `minimum(by, itr)` | `(a, b) -> min(a, b)` |
| `maximum(by, itr)` | `(a, b) -> max(a, b)` |

## Controlling the output type

If desired, you can control the key- and value-types of the returned `Dict{K,V}` with `By{K,V}(fkey, fval)`.
This can be useful if you want to add items of a different type later, or to help performance in cases where Julia's type-inference fails (see [Internals and advanced usage](@ref)).
