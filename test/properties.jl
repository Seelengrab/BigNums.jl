
### Properties ###

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
    function shiftAntiInverse(a, sh)
        ((a << sh) >> sh) == a
    end

    function shiftSame(a::ArbUInt, sh)
        (a >>> sh) == (a >> sh)
    end

    function shiftIdentity(a)
        (a >> 0) == a && (a << 0) == a
    end
end

begin ## Negation ##
    function inverse(a)
        b = deepcopy(a)
        if iszero(Base.leading_zeros(last(a.data)))
            push!(b.data ,zero(ArbDigit))
        end
        b = ~(~b)
    end
end

begin ## And ##
    function zeroing_and(a)
        (a & 0) == zero(a) && (0 & a) == zero(a)
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
        nor(a,b) == ~(a | b)
    end
end

begin ## Nand ##
    function chaining_nand(a,b)
        nand(a,b) == ~(a & b)
    end
end

begin ## Combined Properties ##
    function lossyShift(a, sh)
        b = (a >> sh) << sh
        c = ~(one(ArbUInt) << (sh+1))
        (a ⊻ ~(a & c)) == b
    end
end