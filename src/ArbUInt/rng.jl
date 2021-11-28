using Random: Random, AbstractRNG, Repetition, Sampler, rand!

struct SamplerRangeArbUInt{SP<:Sampler{ArbDigit}} <: Sampler{ArbUInt{T} where T}
    start::ArbUInt
    gen::ArbUInt
    ndigits::Int
    nmaxdigits::Int
    highsp::SP
end

function SamplerRangeArbUInt(::Type{RNG}, r::AbstractUnitRange{<:ArbUInt}, N::Repetition=Val(Inf)) where {RNG <: AbstractRNG}
    isempty(r) && throw(ArgumentError("range must be non-empty"))
    gen = last(r) - first(r)
    ndigits = length(gen.data)
    hm = iszero(ndigits) ? zero(ArbDigit) : last(gen.data)
    highsp = Sampler(RNG, zero(ArbDigit):hm, N)
    nmaxdigits = max(ndigits, length(last(r).data), length(first(r).data))
    return SamplerRangeArbUInt(first(r), gen, ndigits, nmaxdigits, highsp)
end

Random.Sampler(::Type{RNG}, r::AbstractUnitRange{<:ArbUInt}, N::Repetition) where {RNG <: AbstractRNG} = SamplerRangeArbUInt(RNG, r, N)

Random.rand(rng::AbstractRNG, sp::SamplerRangeArbUInt) = rand!(rng, zero(ArbUInt), sp)

function Random.rand!(rng::AbstractRNG, a::ArbUInt, sp::SamplerRangeArbUInt)
    ndigits = sp.ndigits
    iszero(sp.ndigits) && return set_zero!(a)
    buf = a.data
    resize!(buf, sp.nmaxdigits)
    hm = last(sp.gen.data)
    while true
        rand!(rng, buf)
        hx = buf[ndigits] = rand(rng, sp.highsp)
        hx <= hm && break
        _less(<, buf, sp.gen.data) && break
    end
    add!(a, sp.start)
end
