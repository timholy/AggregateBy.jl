module ByOperations

export By

using Base: IteratorEltype, EltypeUnknown, HasEltype

struct UNKNOWN end

struct By{K,V,F}
    f::F
end
By{K,V}(f::F) where {K,V,F} = By{K,V,F}(f)
By{K,V}() where {K,V} = By{K,V}(identity)
@inline By{K}(args...) where K = By{K,UNKNOWN}(args...)

"""
    By(f=identity)
    By{K,V}(f=identity)

`By` creates an object that triggers "key-selective" operations on a collection. `f` is the function that generates
the key, and the operation determines the resulting value. The return value is typically a `Dict`.
Optionally, you can specify the key `K` and value `V` types of that `Dict`, which can help performance in certain cases
(see the documentation for details).

# Examples

```jldoctest; setup=:(using ByOperations)
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

(by::By)(x) = by.f(x)

Base.keytype(::Type{By{K,V,F}}) where {K,V,F} = K
Base.keytype(::Type{By{K,V}}) where {K,V} = K
Base.keytype(::Type{By{K}}) where {K} = K
Base.valtype(::Type{By{K,V,F}}) where {K,V,F} = V
Base.valtype(::Type{By{K,V}}) where {K,V} = V
Base.keytype(by::By) = keytype(typeof(by))
Base.valtype(by::By) = valtype(typeof(by))

## count

Base.count(by::By, itr) = _count(by, itr, IteratorEltype(typeof(itr)))
# Ambiguities
Base.count(by::By, A::Union{AbstractArray, Base.AbstractBroadcasted}) = invoke(count, Tuple{By, Any}, by, A)

# count defaults to Int
_count(by::By{UNKNOWN,V}, itr, ::HasEltype) where V = __count(By{keyjoin(by, eltype(itr)),V===UNKNOWN ? Int : V}(by.f), itr)
_count(by::By{UNKNOWN,V}, itr, ::EltypeUnknown) where V = tighten(__count(By{Any,V===UNKNOWN ? Int : V}(by.f), itr), UNKNOWN, V===UNKNOWN ? Int : V)
_count(by::By{K,V}, itr, ::Any) where {K,V} = __count(By{K,V===UNKNOWN ? Int : V}(by.f), itr)

__count(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> d[k] = get(d, k, zero(V)) + oneunit(V), Dict{K, V}(), itr)


## sum

Base.sum(by::By, itr) = _sum(by, itr, IteratorEltype(itr))
# Ambiguities
Base.sum(by::By, A::AbstractArray) = invoke(sum, Tuple{By, Any}, by, A)
# TODO? `dims` version for AbstractArray?

_sum(by::By{UNKNOWN,UNKNOWN}, itr, ::HasEltype) = __sum(By{keyjoin(by,eltype(itr)),sumjoin(eltype(itr))}(by.f), itr)
_sum(by::By{K,UNKNOWN}, itr, ::HasEltype) where K = __sum(By{K,sumjoin(eltype(itr))}(by.f), itr)
_sum(by::By{UNKNOWN,V}, itr, ::HasEltype) where V = __sum(By{keyjoin(by,eltype(itr)),V}(by.f), itr)
_sum(by::By{K,V}, itr, ::HasEltype) where {K,V} = __sum(By{K,V}(by.f), itr)

_sum(by::By{K,V}, itr, ::EltypeUnknown) where {K,V} = tighten(__sum(By{K===UNKNOWN ? Any : K,V===UNKNOWN ? Any : V}(by.f), itr), K, V)

__sum(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> d[k] = get(d, k, V === Any ? false : zero(V)) + v, Dict{K, V}(), itr)

sumjoin(::Type{T}) where T = Core.Compiler.return_type(Tuple{typeof(+),T,T})

# push!

Base.push!(by::By, itr) = _push!(by, itr, IteratorEltype(itr))

_push!(by::By{UNKNOWN,UNKNOWN}, itr, ::HasEltype) = __push!(By{keyjoin(by,eltype(itr)),Vector{eltype(itr)}}(by.f), itr)
_push!(by::By{K,UNKNOWN}, itr, ::HasEltype) where K = __push!(By{K,Vector{eltype(itr)}}(by.f), itr)
_push!(by::By{UNKNOWN,V}, itr, ::HasEltype) where V = __push!(By{keyjoin(by,eltype(itr)),V}(by.f), itr)
_push!(by::By{K,V}, itr, ::HasEltype) where {K,V} = __push!(By{K,V}(by.f), itr)

_push!(by::By{UNKNOWN,UNKNOWN}, itr, ::EltypeUnknown) = tighten(__push!(By{Any,Any}(by.f), itr), UNKNOWN, UNKNOWN; Vdeep=eltypebottom)
_push!(by::By{K,UNKNOWN}, itr, ::EltypeUnknown) where K = tighten(__push!(By{K,Any}(by.f), itr), K, UNKNOWN; Vdeep=eltypebottom)
_push!(by::By{UNKNOWN,V}, itr, ::EltypeUnknown) where V = tighten(__push!(By{Any,V}(by.f), itr), UNKNOWN, V)
_push!(by::By{K,V}, itr, ::EltypeUnknown) where {K,V} = __push!(By{K,V}(by.f), itr)


__push!(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> push!(get!(Vector{V}, d, k), v), Dict{K,V}(), itr)



## Generic operations

keyjoin(::By{K,V,F}, ::Type{T}) where {K,V,F,T} = Core.Compiler.return_type(Tuple{F,T})

function operate!(by::By{K}, op, dest, itr) where K
    for item in itr
        byitem = by(item)
        op(dest, byitem, item)
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

end   # module ByOperations
