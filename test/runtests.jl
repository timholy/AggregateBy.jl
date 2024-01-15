using ByOperations
using Aqua
using Test

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

        @test count(By(lowercase), "Hello") == Dict('h' => 1, 'e' => 1, 'l' => 2, 'o' => 1)

        @test count(By(isodd), 1:11) == Dict(true => 6, false => 5)
    end

    @testset "sum" begin
        s = @inferred sum(By{Int8, Int}(isodd), 1:11)
        @test isa(s, Dict{Int8, Int}) && s == Dict(0 => 30, 1 => 36)
        @test sum(By(isodd), 1:11) == Dict(false => 30, true => 36)
    end

    @testset "push!" begin
        l = @inferred push!(By{Int8, Vector{Int}}(isodd), 1:11)
        @test isa(l, Dict{Int8, Vector{Int}}) && l == Dict(0 => [2, 4, 6, 8, 10], 1 => [1, 3, 5, 7, 9, 11])

        l = push!(By(isodd), 1:11)
        @test isa(l, Dict{Bool, Vector{Int}}) && l == Dict(false => [2, 4, 6, 8, 10], true => [1, 3, 5, 7, 9, 11])
    end
end
