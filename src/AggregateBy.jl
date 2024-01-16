module AggregateBy

export By

using Base: IteratorEltype, EltypeUnknown, HasEltype

struct UNKNOWN end

struct By{K,V,FKey,FVal}
    fkey::FKey
    fval::FVal
end
By{K,V}(fkey::FKey=identity, fval::FVal=identity) where {K,V,FKey,FVal} = By{K,V,FKey,FVal}(fkey, fval)
@inline By{K}(args...) where K = By{K,UNKNOWN}(args...)
# By(args...) is below with the docstring

"""
    By(fkey=identity, fval=identity)
    By{K,V}(fkey=identity, fval=identity)

`By` creates an object that triggers "key-selective" operations on a collection. `fkey(item)` generates
the key (i.e., the aggregation target), and `fval(item)` gets used in the aggregation operation.

The return value is typically a `Dict`. Optionally, you can specify the key `K` and value `V` types
of that `Dict`, which can help performance in certain cases (see the documentation for details).

# Examples

```jldoctest; setup=:(using AggregateBy)
julia> count(By(lowercase), "Hello")
Dict{Char, Int64} with 4 entries:
  'h' => 1
  'l' => 2
  'e' => 1
  'o' => 1

julia> push!(By(isodd), 1:11)
Dict{Bool, Vector{Int64}} with 2 entries:
  0 => [2, 4, 6, 8, 10]
  1 => [1, 3, 5, 7, 9, 11]
```
"""
@inline By(args...) = By{UNKNOWN}(args...)

Base.keytype(::Type{<:By{K}})   where {K}   = K
Base.valtype(::Type{<:By{K,V}}) where {K,V} = V
Base.keytype(by::By) = keytype(typeof(by))
Base.valtype(by::By) = valtype(typeof(by))

## count
# count ignores `fval`

Base.count(by::By, itr) = _count(by, itr, IteratorEltype(typeof(itr)))
# Ambiguities
Base.count(by::By, A::Union{AbstractArray, Base.AbstractBroadcasted}) = invoke(count, Tuple{By, Any}, by, A)

# count defaults to Int
_count(by::By{UNKNOWN,V}, itr, ::HasEltype) where V = __count(By{fkeyitemtype(by, eltype(itr)),V===UNKNOWN ? Int : V}(by.fkey, by.fval), itr)
_count(by::By{UNKNOWN,V}, itr, ::EltypeUnknown) where V = tighten(__count(By{Any,V===UNKNOWN ? Int : V}(by.fkey, by.fval), itr), UNKNOWN, V===UNKNOWN ? Int : V)
_count(by::By{K,V}, itr, ::Any) where {K,V} = __count(By{K,V===UNKNOWN ? Int : V}(by.fkey, by.fval), itr)

__count(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> d[k] = get(d, k, zero(V)) + oneunit(V), Dict{K, V}(), itr)


## sum

Base.sum(by::By, itr) = _sum(by, itr, IteratorEltype(itr))
# Ambiguities
Base.sum(by::By, A::AbstractArray) = invoke(sum, Tuple{By, Any}, by, A)
# TODO? `dims` version for AbstractArray?

_sum(by::By{UNKNOWN,UNKNOWN}, itr, ::HasEltype) = __sum(By{fkeyitemtype(by,eltype(itr)),sumjoin(by,eltype(itr))}(by.fkey, by.fval), itr)
_sum(by::By{K,UNKNOWN}, itr, ::HasEltype) where K = __sum(By{K,sumjoin(by,eltype(itr))}(by.fkey, by.fval), itr)
_sum(by::By{UNKNOWN,V}, itr, ::HasEltype) where V = __sum(By{fkeyitemtype(by,eltype(itr)),V}(by.fkey, by.fval), itr)
_sum(by::By{K,V}, itr, ::HasEltype) where {K,V} = __sum(By{K,V}(by.fkey, by.fval), itr)

