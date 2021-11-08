function Base.string(a::ArbUInt; base::Int=16, pad::Int=1)
    bufSize = max(pad, stringsize(a, base))
    buf = Base.StringVector(bufSize)
    stringify!(buf, a, base)
    return String(buf)
end

"""
    stringsize(num::ArbUInt, base)

Returns the number of characters required to represent `num` in the given `base`.
"""
function stringsize(a::ArbUInt, base)
    base == 1 && throw(ArgumentError("Base has to be >= 2"))

    # trivial case
    iszero(a) && return 1

    if base == 2
        return length(a.data)*sizeof(ArbDigit)*8 - leading_zeros(a)
    elseif base == 16
        retsize = (length(a.data)-1)*16 # remaining data
        nleading_bits = sizeof(ArbDigit)*8 - leading_zeros(a)
        nnibblesLB = div(nleading_bits, 4)
        retsize += nnibblesLB
        retsize += nnibblesLB*4 < nleading_bits
        return retsize
    else
        throw(ArgumentError("stringsize for base $base is not implemented yet"))
    end
end

"""
    stringify!(buffer, num::ArbUInt, base)

Writes a string representation of `num` in base `base` to `buffer`. If the string representation of `num` is shorter than `buffer`, leading entries in `buffer` are filled with `'0'`.
"""
function stringify!(buf, a::ArbUInt, base)
    requiredSize = stringsize(a, base)
    length(buf) < requiredSize && throw(ArgumentError("buffer not large enough to hold string"))
    if base == 16
        bufIdx = length(buf) - requiredSize + 1
        buf[begin:bufIdx] .= 0x30
        iszero(a) && return

        numIdx = lastindex(a.data)
        digit = a.data[numIdx]
        # write the leading digit specially - we may not want to pad here
        shiftFactor = div(leading_zeros(digit), 4)
        sh = sizeof(ArbDigit)*8 - 4*shiftFactor
        @inbounds while !iszero(sh)
            sh -= 4
            lo = ((digit >> sh) % UInt8) & 0x0f
            # 'a' - '0' - 0xa = 0x27
            buf[bufIdx] = lo + 0x30 + (lo >= 0xa)*0x27
            bufIdx += 1
        end
        numIdx -= 1

        # now for the remaining data
        nwrites = 2*sizeof(ArbDigit)
        @inbounds while numIdx > 0
            sh = sizeof(ArbDigit)*8 - 4
            digit = a.data[numIdx]
            for _ in 0:nwrites-1
                lo = ((digit >> sh) % UInt8) & 0x0f
                buf[bufIdx] = lo + 0x30 + (lo >= 0xa)*0x27
                sh -= 4
                bufIdx += 1
            end
            numIdx -= 1
        end
    else
        throw(ArgumentError("stringification for base $base is not implemented yet"))
    end
end


function Base.parse(::Type{ArbUInt}, str::AbstractString; base=16)
    !isascii(str) && throw(ArgumentError("Given string is not ASCII"))
    if base == 16
        !all(isxdigit, str) && throw(ArgumentError("Non-hex digit detected"))
    end
    parse(ArbUInt, codeunits(str); base)
end

function Base.parse(::Type{ArbUInt}, units::AbstractVector{UInt8}; base::Int=16)
    isempty(units) && return throw(ArgumentError("input string is empty"))
    # TODO: parsing assumes lower case for now

    if isone(length(units))
        lo = units[1]
        return ArbUInt(parse(ArbDigit, lo; base))
    end

    # trim leading zeros
    if units[1] == 0x30 && units[2] == 0x30 # zero?
        nonZeroIdx = findfirst(!=(0x30), units)
        nonZeroIdx === nothing && return zero(ArbUInt)
        units = @view units[nonZeroIdx-1:end]
    end

    parsed = if base == 16
        # one hex digit fills 4 bits => 2 hex chars per byte
        # we have sizeof(ArbDigit) bytes, so we have sizeof(ArbDigit)*2
        unitsPerDigit = sizeof(ArbDigit)*2
        if units[1] == 0x30 && units[2] == 0x78
            # there may be a `0x` prefix
            units = @view units[3:end]
        end

        len_data = length(units)
        nWholeDigits = div(len_data, unitsPerDigit)
        shortDigits = len_data - nWholeDigits*unitsPerDigit

        data = Vector{ArbDigit}(undef, nWholeDigits + !iszero(shortDigits))
        dataIdx = 1

        @inbounds for unitIdx in unitsPerDigit:unitsPerDigit:len_data
            slice = @view units[end-unitIdx+1:end-unitIdx+unitsPerDigit]
            digit = zero(ArbDigit)
            for i in 0:2:unitsPerDigit-1
                lo = slice[end-i]
                hi = slice[end-i-1]
                digit |= ((lo - 0x30 - (lo >= 0x61)*0x27) % ArbDigit) << (i*4)
                digit |= ((hi - 0x30 - (hi >= 0x61)*0x27) % ArbDigit) << (i*4+4)
            end
            data[dataIdx] = digit
            dataIdx += 1
        end

        @inbounds if !iszero(shortDigits)
            restIdxStart = 1
            leftover = @view units[restIdxStart:restIdxStart+shortDigits-1]
            digit = zero(ArbDigit)
            for i in 0:lastindex(leftover)-1
                nibble = leftover[end-i]
                digit |= ((nibble - 0x30 - (nibble >= 0x61)*0x27) % ArbDigit) << (i*4)
            end
            data[dataIdx] = digit
        end

        data
    else
        throw(ArgumentError("parsing for base $base is not implemented yet"))
    end

    return ArbUInt(parsed)
end
