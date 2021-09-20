##### ArbUInt

export ArbUInt

struct ArbUInt <: Unsigned
    data::Vector{ArbDigit}
    ArbUInt(data::AbstractVector{ArbDigit}) = normalize!(new(data))
end
ArbUInt(data::AbstractVector) = ArbUInt(convert(Vector{ArbDigit}, data))
ArbUInt() = zero(ArbUInt)
ArbUInt(x) = ArbUInt(ArbDigit[x])
ArbUInt(x::DoubleArbDigit) = ArbUInt(reverse!([fromDoubleArbDigit(x)...]))
if DoubleArbDigit === UInt64
    ArbUInt(x::UInt128) = ArbUInt(reverse!([u32_from_u128(x)...]))
end

Base.string(a::ArbUInt) = "ArbUInt($(a.data))"
Base.show(io::IO, a::ArbUInt) = print(io, string(a))
Base.show(io::IO, m::MIME"text/plain", a::ArbUInt) = print(io, string(a))

Base.deepcopy(a::ArbUInt) = ArbUInt(deepcopy(a.data))

Base.:(==)(a::ArbUInt, b::ArbUInt) = length(a.data) == length(b.data) && a.data == b.data
Base.hash(a::ArbUInt, h::UInt) = hash(a.data, h)

function Base.:(<)(a::ArbUInt, b::ArbUInt)
    length(a.data) < length(b.data) && return true
    length(a.data) > length(b.data) && return false
    return _less(a.data, b.data)
end
function _less(a, b)
    idx = lastindex(a) # we only hit this method when length(a) === length(b)
    isEq = a[idx] == b[idx]
    while isEq
        idx = prevind(a, idx)
        isEq = a[idx] == b[idx]
    end
    a[idx] < b[idx]
end

Base.zero(::Type{ArbUInt}) = ArbUInt(ArbDigit[])
Base.one(::Type{ArbUInt}) = ArbUInt([one(ArbDigit)])

Base.isone(a::ArbUInt) = isone(length(a.data)) && isone(a.data[end])
Base.iszero(a::ArbUInt) = isempty(a.data)

function normalize!(a::ArbUInt)
    isempty(a.data) && return a
    idx = lastindex(a.data)
    while checkbounds(Bool, a.data, idx) && iszero(a.data[idx])
        idx = prevind(a.data, idx)
    end
    resize!(a.data, idx)
    a
end

function set_one!(a::ArbUInt)
    resize!(a.data, 1)
    a.data[begin] = one(ArbDigit)
    a
end

function set_zero!(a::ArbUInt)
    resize!(a.data, 0)
    a
end

function Base.trailing_zeros(a::ArbUInt)
    i = findfirst(!iszero, a.data)
    i === nothing && return length(a.data) * BITS
    zeros = trailing_zeros(a.data[i])
    (i-1) * BITS + zeros
end

function Base.trailing_ones(a::ArbUInt)
    i = findfirst(!iszero, a.data)
    i === nothing && return 0
    ones = trailing_ones(a.data[i])
    (i-1) * BITS + ones
end

Base.leading_ones(a::ArbUInt) = leading_ones(first(a.data))
function Base.leading_zeros(a::ArbUInt)
    i = findlast(!iszero, a.data)
    i === nothing && return length(a.data) * BITS
    zeros = leading_zeros(a.data[i])
    (length(a.data) - i) * BITS + zeros
end

Base.count_ones(a::ArbUInt) = mapreduce(count_ones, +, a.data)
Base.count_zeros(a::ArbUInt) = mapreduce(count_zeros, +, a.data)

function is_bit_set(a::ArbUInt, bit)
    bits_per_digit = UInt(BITS)
    digit_index = bit ÷ bits_per_digit
    iszero(digitindex) && return false
    digit = a.data[digit_index]
    mask = one(ArbDigit) << (bit % bits_per_digit)
    return (digit & mask) != 0
end

function set_bit!(a::ArbUInt, bit, value)
    bits_per_digit = UInt(BITS)
    digit_index = bits_per_digit > bit ? typemax(UInt) : bit ÷ bits_per_digit
    mask = one(ArbDigit) << (bit % bits_per_digit)
    if value
        if digit_index > length(a.data)
            resize!(a.data, digit_index)
        end
        a.data[digit_index] |= mask
    elseif digit_index <= length(a.data)
        a.data[digit_index] &= ~mask
        normalize!(data)
    end
    a
end

include("addition.jl")
include("subtraction.jl")
include("bits.jl")
include("shifts.jl")

### SUBTRACTION ###

# TODO: Implement signed numbers

### MULTIPLICATION ###

function Base.:*(a::ArbUInt, b::UInt)
    # TODO: Implement multiplication with UInt
end

function mul(a::ArbUInt, b::ArbUInt)
    # TODO: Implement multiplication
end

### DIVISION ###

# TODO: Implement division

### POWER ###

# TODO: Implement power function

### MODULO ###

# TODO: Implement modulo arithmetic