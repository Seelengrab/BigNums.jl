### ADDITION ###

"""
    adc(c_in, a, b)

    Calculates the sum of carry_in, a and b and returns their sum as well as an UInt8 for carry_out.
"""
function adc(c_in, a::ArbDigit, b::ArbDigit)
    s = DoubleArbDigit(a) + DoubleArbDigit(b) + DoubleArbDigit(c_in)
    hi, lo = fromDoubleArbDigit(s)
    lo, hi
end

function _add2!(a::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit})
    @assert length(a) >= length(b) "length(a) == $(length(a)) < $(length(b)) == length(b), should be >="
    a_lo = @view a[begin:length(b)]
    a_hi = @view a[length(b)+1:end]

    carry = zero(ArbDigit)
    @inbounds for (i,(a_el,b_el)) in enumerate(zip(a_lo, b))
        a_lo[i], carry = adc(carry, a_el, b_el)
    end

    if !iszero(carry)
        carry = _add2!(a_hi, carry)
    end

    carry
end

function _add2!(a::AbstractVector{ArbDigit}, carry)
    @inbounds for i in eachindex(a)
        a_el = a[i]
        # TODO: can we do this faster, without going up in size?
        a[i], carry = adc(carry, a_el, zero(ArbDigit))
        iszero(carry) && break
    end

    carry
end

function add2!(a::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit})
    carry = _add2!(a, b)
    @assert iszero(carry)
end

"""
    add!(a, b)

    Adds b to a, saving the result in a. Returns a.
"""
function add! end

function add!(a::ArbUInt, b::ArbUInt)
    a_len = length(a.data)
    carry = if a_len < length(b.data)
        lo_carry = _add2!(a.data, @view(b.data[1:a_len]))
        append!(a.data, @view(b.data[a_len+1:end]))
        _add2!(@view(a.data[a_len+1:end]), lo_carry)
    else
        _add2!(a.data, b.data)
    end
    if !iszero(carry)
        push!(a.data, carry)
    end
    a
end

function add!(a::ArbUInt, b::ArbDigit)
    iszero(b) && return a
    if isempty(a.data)
        push!(a.data, b)
        return a
    end
    carry = _add2!(a.data, b)
    !iszero(carry) && push!(a.data, carry)
    a
end

function add!(a::ArbUInt, b::DoubleArbDigit)
    hi, lo = fromDoubleArbDigit(b)
    if iszero(hi)
        add!(a, lo)
    else
        while length(a.data) < 2
            push!(a.data, 0)
        end

        # TODO: get rid of this allocation
        carry = _add2!(a.data, [lo, hi])
        !iszero(carry) && push!(a.data, carry)
    end
    a
end

# define the 128 bit method if we have 32 bit digits
if DoubleArbDigit === UInt64
    function add!(a::ArbUInt, b::UInt128)
        if b <= typemax(UInt64)
            add!(a, UInt64(b))
        else
            a,b,c,d = u32_from_u128(b)
            carry = if a > 0
                while length(a.data) < 4
                    push!(a.data, 0)
                end
                _add2!(a.data, [d, c, b, a])
            else
                @assert b > 0
                while length(a.data) < 3
                    push!(a.data, 0)
                end
                _add2!(a.data, [d, c, b])
            end

            !iszero(carry) && push!(a.data, carry)
        end
        a
    end
end

# fallback gracefully to copying interface
Base.:(+)(a::DoubleArbDigit, b::ArbUInt) = add!(deepcopy(b), a)
Base.:(+)(a::ArbUInt, b::DoubleArbDigit) = add!(deepcopy(a), b)
Base.:(+)(a::Unsigned, b::ArbUInt) = add!(deepcopy(b), convert(ArbDigit, a))
Base.:(+)(a::ArbUInt, b::Unsigned) = add!(deepcopy(a), convert(ArbDigit, b))
Base.:(+)(a::ArbUInt, b::ArbUInt) = length(a.data) >= length(b.data) ? add!(deepcopy(a), b) : add!(deepcopy(b), a)
Base.:(+)(b::Signed, a::ArbUInt) = +(a,b)
Base.:(+)(_::ArbUInt, b::BigInt) = throw(ArgumentError("addition with BigInt not implemented"))
function Base.:(+)(a::ArbUInt, b::Signed)
    if b < 0
        a - abs(b)
    else
        a + unsigned(b)
    end
end

function (::Type{T})(x::ArbUInt) where T<:Base.BitUnsigned
    if iszero(x)
        return zero(T)
    elseif isone(length(x.data))
        return convert(T, x.data[1])
    else
        throw(InexactError(nameof(T), T, x))
    end
end

function (::Type{T})(x::ArbUInt) where T<:Base.BitSigned
    if iszero(x)
        return zero(T)
    elseif isone(length(x.data))
        return convert(T, x.data[1])
    else
        throw(InexactError(nameof(T), T, x))
    end
end
