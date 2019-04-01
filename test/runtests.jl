module ArbitraryTests

using ArbitraryIntegers
using Test
using PropCheck
using Combinatorics: permutations

### Function Defs

PropCheck.generate(::Type{ArbitInt{UInt}}) = ArbitInt(generate(UInt, (rand(UInt) % 20) + 1))

const _lowerHalf = typemax(UInt) >> (sizeof(UInt) >> 1)
const _upperHalf = _lowerHalf << (sizeof(UInt) >> 1)
const must_tests = [one(UInt), zero(UInt), _lowerHalf, _upperHalf, typemax(UInt)]

PropCheck.specials(::Type{ArbitInt{UInt}}) = ArbitInt{UInt}[
    ArbitInt.(must_tests)...,
    ArbitInt.(permutations(must_tests, 2))...,
    ArbitInt.(permutations(must_tests, 3))...,
]

### Properties ###

## Addition ##

function commutative_add(a::ArbitInt, b::ArbitInt)
    c = a + b
    d = b + a
    c == d
end

function associative_add(a::ArbitInt, b::ArbitInt, c::ArbitInt)
    d = a + (b + c)
    e = (a + b) + c
    d == e
end

function identity_add(a::ArbitInt)
    a == (a + zero(ArbitInt)) && a == (zero(ArbitInt) + a)
end

## Multiplication ##

function commutative_mul(a::ArbitInt, b::ArbitInt)
    c = a * b
    d = b * a
    c == d
end

function associative_mul(a::ArbitInt, b::ArbitInt, c::ArbitInt)
    d = a * (b * c)
    e = (a * b) * c
    d == e
end

function distributive_mul(a::ArbitInt, b::ArbitInt, c::ArbitInt)
    d = a * (b + c)
    e = (a*b) + (a*c)
    d == e
end

function identity_mul(a::ArbitInt)
    a == a * one(ArbitInt) && a == one(ArbitInt) * a
end

function zero_mul(a::ArbitInt)
    iszero(a * zero(ArbitInt)) && iszero(zero(ArbitInt) * a)
end

### Tests ###

@testset "Tests" begin
@testset "Addition" begin
    @check commutative_add (ArbitInt{UInt}, ArbitInt{UInt})
    @check associative_add (ArbitInt{UInt}, ArbitInt{UInt}, ArbitInt{UInt})
    @check identity_add (ArbitInt{UInt},)
end
@testset "Multiplication" begin
    @check commutative_mul (ArbitInt{UInt}, ArbitInt{UInt}) # FIXME: broken
    @check associative_mul (ArbitInt{UInt}, ArbitInt{UInt}, ArbitInt{UInt}) # FIXME: broken
    @check identity_mul (ArbitInt{UInt},)
    @check zero_mul (ArbitInt{UInt},)
end
end

end