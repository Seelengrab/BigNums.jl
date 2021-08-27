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

include("properties.jl")

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
@testset "Bitwise" begin
    @testset "Shifts" begin
        @testset "$shiftAntiInverse" begin
            # gen = 
            # @test check(gen, Base.splat(shiftAntiInverse))
            @test_broken false
        end
        @testset "$shiftSame" begin
            @test_broken false
        end
        @testset "$shiftIdentity" begin
            gen = Integrated(genArbUInt(20))
            @test check(gen, shiftIdentity)
        end
        @testset "$lossyShift" begin
            @test_broken false
        end
    end
    @testset "negation" begin
        @testset "$inverse" begin
            gen = Integrated(genArbUInt(20))
            @test check(gen, inverse)
        end
    end
    @testset "and" begin
        @testset "$f" for (n,f) in ((2,commutative(&)),
                                    (1,zeroing_and),
                                    (1,identity_and))
            gen = PropCheck.tuple(n, genArbUInt(20))
            @test check(gen, Base.splat(f))
        end
    end
    @testset "or" begin
        @testset "$f" for (n,f) in ((2,identity_or),
                                    (2,commutative(|)))
            gen = PropCheck.tuple(2, genArbUInt(20))
            @test check(gen, Base.splat(f))
        end
    end
    @testset "xor" begin
        @testset "$zeroing_xor" begin
            gen = genArbUInt(20)
            @test check(gen, zeroing_xor)
        end
        @testset "$identity_xor" begin
            gen = genArbUInt(20)
            @test check(gen, identity_xor)
        end
        @testset "$commutative" begin
            gen = PropCheck.tuple(2, genArbUInt(20))
            @test check(gen, Base.splat(commutative(⊻)))
        end
    end
    @testset "nor" begin
        @testset "$f" for (n,f) in ((2,chaining_nor),
                                    (2,commutative(⊽)))
            gen = PropCheck.tuple(2, genArbUInt(20))
            @test check(gen, Base.splat(f))
        end
    end
    @testset "nand" begin
        @testset "$f" for (n,f) in ((2,chaining_nand),
                                    (2,commutative(⊼)))
            gen = PropCheck.tuple(2, genArbUInt(20))
            @test check(gen, Base.splat(f))
        end
    end
end

end
end