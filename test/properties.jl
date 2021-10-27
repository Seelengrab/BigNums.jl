using BigNums: BITS, normalize!, set_one!, set_zero!, bitneg!

### Properties ###

###################
### Operational ###
###################

begin
    function checkOne()
        a = one(ArbUInt)
        a.data == [one(ArbDigit)]
    end

    function checkZero()
        a = zero(ArbUInt)
        isempty(a.data)
    end

    function isnormalized(a::ArbUInt)
        findlast(iszero, a.data) != lastindex(a.data)
    end

    function constructNormalized(v::Vector{ArbDigit})
        isnormalized(ArbUInt(v))
    end

    function constructNormalized(v::Union{ArbDigit, DoubleArbDigit})
        isnormalized(ArbUInt(v))
    end

    function setOne(a)
        set_one!(deepcopy(a)) == one(a)
    end

    function setZero(a)
        set_zero!(deepcopy(a)) == zero(a)
    end
end

################
### Ordering ###
################

begin
    function orderTransitive(a,b,c)
        if a < b && b < c
            return a < c
        elseif a < c && c < b
            return a < b
        elseif b < c && c < a
            return b < a
        elseif b < a && a < c
            return b < c
        elseif c < a && a < b
            return c < b
        elseif c < b && b < a
            return c < a
        else
            return a == b || b == c || a == c
        end
    end

    function orderReversal(a,b)
        if a < b
            return b > a
        elseif b < a
            return a > b
        else
            return a == b
        end
    end

    function trichotomy(a,b)
        x1 = a < b
        x2 = a == b
        x3 = a > b
        if x1
            return x2 == x3 == false
        elseif x2
            return x1 == x3 == false
        elseif x3
            return x1 == x2 == false
        end
    end

    function orderPreservedAddition((small,big),constant)
        (small + constant) < (big + constant)
    end
end

##################
### Arithmetic ###
##################

begin ## Addition ##
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
end

begin ## Multiplication ##
    function long_karatsuba_eq(a::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit})
        len = length(a) + length(b)
        long_buf = zeros(ArbDigit, len)
        kara_buf = zeros(ArbDigit, len)

        short, long = length(a) < length(b) ? (a,b) : (b,a)

        BigNums.long_mul!(long_buf, long, short)
        BigNums.karatsuba!(kara_buf, long, short)

        all(Base.splat(==), zip(kara_buf, long_buf))
    end

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
end

###############
### Bitwise ###
###############

commutative(op) = (a,b) -> commutative(a,b,op)
function commutative(a, b, op)
    op(a,b) == op(b,a)
end

begin ## Shifts ##
    function leftShiftTrailLeadCorrect(a, sh)
        b = a << sh
        iszero(a) && return trailing_zeros(a) == trailing_zeros(b) == 0

        trail_correct = trailing_zeros(a) + sh == trailing_zeros(b)

        sh %= BITS # => sh < BITS (the part we care about)

        lead_a = leading_zeros(a)
        lead_b = leading_zeros(b)
        lead_correct = begin
            if iszero(sh) # did we just shift the top most word up a number of digits?
                lead_a == lead_b
            elseif sh > lead_a # ok, only a part word overall, but did we overflow?
                lead_b == BITS - (sh - lead_a)
            elseif sh < lead_a # what about without overflow?
                lead_b == lead_a - sh
            else # and what if we shift exactly up to the boundary?
                iszero(lead_b)
            end
        end

        return trail_correct && lead_correct
    end

    function leftShiftNoDataLoss(a, sh)
        b = a << sh
        count_ones(b) == count_ones(a)
    end

    function additionOfShifts(a, (sh1, sh2)::Tuple{T,T}) where T <: Unsigned
        T1 = widen(T)
        ((a << sh1) << sh2) == (a << (T1(sh1) + T1(sh2)))
    end

    function shiftAntiInverse(a, sh)
        ((a << sh) >> sh) == a
    end

    function shiftValueSubtraction(a, (sh1,sh2)::Tuple{T,T}) where T <: Unsigned
        # property assumes sh1 <= sh2
        b = (a << sh2) >> sh1
        c = a << (sh2 - sh1)
        b == c
    end

    function rightShiftSame(a::ArbUInt, sh)
        (a >>> sh) == (a >> sh)
    end

    function shiftIdentity(a)
        (a >> 0x0) == a && (a << 0x0) == a
    end
end

begin ## Negation ##
    function inverse(a)
        a == ~(~a)
    end
end

begin ## And ##
    function zeroing_and(a)
        (a & zero(a)) == zero(a) && (zero(a) & a) == zero(a)
    end

    function identity_and(a)
        (a & a) == a
    end
end

begin ## Or ##
    function identity_or(a, b)
       (a | a) == a
    end
end

begin ## Xor ##
    function zeroing_xor(a)
        (a ⊻ a) == zero(a)
    end

    function identity_xor(a)
        (a ⊻ zero(a)) == a
    end
end

begin ## Nor ##
    function chaining_nor(a,b)
        nor(a,b) == normalize!(~(a | b))
    end
end

begin ## Nand ##
    function chaining_nand(a,b)
        nand(a,b) == normalize!(~(a & b))
    end
end

begin ## Combined Properties ##
    function lossyShift(a, sh)
        b = (a >> sh) << sh
        # mask out the parts we shifted out in b
        # FIXME: This generation of the mask is broken for when we have more than one word
        mask = ArbUInt(unsigned(-1) % ArbDigit) << sh
        # mask = (one(ArbUInt) << sh) - 0x1 # this is proper, but we don't have subtraction yet
        pop!(mask.data)
        bitneg!(mask)
        (b ⊻ (a & mask)) == a
    end
end
