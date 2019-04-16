module BigNumTests

using BigNums
using Test
using PropCheck
using Combinatorics: permutations

### Function Defs

PropCheck.generate(::Type{ArbInt{UInt}}) = ArbInt(generate(UInt, (rand(UInt) % 20) + 1))

const _lowerHalf = typemax(UInt) >> (sizeof(UInt) >> 1)
const _upperHalf = _lowerHalf << (sizeof(UInt) >> 1)
const must_tests = [one(UInt), zero(UInt), _lowerHalf, _upperHalf, typemax(UInt)]

PropCheck.specials(::Type{ArbInt{UInt}}) = ArbInt{UInt}[
    ArbInt.(must_tests)...,
    ArbInt.(permutations(must_tests, 2))...,
    ArbInt.(permutations(must_tests, 3))...,
]

### Properties ###

## Addition ##

function commutative_add(a::ArbInt, b::ArbInt)
    c = a + b
    d = b + a
    c == d
end

function associative_add(a::ArbInt, b::ArbInt, c::ArbInt)
    d = a + (b + c)
    e = (a + b) + c
    d == e
end

function identity_add(a::ArbInt)
    a == (a + zero(ArbInt)) && a == (zero(ArbInt) + a)
end

## Multiplication ##

function commutative_mul(a::ArbInt, b::ArbInt)
    c = a * b
    d = b * a
    c == d
end

function associative_mul(a::ArbInt, b::ArbInt, c::ArbInt)
    d = a * (b * c)
    e = (a * b) * c
    d == e
end

function distributive_mul(a::ArbInt, b::ArbInt, c::ArbInt)
    d = a * (b + c)
    e = (a*b) + (a*c)
    d == e
end

function identity_mul(a::ArbInt)
    a == a * one(ArbInt) && a == one(ArbInt) * a
end

function zero_mul(a::ArbInt)
    iszero(a * zero(ArbInt)) && iszero(zero(ArbInt) * a)
end

### Tests ###

@testset "Tests" begin
@testset "Addition" begin
    @check commutative_add (ArbInt{UInt}, ArbInt{UInt})
    @check associative_add (ArbInt{UInt}, ArbInt{UInt}, ArbInt{UInt})
    @check identity_add (ArbInt{UInt},)
end
@testset "Multiplication" begin
    @check commutative_mul (ArbInt{UInt}, ArbInt{UInt}) # FIXME: broken
    @check associative_mul (ArbInt{UInt}, ArbInt{UInt}, ArbInt{UInt}) # FIXME: broken
    @check identity_mul (ArbInt{UInt},)
    @check zero_mul (ArbInt{UInt},)
end
end

end