_sum(by::By{K,V}, itr, ::EltypeUnknown) where {K,V} = tighten(__sum(By{K===UNKNOWN ? Any : K,V===UNKNOWN ? Any : V}(by.fkey, by.fval), itr), K, V)

__sum(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> d[k] = get(d, k, V === Any ? false : zero(V)) + v, Dict{K, V}(), itr)

function sumjoin(by::By{K,V,FKey,FVal}, ::Type{T}) where {K,V,FKey,FVal,T}
    FT = fvalitemtype(by, T)
    return Core.Compiler.return_type(Tuple{typeof(+),FT,FT})
end

# push!

Base.push!(by::By, itr) = _push!(by, itr, IteratorEltype(itr))

_push!(by::By{UNKNOWN,UNKNOWN}, itr, ::HasEltype) = __push!(By{fkeyitemtype(by,eltype(itr)),Vector{fvalitemtype(by,eltype(itr))}}(by.fkey, by.fval), itr)
_push!(by::By{K,UNKNOWN}, itr, ::HasEltype) where K = __push!(By{K,Vector{fvalitemtype(by,eltype(itr))}}(by.fkey, by.fval), itr)
_push!(by::By{UNKNOWN,V}, itr, ::HasEltype) where V = __push!(By{fkeyitemtype(by,eltype(itr)),V}(by.fkey, by.fval), itr)
_push!(by::By{K,V}, itr, ::HasEltype) where {K,V} = __push!(By{K,V}(by.fkey, by.fval), itr)

_push!(by::By{UNKNOWN,UNKNOWN}, itr, ::EltypeUnknown) = tighten(__push!(By{Any,Any}(by.fkey, by.fval), itr), UNKNOWN, UNKNOWN; Vdeep=eltypebottom)
_push!(by::By{K,UNKNOWN}, itr, ::EltypeUnknown) where K = tighten(__push!(By{K,Any}(by.fkey, by.fval), itr), K, UNKNOWN; Vdeep=eltypebottom)
_push!(by::By{UNKNOWN,V}, itr, ::EltypeUnknown) where V = tighten(__push!(By{Any,V}(by.fkey, by.fval), itr), UNKNOWN, V)
_push!(by::By{K,V}, itr, ::EltypeUnknown) where {K,V} = __push!(By{K,V}(by.fkey, by.fval), itr)


__push!(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> push!(get!(Vector{V}, d, k), v), Dict{K,V}(), itr)


# min

Base.min(by::By, itr) = _min(by, itr, IteratorEltype(itr))
# Ambiguities
Base.min(::By, m::Missing) = m

_min(by::By{UNKNOWN,UNKNOWN}, itr, ::HasEltype) = __min(By{fkeyitemtype(by,eltype(itr)),fvalitemtype(by,eltype(itr))}(by.fkey, by.fval), itr)
_min(by::By{K,UNKNOWN}, itr, ::HasEltype) where K = __min(By{K,fvalitemtype(by,eltype(itr))}(by.fkey, by.fval), itr)
_min(by::By{UNKNOWN,V}, itr, ::HasEltype) where V = __min(By{fkeyitemtype(by,eltype(itr)),V}(by.fkey, by.fval), itr)
_min(by::By{K,V}, itr, ::HasEltype) where {K,V} = __min(By{K,V}(by.fkey, by.fval), itr)

_min(by::By{K,V}, itr, ::EltypeUnknown) where {K,V} = tighten(__min(By{K===UNKNOWN ? Any : K,V===UNKNOWN ? Any : V}(by.fkey, by.fval), itr), K, V)

__min(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> d[k] = safemin(v, get(d, k, UNKNOWN())), Dict{K, V}(), itr)

safemin(x, y) = min(x, y)
safemin(x, ::UNKNOWN) = x

# max

Base.max(by::By, itr) = _max(by, itr, IteratorEltype(itr))
# Ambiguities
Base.max(::By, m::Missing) = m

