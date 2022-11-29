if UInt64Digit[]
    const ArbDigit = UInt64
    const DoubleArbDigit = UInt128
    const SignedDoubleArbDigit = Int128
else
    const ArbDigit = UInt32
    const DoubleArbDigit = UInt64
    const SignedDoubleArbDigit = Int64
end

const BITS = UInt8(8 * sizeof(ArbDigit))
const HALF_BITS = BITS ÷ 2
const HALF = ArbDigit((1 << HALF_BITS) - 1)
const LO_MASK = DoubleArbDigit(typemax(ArbDigit))
const HI_MASK = ~LO_MASK
const MAX = ArbDigit(LO_MASK)

highBits(n) = (n >> BITS) % ArbDigit
lowBits(n) = (n & LO_MASK) % ArbDigit

fromDoubleArbDigit(n) = (highBits(n), lowBits(n))
toDoubleArbDigit(hi, lo) = DoubleArbDigit(lo) | (DoubleArbDigit(hi) << BITS)

function u32_to_u128(a::UInt32,b::UInt32,c::UInt32,d::UInt32)
    UInt128(d) | (UInt128(c) << 32) | (UInt128(c) << 64) | UInt128(c) << 96
end

function u32_from_u128(n)
    (
        (n >> 96) % UInt32,
        (n >> 64) % UInt32,
        (n >> 32) % UInt32,
        n % UInt32
    )
end
