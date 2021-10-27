function Base.string(a::ArbUInt; base::Int=16, pad::Int=1)
    buf = Base.StringVector(stringsize(a, base, pad))
    stringify!(buf, a, base, pad)
    return String(buf)
end

function stringsize(a::ArbUInt, base, pad)
    if base == 16
        retsize = (length(a.data)-1)*16 # remaining data
        nleading_bits = sizeof(ArbDigit)*8 - leading_zeros(a)
        nnibblesLB = div(nleading_bits, 4)
        retsize += nnibblesLB
        retsize += nnibblesLB*4 < nleading_bits
        max(pad, retsize)
    else
        throw(ArgumentError("stringsize for base $base is not implemented yet"))
    end
end

function stringify!(buf, a::ArbUInt, base, pad)
    length(buf) < stringsize(a, base, pad) && throw(ArgumentError("buffer not large enough to hold string"))
    if base == 16
        bufIdx = 1

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
