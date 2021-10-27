function sbb(borrow::UInt8, a::ArbDigit, b::ArbDigit)
    difference = SignedDoubleArbDigit(a) - SignedDoubleArbDigit(b) - SignedDoubleArbDigit(borrow)
    lowBits(difference), UInt8(difference < 0)
end

function sub2!(a::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit})
    len = min(length(a), length(b))
    a_lo, a_hi = @views a[begin:len], a[len+1:end]
    b_lo, b_hi = @views b[begin:len], b[len+1:end]

    borrow = 0x0
    for i in eachindex(a_lo)
        a_lo[i], borrow = sbb(borrow, a_lo[i], b_lo[i])
    end

    if !iszero(borrow)
        for i in eachindex(a_hi)
            a_hi[i], borrow = sbb(borrow, a_hi[i], zero(ArbDigit))
            iszero(borrow) && break
        end
    end

    (!iszero(borrow) || any(!iszero, b_hi)) && throw(ArgumentError("Cannot subtract b from a because b is larger than a."))
end

function sub!(a::ArbUInt, b::ArbUInt)
    sub2!(a.data, b.data)
    normalize!(a)
end
sub!(a::ArbUInt, b::T) where T <: Unsigned = sub!(a, ArbUInt(b))

function Base.:(-)(a::ArbUInt, b::ArbUInt)
    a_copy = deepcopy(a)
    sub2!(a_copy.data, b.data)
    a_copy
end
Base.:(-)(a::ArbUInt, b::T) where T <: Unsigned = sub!(deepcopy(a), b)
Base.:(-)(a::T, b::ArbUInt) where T <: Unsigned = sub!(deepcopy(b), a)
