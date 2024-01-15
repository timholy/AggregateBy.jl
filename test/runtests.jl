using ByOperations
using Aqua
using Test

# Container type with unknown eltype
struct UnknownEltype
    container
end

Base.IteratorEltype(::Type{UnknownEltype}) = Base.EltypeUnknown()

Base.iterate(u::UnknownEltype) = iterate(u.container)
Base.iterate(u::UnknownEltype, s) = iterate(u.container, s)


@testset "ByOperations.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(ByOperations)
    end

    @testset "count" begin
        c = @inferred count(By{Char, Int}(), "Hello")
        @test isa(c, Dict{Char, Int}) && c == Dict('H' => 1, 'e' => 1, 'l' => 2, 'o' => 1)
        c = @inferred count(By{Char, Int16}(), "Hello")
        @test isa(c, Dict{Char, Int16}) && c == Dict('H' => 1, 'e' => 1, 'l' => 2, 'o' => 1)
        c = @inferred count(By{Char, Int}(lowercase), "Hello")
        @test isa(c, Dict{Char, Int}) && c == Dict('h' => 1, 'e' => 1, 'l' => 2, 'o' => 1)
        c = @inferred count(By{Char}(lowercase), "Hello")   # count defaults to Int so this should be inferrable
        @test isa(c, Dict{Char, Int}) && c == Dict('h' => 1, 'e' => 1, 'l' => 2, 'o' => 1)
        c = @inferred count(By{Any}(lowercase), "Hello")
        @test isa(c, Dict{Any, Int}) && c == Dict('h' => 1, 'e' => 1, 'l' => 2, 'o' => 1)

        # Inference here is harder, but we can still infer the return type because the eltype is known
        c = @inferred count(By(lowercase), "Hello")
        @test isa(c, Dict{Char, Int}) && c == Dict('h' => 1, 'e' => 1, 'l' => 2, 'o' => 1)

        c = @inferred count(By(isodd), 1:11)
        @test isa(c, Dict{Bool, Int}) && c == Dict(true => 6, false => 5)

        # Inference is not possible
        c = count(By(isodd), UnknownEltype(1:11))
        @test isa(c, Dict{Bool, Int}) && c == Dict(true => 6, false => 5)
    end

    @testset "sum" begin
        s = @inferred sum(By{Int8, Int}(isodd), 1:11)
        @test isa(s, Dict{Int8, Int}) && s == Dict(0 => 30, 1 => 36)
        s = @inferred sum(By(isodd), 1:11)
        @test isa(s, Dict{Bool, Int}) && s == Dict(0 => 30, 1 => 36)

        s = sum(By(isodd), UnknownEltype(1:11))
        @test isa(s, Dict{Bool, Int}) && s == Dict(0 => 30, 1 => 36)
    end

    @testset "push!" begin
        l = @inferred push!(By{Int8, Vector{Int}}(isodd), 1:11)
        @test isa(l, Dict{Int8, Vector{Int}}) && l == Dict(0 => [2, 4, 6, 8, 10], 1 => [1, 3, 5, 7, 9, 11])

        l = @inferred push!(By(isodd), 1:11)
        @test isa(l, Dict{Bool, Vector{Int}}) && l == Dict(false => [2, 4, 6, 8, 10], true => [1, 3, 5, 7, 9, 11])

        l = push!(By(isodd), UnknownEltype(1:11))
        @test isa(l, Dict{Bool, Vector{Int}}) && l == Dict(false => [2, 4, 6, 8, 10], true => [1, 3, 5, 7, 9, 11])
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
