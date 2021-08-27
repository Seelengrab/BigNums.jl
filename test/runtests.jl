module BigNumTests

using BigNums
using BigNums: ArbDigit
using Test
using PropCheck
using Combinatorics: permutations

### Function Defs

genArbUInt(i) = Integrated(Generator{ArbUInt}((rng) -> ArbUInt(root(generate(rng, PropCheck.vector(i, Integrated(Generator(ArbDigit))))))))
PropCheck.generate(::Type{ArbUInt}) = ArbUInt(generate(UInt, (rand(UInt) % 20) + 1))
PropCheck.shrink(t::ArbUInt) = Iterators.map(ArbUInt, shrink(t.data))

# PropCheck.specials(::Type{ArbUInt}) = ArbUInt[
#     ArbUInt.(must_tests)...,
#     ArbUInt.(permutations(must_tests, 2))...,
#     ArbUInt.(permutations(must_tests, 3))...,
# ]

### Properties ###

## Addition ##

function commutative_add(a::ArbUInt, b::ArbUInt)
    c = a + b
    d = b + a
    c == d
end

function associative_add(a::ArbUInt, b::ArbUInt, c::ArbUInt)
    d = a + (b + c)
    e = (a + b) + c
    d == e
end

function identity_add(a::ArbUInt)
    a == (a + zero(ArbUInt)) && a == (zero(ArbUInt) + a)
end

## Multiplication ##

function commutative_mul(a::ArbUInt, b::ArbUInt)
    c = a * b
    d = b * a
    c == d
end

function associative_mul(a::ArbUInt, b::ArbUInt, c::ArbUInt)
    d = a * (b * c)
    e = (a * b) * c
    d == e
end

function distributive_mul(a::ArbUInt, b::ArbUInt, c::ArbUInt)
    d = a * (b + c)
    e = (a*b) + (a*c)
    d == e
end

function identity_mul(a::ArbUInt)
    a == a * one(ArbUInt) && a == one(ArbUInt) * a
end

function zero_mul(a::ArbUInt)
    iszero(a * zero(ArbUInt)) && iszero(zero(ArbUInt) * a)
end

### Tests ###

@testset "Tests" begin
@testset "Addition" begin
    @testset "$f" for (n,f) in ((2,commutative_add),
                                (3,associative_add),
                                (1,identity_add))
        gen = PropCheck.tuple(n, genArbUInt(20))
        @test check(gen, Base.splat(f))
    end
end
@testset "Multiplication" begin
    @testset "$f" for (n,f) in ((2,commutative_mul),
                            (3,associative_mul),
                            (1,identity_mul),
                            (1,zero_mul))
        gen = PropCheck.tuple(n, genArbUInt(20))
        @test check(gen, Base.splat(f))
    end
end
end

end