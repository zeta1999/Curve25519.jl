# from backend/serial/scalar_mul/variable_base.rs
function scalar_mul__variable_base__mul(point::EdwardsPoint{T}, scalar::Z) where {T, Z}
# Perform constant-time, variable-base scalar multiplication.
    # Construct a lookup table of [P,2P,3P,4P,5P,6P,7P,8P]
    lookup_table = lookup_table_from(point)
    #=
    // Setting s = scalar, compute
    //
    //    s = s_0 + s_1*16^1 + ... + s_63*16^63,
    //
    // with `-8 ≤ s_i < 8` for `0 ≤ i < 63` and `-8 ≤ s_63 ≤ 8`.
    =#
    scalar_digits = to_radix_16(scalar)
    #=
    // Compute s*P as
    //
    //    s*P = P*(s_0 +   s_1*16^1 +   s_2*16^2 + ... +   s_63*16^63)
    //    s*P =  P*s_0 + P*s_1*16^1 + P*s_2*16^2 + ... + P*s_63*16^63
    //    s*P = P*s_0 + 16*(P*s_1 + 16*(P*s_2 + 16*( ... + P*s_63)...))
    //
    // We sum right-to-left.
    =#

    # Unwrap first loop iteration to save computing 16*identity
    #let mut tmp2;
    tmp3 = zero(EdwardsPoint{T})
    tmp1 = tmp3 + select(lookup_table, scalar_digits[63+1])
    # Now tmp1 = s_63*P in P1xP1 coords
    for i in 62:-1:0
        tmp2 = to_projective(tmp1) # tmp2 =    (prev) in P2 coords
        tmp1 = double(tmp2)        # tmp1 =  2*(prev) in P1xP1 coords
        tmp2 = to_projective(tmp1) # tmp2 =  2*(prev) in P2 coords
        tmp1 = double(tmp2)        # tmp1 =  4*(prev) in P1xP1 coords
        tmp2 = to_projective(tmp1) # tmp2 =  4*(prev) in P2 coords
        tmp1 = double(tmp2)        # tmp1 =  8*(prev) in P1xP1 coords
        tmp2 = to_projective(tmp1) # tmp2 =  8*(prev) in P2 coords
        tmp1 = double(tmp2)        # tmp1 = 16*(prev) in P1xP1 coords
        tmp3 = to_extended(tmp1)   # tmp3 = 16*(prev) in P3 coords
        tmp1 = tmp3 + select(lookup_table, scalar_digits[i+1])
        # Now tmp1 = s_i*P + 16*(prev) in P1xP1 coords
    end
    to_extended(tmp1)
end
