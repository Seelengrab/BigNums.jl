function macWithCarry(a::ArbDigit, b::ArbDigit, c::ArbDigit, carry::DoubleArbDigit)
    @assert carry < (one(DoubleArbDigit) << BITS)
    carry += DoubleArbDigit(a) + DoubleArbDigit(b) * DoubleArbDigit(c)
    return carry % ArbDigit, carry >> BITS
end

function mulWithCarry(a::ArbDigit, b::ArbDigit, cin::DoubleArbDigit)
    cout = DoubleArbDigit(a) * DoubleArbDigit(b) + cin
    return cout % ArbDigit, cout >> BITS
end

function macDigit!(acc::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit}, c::ArbDigit)
    iszero(c) && return
    # we need to make sure that we have enough space
    # meaning length(b) +1 for carry
    @assert length(acc) > length(b) "accumulator needs extra space for carry!"

    carry = zero(DoubleArbDigit)
    a_lo = @view acc[begin:length(b)]
    a_hi = @view acc[length(b)+1:end]

    # we want to add `b*c+carry` into `acc`,
    # so we add elementwise into the lower
    # length(b) digits of `acc`.
    # whatever is left over is our true carry.
    for (a,(i,b)) in zip(a_lo, enumerate(b))
        a_lo[i], carry = macWithCarry(a, b, c, carry)
    end

    carry_hi, carry_lo = fromDoubleArbDigit(carry)

    # if we have carry from multiplying, we add it here
    final_carry = if iszero(carry_hi)
        _add2!(a_hi, carry_lo)
    else
        _add2!(a_hi, [carry_hi, carry_lo])
    end

    # there should never be anything left over
    # i.e. if this assert fires, the one above
    # should also have fired already or acc was
    # not filled with zeros
    @assert iszero(final_carry) "carry overflow during multiplication!"
end

function long_mul!(acc::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit}, c::AbstractVector{ArbDigit})
    # naive long multiplication
    # multiply each digit of `c` with `b` and
    # write to `acc`
    for (i,ci) in enumerate(c)
        macDigit!(@view(acc[i:end]), b, ci)
    end
end

function karatsuba!(acc::AbstractVector{ArbDigit}, a::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit})
    #= karatsuba multiplication
      exponents are just for numbering, not power function
      power is denoted by ^

      write x*y in two parts:
      a = a¹ * sh + a²
      b = b¹ * sh + b²

      now this becomes
      a*b = (a¹ * sh + a²) * (b¹ * sh + b²)
          =  a¹ * b¹            * sh^2
          + (a² * b¹ + a¹ * b²) * sh
          +  a² * b²

      now set p¹ = a¹ * b¹ and p³ = a² * b²:
      a*b =  p¹                 * sh^2
          + (a² * b¹ + a¹ * b²) * sh
          +  p³

      here comes karatsuba's trick:
              a¹ * b² + a² * b¹
          =   a¹ * b² + a² * b¹ - p¹ + p¹ - p³ + p³
          =   a¹ * b² + a² * b¹ - a¹ * b¹ - a² * b²  + p¹ + p³
          = -(a¹ * b¹ - a¹ * b² - a² * b¹ + a² * b²) + p¹ + p³
          = -((a² - a¹) * (b² - b¹))                 + p¹ + p³

      so we now have p² = (a² - a¹) * (b² - b¹) and thus
      a*b = p¹             * sh^2
          + (p¹ + p³ - p²) * sh
          + p³

      so our intermediate products are
      p¹  = a¹ * b¹
      p²  = (a² - a¹) * (b² - b¹)
      p³  = a² * b²

      which we can use to rearrange the above like so
      a*b = p¹ * sh^2
          + p¹ * sh
          + p³ * sh
          - p² * sh
          + p³
          = p³
          + p³ * sh
          + p¹ * sh
          + p¹ * sh^2
          - p² * sh
      with evaluation order from top to bottom. This means,
      by offsetting our index instead of really multiplying
      by `sh`, we can only calculate p¹, p² and p³ once each
      and reuse the result when adding. Subtracting p²*sh at
      the end is done to ensure we don't go negative. An
      informal argument for that is that we're multiplying
      positive integers - that can't ever give a negative
      result and since all transformations above are valid,
      the result has to be positive as well. However, to ensure
      we don't go negative during an intermediate step, we
      make sure to subtract as the last step.
    =#

    short, long = length(a) < length(b) ? (a,b) : (b,a)
    @assert length(short) <= length(long)
    @assert length(acc) >= length(short)+length(long)

    short_half_len = div(length(short), 2)
    short² = @view short[begin:short_half_len]
    short¹ = @view short[short_half_len+1:end]
    long²  = @view  long[begin:short_half_len]
    long¹  = @view  long[short_half_len+1:end]

    # uppers are longer, so we need at most that space
    p_len = length(short¹) + length(long¹)
    p = Vector{ArbDigit}(undef, p_len)
    p_num = ArbUInt(p)

    resize!(p, p_len)
    fill!(p, zero(ArbDigit))

    # p³ = a² * b²
    mac3!(p, short², long²)
    normalize!(p_num) # remove excess zeros
    # acc += p³
    add2!(acc, p)

    # acc += p³*sh
    add2!(@view(acc[short_half_len+1:end]), p)

    # zero buffer
    resize!(p, p_len)
    fill!(p, zero(ArbDigit))

    # p¹ = a¹ * b¹
    mac3!(p, short¹, long¹)
    normalize!(p_num) # remove excess zeros
    # acc += p¹*sh
    add2!(@view(acc[short_half_len+1:end]), p)

    # acc += p¹*sh^2
    add2!(@view(acc[2*short_half_len+1:end]), p)

    # now for p²
    # p²  = (a² - a¹) * (b² - b¹)
    # tmp¹  = a² - a¹
    # tmp²  = b² - b¹
    # this could be negative, so we have to take care
    sign¹, tmp¹ = sub_sign(short², short¹)
    sign², tmp² = sub_sign(long², long¹)

    if sign¹ * sign² > 0
        # both subtractions are positive, so we
        # have to _subtract_ from acc
        resize!(p, p_len)
        fill!(p, zero(ArbDigit))

        mac3!(p, tmp¹, tmp²)
        normalize!(p_num) # remove excess zeros

        # acc -= p²*sh
        sub2!(@view(acc[short_half_len+1:end]), p)

    elseif sign¹ * sign² < 0
        # one subtraction is negative, so we
        # have to _add_ to acc
        mac3!(@view(acc[short_half_len+1:end]), tmp¹, tmp²)

    else
        # one of the subtractions results in 0
        # we don't have to do anything!
    end

    # we're a mutating function - so return nothing
    return nothing
