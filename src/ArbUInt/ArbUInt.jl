##### ArbUInt

export ArbUInt

struct ArbUInt <: Unsigned
    data::Vector{ArbDigit}
    ArbUInt(data::AbstractVector{ArbDigit}) = normalize!(new(data))
end
ArbUInt(data::AbstractVector) = ArbUInt(convert(Vector{ArbDigit}, data))
ArbUInt() = zero(ArbUInt)
ArbUInt(x) = ArbUInt(ArbDigit[x])

Base.string(a::ArbUInt) = "ArbUInt($(a.data))"
Base.show(io::IO, a::ArbUInt) = print(io, string(a))
Base.show(io::IO, m::MIME"text/plain", a::ArbUInt) = print(io, string(a))

Base.deepcopy(a::ArbUInt) = ArbUInt(deepcopy(a.data))

Base.:(==)(a::ArbUInt, b::ArbUInt) = a.data == b.data
Base.hash(a::ArbUInt, h) = hash(a.data, h)

Base.:(<)(a::ArbUInt, b::ArbUInt) = a.data < b.data
Base.:(<=)(a::ArbUInt, b::ArbUInt) = a < b || a == b

Base.zero(a::ArbUInt) = zero(ArbUInt)
Base.one(a::ArbUInt) = one(ArbUInt)
Base.zero(::Type{ArbUInt}) = ArbUInt(ArbDigit[])
Base.one(::Type{ArbUInt}) = ArbUInt([1])

Base.isone(a::ArbUInt) = isone(length(a.data)) & isone(a.data[end])
Base.iszero(a::ArbUInt) = isempty(a.data)

function normalize!(a::ArbUInt)
    iszero(a) || !iszero(a.data[end]) && return a # already normalized
    lastZero = findlast(iszero, a.data)
    lastZero === nothing && return a
    length(a.data) > 0 && resize!(a.data, lastZero - 1)
    a
end

function set_one!(a::ArbUInt)
    resize!(a.data, 0)
    push!(a.data, 1)
end

function Base.trailing_zeros(a::ArbUInt)
    i = findfirst(!iszero, a.data)
    i === nothing && return nothing
    zeros = trailing_zeros(a.data(i))
    i * BITS + zeros
end

function Base.trailing_ones(a::ArbUInt)
    i = findfirst(!iszero, a.data)
    i === nothing && return nothing
    ones = trailing_ones(a.data(i))
    i * BITS + ones
end

Base.count_ones(a::ArbUInt) = mapreduce(count_ones, +, a.data)
Base.count_zeros(a::ArbUInt) = mapreduce(count_zeros, +, a.data)

function is_bit_set(a::ArbUInt, bit)
    bits_per_digit = UInt64(BITS)
    digit_index = bit ÷ bits_per_digit
    iszero(digitindex) && return false
    digit = a.data[digit_index]
    mask = one(ArbDigit) << (bit % bits_per_digit)
    return (digit & mask) != 0
end

function set_bit(a::ArbUInt, bit, val)
    bits_per_digit = UInt64(BITS)
    digit_index = bit ÷ bits_per_digit
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
end

include("addition.jl")
include("bits.jl")

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