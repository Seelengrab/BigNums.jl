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
            @test check(Base.splat(f), gen) broken=(f==chaining_nand)
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
@testset "Strings & parsing" begin
    @testset "parse(string(..))" begin
        gen = genArbUInt(igen(0x100))
        @test check(x -> stringparse(x, 16), gen)
    end
    hexchar(c) = map(x -> Char(x < 0xa ? x+0x30 : x-0xa+0x61), c)
    elgen = Integrated(Generator{UInt8}(rng -> rand(rng, 0x0:0xf)))
    len = igen(unsigned(1000))
    elVectorGen = filter(x -> !iszero(length(x)), PropCheck.vector(len, elgen))
    @testset "string(parse(..))" begin
        validHexString = map(String ∘ hexchar, elVectorGen)

        @test check(x -> parsestring(x, 16), validHexString)
    end
    @testset "throwing inputs" begin
        @test_throws ArgumentError parse(ArbUInt, "")

        nonHex = filter(!isxdigit, '\u00':'\uff')
        invalidHexString = map(elVectorGen, String) do charVec
            retVec = map(hexchar, charVec)
            targetIdx = rand(eachindex(retVec))
            retVec[targetIdx] = rand(nonHex)
            join(retVec)
        end
        @test check(throwNonHex, invalidHexString)
    end
end
end