end

function mac3!(acc::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit}, c::AbstractVector{ArbDigit})
    if !iszero(length(b)) && iszero(first(b))
        nz = findfirst(!iszero, b)
        nz === nothing && return # only zeros!
        b = @view b[nz:end]
        acc = @view acc[nz:end]
    end
    if !iszero(length(c)) && iszero(first(c))
        nz = findfirst(!iszero, c)
        nz === nothing && return # only zeros!
        c = @view c[nz:end]
        acc = @view acc[nz:end]
    end

    short, long = length(b) < length(c) ? (b,c) : (c,b)

    if length(short) <= 32
        long_mul!(acc, long, short)
    else #if length(short) <= 256
        karatsuba!(acc, long, short)
    #else
        # TODO: implement Toom-3  multiplication for numbers larger than 256 digits
        #throw(ArgumentError("Multiplication for numbers with more than 256 digits has not been implemented yet."))
    end
end

function sub_sign(a::AbstractVector{ArbDigit}, b::AbstractVector{ArbDigit})
    if !isempty(a) && iszero(last(a))
        idx = something(findlast(!iszero, a), 0)
        a = @view a[begin:idx]
    end
    if !isempty(b) && iszero(last(b))
        idx = something(findlast(!iszero, b), 0)
        b = @view b[begin:idx]
    end

    ret = if a == b
        (0, ArbDigit[])
    elseif _less(<, a, b)
        retArr = copy(b)
        sub2!(retArr, a)
        (-1, retArr)
    else
        retArr = copy(a)
        sub2!(retArr, b)
        (1, retArr)
    end
    return ret
end

function mul3(x::AbstractVector{ArbDigit}, y::AbstractVector{ArbDigit})
    len = length(x) + length(y)
    prod = zeros(ArbDigit, len)

    mac3!(prod, x, y)
    ArbUInt(prod)
end

function scalar_mul!(a::ArbUInt, b::ArbDigit)
    if iszero(b)
        set_zero!(a)
    elseif isone(b)
        return
    else
        if ispow2(b)
            # this will break with too large numbers
            shl!(a, trailing_zeros(b))
        else
            carry = zero(DoubleArbDigit)
            for i in eachindex(a.data)
                a[i], carry = mulWithCarry(a[i], b, carry)
            end
            !iszero(carry) && push!(a.data, carry % ArbDigit)
        end
    end
end

Base.:(*)(a::ArbUInt, b::ArbUInt) = mul3(a.data, b.data)
Base.:(*)(a::ArbUInt, b::Unsigned) = scalar_mul!(deepcopy(a), ArbDigit(b))
Base.:(*)(b::Unsigned, a::ArbUInt) = scalar_mul!(deepcopy(a), ArbDigit(b))
