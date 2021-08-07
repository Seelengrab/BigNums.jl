################
#### bitwise and
################

function bitand!(a::ArbUInt, b::ArbUInt)
    # writes to a
    for i in 1:min(length(a.data), length(b.data))
        a.data[i] &= b.data[i]
    end
    resize!(a.data, min(length(a.data), length(b.data)))
    normalize!(a)
end

function bitand!(a::ArbUInt, b::T) where T <: Unsigned
    if sizeof(ArbDigit) >= sizeof(T)
        resize!(a.data, 1)
        a.data[begin] &= ArbDigit(b)
    else
        resize!(a.data, sizeof(T) ÷ sizeof(ArbDigit))
        a.data .&= reinterpret(ArbDigit, [b])
    end
    a
end

function Base.:(&)(a::ArbUInt, b::ArbUInt)
    short, long = length(a.data) <= length(b.data) ? (a,b) : (b,a)    
    bitand!(deepcopy(short), long)
end
function Base.:(&)(a::ArbUInt, b::T) where T <: Unsigned
    if sizeof(ArbDigit) >= sizeof(T)
        return ArbUInt(a.data[begin] & b)
    end
    n_data = a.data[begin:(sizeof(T) ÷ sizeof(ArbDigit))]
    bitand!(ArbUInt(n_data), b) # don't have to keep the upper bits!
end
Base.:(&)(a::T, b::ArbUInt) where T <: Unsigned = b & a 

###############
#### bitwise or
###############

function bitor!(a::ArbUInt, b::ArbUInt)
    # writes to a
    for i in 1:min(length(a.data), length(b.data))
        a.data[i] |= b.data[i]
    end
    if length(b.data) > length(a.data)
        append!(a.data, @view(b.data[length(a.data)+1:end]))
    end
    a
end

function bitor!(a::ArbUInt, b::T) where T <: Unsigned
    # writes to a
    if sizeof(ArbDigit) >= sizeof(T)
        iszero(a) && push!(a.data, zero(ArbDigit))
        a.data[begin] |= ArbDigit(b)
    else
        mod_size = (sizeof(T)÷sizeof(ArbDigit))
        if length(a.data) < mod_size
            old_length = length(a.data)
            resize!(a.data, mod_size)
            a.data[old_length + 1:end] .= zero(ArbDigit)
        end
        a.data[begin:mod_size] .|= reinterpret(ArbDigit, [b])
    end
    normalize!(a)
end

function Base.:(|)(a::ArbUInt, b::ArbUInt)
    short, long = length(a.data) <= length(b.data) ? (a,b) : (b,a)
    bitor!(deepcopy(long), short) # gotta keep the upper bits
end
Base.:(|)(a::ArbUInt, b::T) where T <: Unsigned = bitor!(deepcopy(a), b)
Base.:(|)(a::T, b::ArbUInt) where T <: Unsigned = bitor!(deepcopy(b), a)

################
#### bitwise xor
################

function bitxor!(a::ArbUInt, b::ArbUInt)
    for i in 1:min(length(a.data), length(b.data))
        a.data[i] ⊻= b.data[i]
    end
    if length(b.data) > length(a.data)
        append!(a.data, @view(b.data[length(a.data)+1:end]))
    end
    normalize!(a)
end

function bitxor!(a::ArbUInt, b::T) where T <: Unsigned
    if sizeof(ArbDigit) >= sizeof(T)
        iszero(a) && push!(a.data, zero(ArbDigit))
        a.data[begin] ⊻= ArbDigit(b)
    else
        mod_size = (sizeof(T)÷sizeof(ArbDigit))
        if length(a.data) < mod_size
            old_length = length(a.data)
            resize!(a.data, mod_size)
            a.data[old_length + 1:end] .= zero(ArbDigit)
        end
        a.data[begin:mod_size] .⊻= reinterpret(ArbDigit, [b])
    end
    normalize!(a)
end

function Base.:(⊻)(a::ArbUInt, b::ArbUInt)
    short, long = length(a.data) <= length(b.data) ? (a,b) : (b,a)
    bitxor!(deepcopy(long), short) # gotta keep the upper bits
end
Base.:(⊻)(a::ArbUInt, b::T) where T <: Unsigned = bitxor!(deepcopy(a), b)
Base.:(⊻)(a::T, b::ArbUInt) where T <: Unsigned = bitxor!(deepcopy(b), a)