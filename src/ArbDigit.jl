if UInt64Digit[]
    const ArbDigit = UInt64
    const DoubleArbDigit = UInt128
    const SignedDoubleArbDigit = Int128
else
    const BigDigit = UInt32
    const DoubleArbDigit = UInt64
    const SignedDoubleArbDigit = Int64
end

const BITS = UInt8(8 * sizeof(ArbDigit))
const HALF_BITS = BITS ÷ 2
const HALF = ArbDigit((1 << HALF_BITS) - 1)
const LO_MASK = DoubleArbDigit(typemax(ArbDigit))
const MAX = ArbDigit(LO_MASK)

highBits(n) = ArbDigit(n >> BITS)
lowBits(n) = ArbDigit(n & LO_MASK)

fromDoubleArbDigit(n) = (highBits(n), lowBits(n))
toDoubleArbDigit(hi, lo) = DoubleArbDigit(lo) | (DoubleArbDigit(hi) << BITS)