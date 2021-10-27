# Function definitions for interop w/ PropCheck.jl
# seperated into their own file to make reproducing tests easier

genArbUInt(i=igen(0x5)) = Integrated(Generator{ArbUInt}(rng -> ArbUInt(root(generate(rng, PropCheck.vector(i, igen(ArbDigit)))))))
PropCheck.generate(rng, ::Type{ArbUInt}) = root(generate(rng, genArbUInt()))
function PropCheck.shrink(t::ArbUInt)
    shrunks = shrink(reverse(t.data))
    isempty(shrunks) && return unique!(shrunks)
    finalize = ArbUInt ∘ reverse!
    lower_zeroed = copy(t.data)
    lower_zeroed[begin:div(end,2)] .= zero(ArbDigit)
    customs = Iterators.map(finalize, [
        t.data[begin:div(end,2)],
        lower_zeroed
    ])
    PropCheck.iunique(customs, Iterators.map(finalize, shrunks))
end
