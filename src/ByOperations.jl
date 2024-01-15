module ByOperations

export By

struct UNKNOWN end

struct By{K,V,F}
    f::F
end
By{K,V}(f::F) where {K,V,F} = By{K,V,F}(f)
By{K,V}() where {K,V} = By{K,V}(identity)
@inline By{K}(args...) where K = By{K,UNKNOWN}(args...)
@inline By(args...) = By{UNKNOWN}(args...)

(by::By)(x) = by.f(x)

# count

Base.count(by::By{UNKNOWN,UNKNOWN}, itr) = count(By{UNKNOWN,Int}(by.f), itr)   # count defaults to Int
Base.count(by::By{K,UNKNOWN}, itr) where K = count(By{K,Int}(by.f), itr)
Base.count(by::By{UNKNOWN,V}, itr) where V = tighten(count(By{Any,V}(by.f), itr), UNKNOWN, V)
Base.count(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> d[k] = get(d, k, zero(V)) + oneunit(V), Dict{K, V}(), itr)
# Ambiguities
Base.count(by::By{UNKNOWN,UNKNOWN}, A::Union{AbstractArray, Base.AbstractBroadcasted}) = invoke(count, Tuple{By{UNKNOWN,UNKNOWN}, Any}, by, A)
Base.count(by::By{K,UNKNOWN}, A::Union{AbstractArray, Base.AbstractBroadcasted}) where K = invoke(count, Tuple{By{K,UNKNOWN}, Any}, by, A)
Base.count(by::By{UNKNOWN,V}, A::Union{AbstractArray, Base.AbstractBroadcasted}) where V = invoke(count, Tuple{By{UNKNOWN,V}, Any}, by, A)
Base.count(by::By{K,V}, A::Union{AbstractArray, Base.AbstractBroadcasted}) where {K,V} = invoke(count, Tuple{By{K,V}, Any}, by, A)

# sum

Base.sum(by::By{UNKNOWN,UNKNOWN}, itr) = tighten(sum(By{Any,Any}(by.f), itr), UNKNOWN, UNKNOWN)
Base.sum(by::By{K,UNKNOWN}, itr) where K = tighten(sum(By{K,Any}(by.f), itr), K, UNKNOWN)
Base.sum(by::By{UNKNOWN,V}, itr) where V = tighten(sum(By{Any,V}(by.f), itr), UNKNOWN, V)
Base.sum(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> d[k] = get(d, k, V === Any ? false : zero(V)) + v, Dict{K, V}(), itr)
# Ambiguities
Base.sum(by::By{UNKNOWN,UNKNOWN}, A::AbstractArray) = invoke(sum, Tuple{By{UNKNOWN,UNKNOWN}, Any}, by, A)
Base.sum(by::By{K,UNKNOWN}, A::AbstractArray) where K = invoke(sum, Tuple{By{K,UNKNOWN}, Any}, by, A)
Base.sum(by::By{UNKNOWN,V}, A::AbstractArray) where V = invoke(sum, Tuple{By{UNKNOWN,V}, Any}, by, A)
Base.sum(by::By{K,V}, A::AbstractArray) where {K,V} = invoke(sum, Tuple{By{K,V}, Any}, by, A)
# TODO? `dims` version for AbstractArray?

# push!

Base.push!(by::By{UNKNOWN,UNKNOWN}, itr) = tighten(push!(By{Any,Any}(by.f), itr), UNKNOWN, UNKNOWN; Vdeep=eltypebottom)
Base.push!(by::By{K,UNKNOWN}, itr) where K = tighten(push!(By{K,Any}(by.f), itr), K, UNKNOWN; Vdeep=eltypebottom)
Base.push!(by::By{UNKNOWN,V}, itr) where V = tighten(push!(By{Any,V}(by.f), itr), UNKNOWN, V)
Base.push!(by::By{K,V}, itr) where {K,V} = operate!(by, (d, k, v) -> push!(get!(Vector{V}, d, k), v), Dict{K,V}(), itr)



## Generic operations

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

# function operate(by::By{UNKNOWN}, op, fits, widen, dest, itr)
#     ret = iterate(itr)
#     ret === nothing && return nothing
#     item, _ = ret
#     while ret !== nothing
#         item, state = ret
#         byitem = by(item)
#         if !fits(dest, byitem, item)
#             dest = widen(dest, byitem, item)
#         end
#         op(dest, byitem, item)
#         ret = iterate(itr, state)
#     end
#     return dest
# end


# Base.@nospecializeinfer function dictwiden(d::Dict{K1,V1}, @nospecialize(K2::Type), @nospecialize(V2::Type)) where {K1,V1}
#     K12 = typejoin(K1, K2)
#     V12 = typejoin(V1, V2)
#     d12 = Dict{K12,V12}()
#     for (k, v) in d
#         d12[k] = v
#     end
#     return d12
# end

end   # module ByOperations
