using AggregateBy
using Aqua
using DelimitedFiles
using Test

using AggregateBy: UNKNOWN

## Container type with unknown eltype
struct UnknownEltype
    container
end

Base.IteratorEltype(::Type{UnknownEltype}) = Base.EltypeUnknown()

Base.iterate(u::UnknownEltype) = iterate(u.container)
Base.iterate(u::UnknownEltype, s) = iterate(u.container, s)


@testset "AggregateBy.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(AggregateBy)
    end

    @testset "Fundamentals" begin
        @test keytype(By{Bool,Int}) === Bool
        @test keytype(By{Bool}) === Bool
        @test valtype(By{Bool,Int}) === Int
        @test keytype(By{Bool,Int}()) === Bool
        @test valtype(By{Bool,Int}()) === Int
    end

    @testset "count" begin
        uresult = Dict('H' => 1, 'e' => 1, 'l' => 2, 'o' => 1)
        lresult = Dict('h' => 1, 'e' => 1, 'l' => 2, 'o' => 1)
        c = @inferred count(By{Char, Int}(), "Hello")
        @test isa(c, Dict{Char, Int}) && c == uresult
        c = @inferred count(By{Char, Int16}(), "Hello")
        @test isa(c, Dict{Char, Int16}) && c == uresult
        c = @inferred count(By{Char, Int}(lowercase), "Hello")
        @test isa(c, Dict{Char, Int}) && c == lresult
        c = @inferred count(By{Char}(lowercase), "Hello")   # count defaults to Int so this should be inferrable
        @test isa(c, Dict{Char, Int}) && c == lresult
        c = @inferred count(By{Any}(lowercase), "Hello")
        @test isa(c, Dict{Any, Int}) && c == lresult

        # Inference here is harder, but we can still infer the return type because the eltype is known
        c = @inferred count(By(lowercase), "Hello")
        @test isa(c, Dict{Char, Int}) && c == lresult

        c = @inferred count(By(isodd), 1:11)
        @test isa(c, Dict{Bool, Int}) && c == Dict(true => 6, false => 5)

        # Inference is not possible
        c = count(By(isodd), UnknownEltype(1:11))
        @test isa(c, Dict{Bool, Int}) && c == Dict(true => 6, false => 5)
    end

    @testset "sum" begin
        result = Dict(0 => -30, 1 => -36)
        s = @inferred sum(By{Int8, Int}(isodd, x->-x), 1:11)
        @test isa(s, Dict{Int8, Int}) && s == result
        s = @inferred sum(By{Int8}(isodd, x->-x), 1:11)
        @test isa(s, Dict{Int8, Int}) && s == result
        s = @inferred sum(By{UNKNOWN,Int16}(isodd, x->-x), 1:11)
        @test isa(s, Dict{Bool, Int16}) && s == result
        s = @inferred sum(By(isodd, x->-x), 1:11)
        @test isa(s, Dict{Bool, Int}) && s == result

        s = sum(By(isodd, x->-x), UnknownEltype(1:11))
        @test isa(s, Dict{Bool, Int}) && s == result
    end

    @testset "push!" begin
        result = Dict(false => [2, 4, 6, 8, 10], true => [1, 3, 5, 7, 9, 11])
        sresult = Dict(false => [2, 4, 6, 8, 10].^2, true => [1, 3, 5, 7, 9, 11].^2)
        l = @inferred push!(By{Int8, Vector{Int16}}(isodd), 1:11)
        @test isa(l, Dict{Int8, Vector{Int16}}) && l == result
        l = @inferred push!(By{Int8}(isodd), 1:11)
        @test isa(l, Dict{Int8, Vector{Int}}) && l == result
        l = @inferred push!(By{UNKNOWN, Vector{Int16}}(isodd), 1:11)
        @test isa(l, Dict{Bool, Vector{Int16}}) && l == result
        l = @inferred push!(By(isodd), 1:11)
        @test isa(l, Dict{Bool, Vector{Int}}) && l == result
        l = @inferred push!(By(isodd, abs2), 1:11)
        @test isa(l, Dict{Bool, Vector{Int}}) && l == sresult

        l = @inferred push!(By{Int8, Vector{Int16}}(isodd), UnknownEltype(1:11))
        @test isa(l, Dict{Int8, Vector{Int16}}) && l == result
        l = push!(By{Int8}(isodd), UnknownEltype(1:11))
        @test isa(l, Dict{Int8, Vector{Int}}) && l == result
        l = push!(By{UNKNOWN, Vector{Int16}}(isodd), UnknownEltype(1:11))
        @test isa(l, Dict{Bool, Vector{Int16}}) && l == result
        l = push!(By(isodd), UnknownEltype(1:11))
        @test isa(l, Dict{Bool, Vector{Int}}) && l == result
    end

    @testset "minimum/maximum" begin
        temps = readdlm(joinpath(@__DIR__, "data", "hourly_StL.tsv"))
        byUU = By(first, last)
        byKU = By{Int}(first, last)
        byUV = By{UNKNOWN,Float64}(first, last)
        byKV = By{Int,Float64}(first, last)

        resultmin = Dict(0 => 273.15,  3 => 268.325, 6 => 264.892, 9 => 262.865, 12 => 260.351, 15 => 268.478, 18 => 273.705, 21 => 275.75)
        resultmax = Dict(0 => 283.019, 3 => 277.989, 6 => 278.94, 9 => 279.512,  12 => 280.599, 15 => 287.615, 18 => 288.265, 21 => 289.044)

        for (by, dtype) in ((byUU, Dict{Float64,Float64}), (byKU, Dict{Int,Float64}), (byUV, Dict{Float64,Float64}), (byKV, Dict{Int,Float64}))
            mins = @inferred minimum(by, eachrow(temps))
            @test isa(mins, dtype) && mins == resultmin
            maxs = @inferred maximum(by, eachrow(temps))
            @test isa(maxs, dtype) && maxs == resultmax
        end
        mins = @inferred minimum(byKV, UnknownEltype(eachrow(temps)))
        @test isa(mins, Dict{Int,Float64}) && mins == resultmin
        maxs = @inferred maximum(byKV, UnknownEltype(eachrow(temps)))
        @test isa(maxs, Dict{Int,Float64}) && maxs == resultmax
        mins = minimum(byUU, UnknownEltype(eachrow(temps)))
        @test isa(mins, Dict{Float64,Float64}) && mins == resultmin
        maxs = maximum(byUU, UnknownEltype(eachrow(temps)))
        @test isa(maxs, Dict{Float64,Float64}) && maxs == resultmax
    end

    @testset "benchmark cases" begin
        # this doesn't do benchmarking, but it runs through all the cases in the docs to ensure they work
        by1 = By{Bool,Int}(isodd)
        by2 = By(isodd)
        vconcrete = collect(1:11)
        vabstract = Any[(1:11)...]
        vunknown = UnknownEltype(vconcrete)
        for by in (by1, by2), v in (vconcrete, vabstract, vunknown)
            @test sum(by, v) == Dict(false => 30, true => 36)
        end
    end
end
