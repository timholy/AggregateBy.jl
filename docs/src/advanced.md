# Internals and advanced usage

The main design goal is to make `By` robust and easy to use. However, this package also tries to achieve good performance,
and that often means inferring the key- and value-types of the returned `Dict`. In detail, here is what actually happens for a ficticious operation `aggregator` (e.g., like `count`, `sum`, or `push!`) and "by" function `f`:

- If you call `aggregator(By{K,V}(f), itr)`, it should return a `Dict{K,V}`. It does not rely on inference.
- If you call `aggregator(By(f), itr)`, it will determine whether `itr` has a known eltype (see `Base.IteratorEltype`):
  + if the eltype `T` is known, it infers `K` from `f(::T)` and `V` from `aggregator` and `T`
  + if the eltype is unknown, it will aggregate to `Dict{Any,Any}` internally, and then try to "tighten" the eltype upon return.

You can use `AggregateBy.UNKNOWN` if you want to tighten selectively, e.g., `By{UNKNOWN,Any}` will tighten the keytype but not the valtype, and so on.

To illustrate these considerations, let's experiment with both `By(f)` and `By{K,V}(f)` in three different cases:

1. where the eltype is known and concrete (e.g., `Vector{Int}`)
2. where the eltype is known and abstract (e.g., `Vector{Any}`)
3. where the eltype is unknown

For the third case, it will help if we define a custom container type:

```julia
struct UnknownEltype
    container
end

Base.IteratorEltype(::Type{UnknownEltype}) = Base.EltypeUnknown()

Base.iterate(u::UnknownEltype) = iterate(u.container)
Base.iterate(u::UnknownEltype, s) = iterate(u.container, s)
```

Now, let's set up the data we need for benchmarking:

```julia
julia> by1 = By{Bool,Int}(isodd)
By{Bool, Int64, typeof(isodd)}(isodd)

julia> by2 = By(isodd)
By{AggregateBy.UNKNOWN, AggregateBy.UNKNOWN, typeof(isodd)}(isodd)

julia> vconcrete = collect(1:11);    # Vector{Int}

julia> vabstract = Any[(1:11)...];   # Vector{Any}

julia> vunknown = UnknownEltype(vconcrete);    # unknown eltype
```

On the author's machine,

```julia
julia> using BenchmarkTools

julia> @btime sum($by, $v);   # supply either by1 or by2, and either vconcrete, vabstract, or vunknown
```

yields the following results:

| Container   | `By{K,V}(f)` | `By(f)` |
|:---------   | -----------:| ---------------------:|
| `vconcrete` | 150.153 ns (4 allocations: 432 bytes) | 150.652 ns (4 allocations: 432 bytes) |
| `vabstract` | 343.598 ns (4 allocations: 432 bytes) | 906.775 ns (4 allocations: 512 bytes) |
| `vunknown`  | 861.281 ns (26 allocations: 960 bytes) | 1.327 μs (30 allocations: 1.44 KiB) |

In the `vunknown` row, much of the cost in the `By{K,V}(f)` case is the unknown type of `vunknown.container`;
the alternative definition

```julia
struct UnknownEltype2
    container::Vector{Int}
end
Base.IteratorEltype(::Type{UnknownEltype}) = Base.EltypeUnknown()
```

yields substantially better performance (`302.490 ns (4 allocations: 432 bytes)`).
The `By(f)` case improves less dramatically (`1.039 μs (8 allocations: 944 bytes)`).
