using BigNums
using BigNums: ArbDigit, DoubleArbDigit
using Test
using PropCheck
using Random

### Function Defs

include("genfuncs.jl")
include("properties.jl")

### Tests ###

@testset "Tests" begin
@testset "Construction" begin
    @test check(isnormalized, genArbUInt())
    @test checkOne()
    @test checkZero()
    @test check(setOne, genArbUInt())
    @test check(setZero, genArbUInt())
    @testset "constructNormalized($T)" for (gen,T) in ((PropCheck.vector(5, igen(ArbDigit)),Vector{ArbDigit}),
                                                        (igen(ArbDigit),ArbDigit),
                                                        (igen(DoubleArbDigit),DoubleArbDigit))
        @test check(constructNormalized, gen)
    end
end
@testset "Addition" begin
    @testset "$f" for (n,f) in ((2,commutative_add),
                                (3,associative_add),
                                (1,identity_add))
        gen = PropCheck.tuple(n, genArbUInt())
        @test check(Base.splat(f), gen)
    end
end
@testset "Multiplication" begin
    @testset "long_kara_eq" begin
        gen = PropCheck.tuple(2, PropCheck.vector(Integrated(Generator{UInt}(rng -> rand(rng,33:65))), igen(ArbDigit)))
        @test check(Base.splat(long_karatsuba_eq), gen)
    end
    @testset "$f" for (n,f) in ((2,commutative_mul),
                            (3,associative_mul),
                            (1,identity_mul),
                            (1,zero_mul))
        @testset for i in (1:32, 33:64) #, 65:1024)
            sizeGen = Integrated(Generator{UInt}(
                rng -> unsigned(rand(rng, i))
            ))
            gen = PropCheck.tuple(n, genArbUInt(sizeGen))
            @test check(Base.splat(f), gen)
        end
    end
end
@testset "Bitwise" begin
    @testset "Shifts" begin
        @testset "$leftShiftNoDataLoss" begin
            gen = interleave(genArbUInt(), igen(UInt8))
            @test check(Base.splat(leftShiftNoDataLoss), gen)
        end
        @testset "$leftShiftTrailLeadCorrect" begin
            gen = interleave(genArbUInt(), igen(UInt8)) # shifting more would be irresponsible
            @test check(Base.splat(leftShiftTrailLeadCorrect), gen)
        end
        @testset "$additionOfShifts" begin
            gen = interleave(genArbUInt(), igen(Tuple{UInt8, UInt8}))
            @test check(Base.splat(additionOfShifts), gen)
        end
        @testset "$shiftAntiInverse" begin
            gen = interleave(genArbUInt(), igen(UInt8)) # shifting more would be irresponsible
            @test check(Base.splat(shiftAntiInverse), gen)
        end
        @testset "$shiftValueSubtraction" begin
            shiftGen = filter(issorted, igen(Tuple{UInt8, UInt8}))
            gen = interleave(genArbUInt(), shiftGen)
            @test check(Base.splat(shiftValueSubtraction), gen)
        end
        @testset "$rightShiftSame" begin
            gen = interleave(genArbUInt(), igen(UInt8)) # shifting more would be irresponsible
            @test check(Base.splat(rightShiftSame), gen) broken=true
        end
        @testset "$shiftIdentity" begin
            gen = genArbUInt()
            @test check(shiftIdentity, gen)
        end
        @testset "$lossyShift" begin
            gen = interleave(genArbUInt(), igen(UInt8))
            @test check(Base.splat(lossyShift), gen)
        end
    end
    @testset "negation" begin
        @testset "$inverse" begin
            gen = genArbUInt()
            @test check(inverse, gen)
        end
    end
    @testset "and" begin
        @testset "$f" for (n,f) in ((2,commutative(&)),
                                    (1,zeroing_and),
                                    (1,identity_and))
            gen = PropCheck.tuple(n, genArbUInt())
            @test check(Base.splat(f), gen)
        end
    end
    @testset "or" begin
        @testset "$f" for (n,f) in ((2,identity_or),
                                    (2,commutative(|)))
            gen = PropCheck.tuple(n, genArbUInt())
            @test check(Base.splat(f), gen)
        end
    end
    @testset "xor" begin
        @testset "$zeroing_xor" begin
            gen = genArbUInt()
            @test check(zeroing_xor, gen)
        end
        @testset "$identity_xor" begin
            gen = genArbUInt()
            @test check(identity_xor, gen)
        end
        @testset "$commutative" begin
            gen = PropCheck.tuple(2, genArbUInt())
            @test check(Base.splat(commutative(⊻)), gen)
        end
    end
    @testset "nor" begin
        @testset "$f" for (n,f) in ((2,chaining_nor),
                                    (2,commutative(⊽)))
            gen = PropCheck.tuple(n, genArbUInt())
            @test check(Base.splat(f), gen)
        end
    end
    @testset "nand" begin
        @testset "$f" for (n,f) in ((2,chaining_nand),
                                    (2,commutative(⊼)))
            gen = PropCheck.tuple(n, genArbUInt())
            @test check(Base.splat(f), gen)
        end
    end
end
@testset "Ordering" begin
    @testset "$orderTransitive" begin
        gen = interleave(genArbUInt(), genArbUInt(), genArbUInt())
        @test check(Base.splat(orderTransitive), gen)
    end
    @testset "$orderReversal" begin
        gen = interleave(genArbUInt(), genArbUInt())
        @test check(Base.splat(orderReversal), gen)
    end
    @testset "$trichotomy" begin
        gen = interleave(genArbUInt(), genArbUInt())
        @test check(Base.splat(trichotomy), gen)
    end
    @testset "$orderPreservedAddition" begin
        genPair = Integrated(Generator{Tuple{ArbUInt, ArbUInt}}() do rng
            upper = generate(rng, ArbUInt)
            lower = rand(rng, zero(ArbUInt):upper)
            return (lower, upper + 0x1) # guarantee that the second one is larger
        end)
        gen = interleave(genPair, genArbUInt())
        @test check(Base.splat(orderPreservedAddition), gen)
    end
end
end
