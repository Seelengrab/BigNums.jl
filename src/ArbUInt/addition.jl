### ADDITION ###

"""
    adc(c_in, a, b)

    Calculates the sum of carry_in, a and b and returns their sum as well as an UInt8 for carry_out. 
"""
function adc(c_in, a::ArbDigit, b::ArbDigit)::Tuple{ArbDigit, Bool}
    s = DoubleArbDigit(a) + DoubleArbDigit(b) + DoubleArbDigit(c_in)
    hi, lo = fromDoubleArbDigit(s)
    lo, !iszero(hi)
end

function _add2!(a::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit})
    # assumes length(a) >= length(b), returns carry
    a_lo = @view a[begin:length(b)]
    a_hi = @view a[length(b)+1:end]
    
    carry = zero(UInt8)
    @inbounds for (i,(a_el,b_el)) in enumerate(zip(a_lo, b))
        a_lo[i], carry = adc(carry, a_el, b_el)
    end

    if !iszero(carry)
        carry = _add2!(a_hi, carry)
    end
    
    carry
end

function _add2!(a::AbstractVector{ArbDigit}, carry)
    for (i,a_el) in enumerate(a)
        # TODO: can we do this faster, without going up in size?
        a[i], carry = adc(carry, a_el, ArbDigit(0))
        iszero(carry) && break
    end
    
    carry
end

# function add2!(a::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit})
#     carry = _add2!(a, b)
#     @assert iszero(carry)
# end

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
Base.:(+)(a::UInt128, b::ArbUInt) = add!(deepcopy(b), a)
Base.:(+)(a::ArbUInt, b::UInt128) = add!(deepcopy(a), b)
Base.:(+)(a::Unsigned, b::ArbUInt) = add!(deepcopy(b), convert(ArbDigit, a))
Base.:(+)(a::ArbUInt, b::Unsigned) = add!(deepcopy(a), convert(ArbDigit, b))
Base.:(+)(a::ArbUInt, b::ArbUInt) = length(a.data) >= length(b.data) ? add!(deepcopy(a), b) : add!(deepcopy(b), a)