_max(by::By{UNKNOWN,UNKNOWN}, itr, ::HasEltype) = __max(By{fkeyitemtype(by,eltype(itr)),fvalitemtype(by,eltype(itr))}(by.fkey, by.fval), itr)
_max(by::By{K,UNKNOWN}, itr, ::HasEltype) where K = __max(By{K,fvalitemtype(by,eltype(itr))}(by.fkey, by.fval), itr)
_max(by::By{UNKNOWN,V}, itr, ::HasEltype) where V = __max(By{fkeyitemtype(by,eltype(itr)),V}(by.fkey, by.fval), itr)
_max(by::By{K,V}, itr, ::HasEltype) where {K,V} = __max(By{K,V}(by.fkey, by.fval), itr)

_max(by::By{K,V}, itr, ::EltypeUnknown) where {K,V} = tighten(__max(By{K===UNKNOWN ? Any : K,V===UNKNOWN ? Any : V}(by.fkey, by.fval), itr), K, V)

__max(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> d[k] = safemax(v, get(d, k, UNKNOWN())), Dict{K, V}(), itr)

safemax(x, y) = max(x, y)
safemax(x, ::UNKNOWN) = x


## Generic operations

fkeyitemtype(::By{K,V,FKey}, ::Type{T}) where {K,V,FKey,T} = Core.Compiler.return_type(Tuple{FKey,T})
fvalitemtype(::By{K,V,FKey,FVal}, ::Type{T}) where {K,V,FKey,FVal,T} = Core.Compiler.return_type(Tuple{FVal,T})

function operate!(by::By, op, dest, itr)
    for item in itr
        key = by.fkey(item)
        op(dest, key, by.fval(item))
    end
    return dest
end

function tighten(dest::Dict, ::Type{UNKNOWN}, ::Type{UNKNOWN}; Kdeep=nothing, Vdeep=nothing)
    K, V = Union{}, Union{}
    for (k, v) in dest
        K = Kdeep !== nothing ? deeptypejoin(Kdeep(K), k) : typejoin(K, typeof(k))
        V = Vdeep !== nothing ? deeptypejoin(Vdeep(V), v) : typejoin(V, typeof(v))
    end
    return merge!(Dict{K,V}(), dest)
end

function tighten(dest::Dict, ::Type{K}, ::Type{UNKNOWN}; Kdeep=nothing, Vdeep=nothing) where K
    V = Union{}
    for (_, v) in dest
        V = Vdeep !== nothing ? deeptypejoin(Vdeep(V), v) : typejoin(V, typeof(v))
    end
    return merge!(Dict{K,V}(), dest)
end

function tighten(dest::Dict, ::Type{UNKNOWN}, ::Type{V}; Kdeep=nothing, Vdeep=nothing) where V
    K = Union{}
    for (k, _) in dest
        K = Kdeep !== nothing ? deeptypejoin(Kdeep(K), k) : typejoin(K, typeof(k))
    end
    return merge!(Dict{K,V}(), dest)
end

tighten(dest::Dict, ::Type{K}, ::Type{V}; Kdeep=nothing, Vdeep=nothing) where {K,V} = dest   # don't tighten

Base.@nospecializeinfer deeptypejoin(@nospecialize(T::Type), itr::Array{<:Any,N}) where N = Array{deepeltypejoin(T, itr), N}
Base.@nospecializeinfer function deeptypejoin(@nospecialize(T::Type), itr::Dict)
    P = deepeltypejoin(T, itr)   # Pair{K,V}
    return Dict{P.parameters...}
end

Base.@nospecializeinfer function deepeltypejoin(@nospecialize(T::Type), itr)
    for item in itr
        T = typejoin(T, typeof(item))
    end
    return T
end

eltypebottom(::Type{Union{}}) = Union{}
eltypebottom(::Type{T}) where T = eltype(T)

end   # module AggregateBy
