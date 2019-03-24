module ArbitraryTests

using ArbitraryIntegers
using Test
using PropCheck

### Function Defs

# 3 should cover most cases, at least until array generation is supported
PropCheck.generate(::Type{ArbitInt{UInt}}) = ArbitInt([rand(UInt), rand(UInt), rand(UInt)])

const _lowerHalf = typemax(UInt) >> (sizeof(UInt) >> 1)
const _upperHalf = _lowerHalf << (sizeof(UInt) >> 1)

PropCheck.specials(::Type{ArbitInt{UInt}}) = ArbitInt{UInt}[
    zero(ArbitInt),
    one(ArbitInt),
    ArbitInt([typemax(UInt)]),
    ArbitInt([UInt(1), zero(UInt)]),
    ArbitInt([typemax(UInt), zero(UInt)]),
    ArbitInt([_lowerHalf]),
    ArbitInt([_upperHalf]),
    ArbitInt([_lowerHalf, _lowerHalf]),
    ArbitInt([_lowerHalf, _upperHalf]),
    ArbitInt([_upperHalf, _upperHalf]),
    ArbitInt([_upperHalf, _lowerHalf]),
    ArbitInt([_upperHalf, typemax(UInt)]),
    ArbitInt([_upperHalf, zero(UInt)]),
    ArbitInt([_upperHalf, one(UInt)]),
    ArbitInt([_lowerHalf, typemax(UInt)]),
    ArbitInt([_lowerHalf, zero(UInt)]),
    ArbitInt([_lowerHalf, one(UInt)]),
    ArbitInt([one(UInt), typemax(UInt) - 1, typemax(UInt)])
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