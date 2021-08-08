#######################
#### bitwise shift left
#######################

function shift_left!(a::ArbUInt, shift::T) where T <: Integer
    shift < zero(T) && return shift_right!(a, abs(shift))
    iszero(shift) && return a
    bits = T(BITS)
    more_digits = shift ÷ bits
    more_digits > typemax(UInt) && throw(DomainError(shift, "requested shift too large to fit in memory"))
    more_digits = UInt(more_digits)
    shift = UInt8(shift % bits)
    _shift_left!(a, more_digits, shift)
end
const shl! = shift_left!

function _shift_left!(a::ArbUInt, new_digits::UInt, shift::UInt8)
    data = if iszero(new_digits)
        a.data
    else
        # we may crash here due to lack of memory, nothing we can do about that
        Base._growbeg0!(a.data, signed(new_digits) + 1) # REMOVEME: once we can grow with guaranteed zeroed memory, since this is internal
        a.data
    end

    one_based_digits = new_digits + 1
    if shift > 0
        carry = zero(eltype(data))
        carry_shift = UInt8(BITS) - shift
        for i in one_based_digits:lastindex(data)
            elem = data[i]
            new_carry = elem >> carry_shift
            data[i] = (elem << shift) | carry
            carry = new_carry
        end
    end

    normalize!(a) # unlike rust, we modify the original - not sure if that's a good idea
end

Base.:(<<)(a::ArbUInt, b::T) where T <: Integer = shift_left!(deepcopy(a), b)
Base.:(<<)(a::ArbUInt, b::T) where T <: Unsigned = shift_left!(deepcopy(a), b) # ambiguity
Base.:(<<)(_, b::ArbUInt) = throw(ArgumentError("can't leftshift by ArbUInt"))
Base.:(<<)(_::ArbUInt, _::ArbUInt) = throw(ArgumentError("can't leftshift ArbUInt by another ArbUInt"))

########################
#### bitwise shift right
########################

function shift_right!(a::ArbUInt, shift::T) where T <: Integer
    shift < zero(T) && return shift_left!(a, abs(shift))
    iszero(shift) && return a
    bits = T(BITS)
    more_digits = shift ÷ bits
    more_digits = more_digits > typemax(UInt) ? typemax(UInt) : UInt(more_digits)
    shift = UInt8(shift % bits)
    _shift_right!(a, more_digits, shift)
end
const shr! = shift_right!

function _shift_right!(a::ArbUInt, digits::UInt, shift::UInt8)
    digits >= length(data) && return set_zero!(a)
    data = @view a.data[digits:end]
    
    if shift > 0
        borrow = 0
        borrow_shift = UInt8(BITS) - shift
        for i in lastindex(data):-1:1
            elem = data[i]
            new_borrow = elem << borrow_shift
            data[i] = (elem >> shift) | borrow
            borrow = new_borrow
        end
    end
    
    # maybe dangerous when aliased? 
    a.data[1:length(a.data)-digits] .= data
    a # unlike rust, we modify the original
end

# this makes a surprising amount of sense
function Base.:(>>)(a::T, b::ArbUInt) where T <: Integer
    iszero(b) && return a
    if length(b.data) == 1
        return a >> b.data[begin]
    else
        return zero(T)
    end
end
Base.:(>>)(a::ArbUInt, b::T) where T <: Integer = shift_right!(deepcopy(a), b)
Base.:(>>)(_::ArbUInt, _::ArbUInt) = throw(ArgumentError("can't rightshift ArbUInt by another ArbUInt"))
