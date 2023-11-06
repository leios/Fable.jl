export quick_seed, simple_rand

# Numbers come from...
#@article{l1999tables,
#  title={Tables of linear congruential generators of different sizes and good lattice structure},
#  author={L’ecuyer, Pierre},
#  journal={Mathematics of Computation},
#  volume={68},
#  number={225},
#  pages={249--260},
#  year={1999},
#  url={https://www.ams.org/mcom/1999-68-225/S0025-5718-99-00996-5/S0025-5718-99-00996-5.pdf}
#}

# This is a quick and dirty method to generate a seed
@inline function quick_seed(id)
    return UInt(id*1099087573)
end

# This is a linear congruential generator (LCG)
# This uses a default modulo 64 for UInt
@inline function LCG_step(x::UInt, a::UInt, c::UInt)
    return UInt(a*x+c) #%m, where m = 64
end

# This is a combination of both
@inline function simple_rand(x::Union{Int, UInt})
    return LCG_step(UInt(x), UInt(2862933555777941757), UInt(1))
end

@inline function find_choice(prob_set, start, fnum, seed)
    rnd = seed/typemax(UInt)
    p = 0.0

    for i = start:start + fnum - 1
        @inbounds p += prob_set[i]
        if rnd <= p
            return i - start + 1
        end
    end

    return 0
end

# The fid (Function ID) is used to select which operation in a 
#   function system to select for each iteration.
# The fid could have multiple function systems in it. Quick example:
#     2 function systems (fs) with 3 and 5 functions respectively.
#     The fid might be 011 01, read from right to left
#     The first 2 digits, 01, represent a selection between 1 and 3 from fs 1
#     The second 3 digits, 011, represent a selection between 1 and 5 from fs 2
#     As a UInt, the value is saved as 25
# encoding an fid involves generating a random UInt and going through the
#   bitstring to ensure that each set of possible values is a possible option
@inline function create_fid(fnums, rng::UI) where UI <: Unsigned
    val = UI(0)
    offset = UI(0)

    for i = 1:length(fnums)
        # needed bits to hold the fnum
        @inbounds bitsize = ceil(UI, log2(fnums[i]))

        # set of 1's to mask only those bits in the rng string
        bitmask = UI(2^(bitsize + offset) - 1 - (2^offset - 1))

        # shifting the bits from rng over to read them as an int
        a = UI(((rng & bitmask) >> offset))

        # checking if that option is actually valid,
        # if not, using the rng string to create an adhoc new choice
        @inbounds begin
            if a+1 > fnums[i]
                a = UI(rng % fnums[i])
            end
        end

        # Shifting back to appropriate location
        b = a << offset

        # adding to final bitstring
        val += b

        # creating offset bit number for next iteration
        offset += bitsize
    end

    return val
end

@inline function create_fid(probs, fnums, seed, fx_offset)
    fid = UInt(0)
    bit_offset = 0
    @inbounds begin
        for i = 1:length(fnums)
            if probs[fx_offset] < 1
                seed = simple_rand(UInt(seed))
                choice = find_choice(probs, fx_offset, fnums[i], seed)
                fid += ((choice-1) << bit_offset)
                bit_offset += ceil(UInt, log2(fnums[i]))
            end
            fx_offset += fnums[i]
        end
    end
    return fid
end

@inline function create_fid(probs, fnums, seed)
    fid = UInt(0)
    bit_offset = 0
    fx_offset = 1
    @inbounds begin
        for i = 1:length(fnums)
            if probs[fx_offset] < 1
                seed = simple_rand(UInt(seed))
                choice = find_choice(probs, fx_offset, fnums[i], seed)
                fid += ((choice-1) << bit_offset)
                bit_offset += ceil(UInt, log2(fnums[i]))
            end
            fx_offset += fnums[i]
        end
    end
    return fid
end

# Decoding takes an offset, which is the number of digits on the fid bitstring
#   to ignore from the right hand side.
# Should probably add an error, but was afraid of the conditional
@inline function decode_fid(fid::UI, offset, fnum) where UI <: Unsigned
    bitsize = ceil(UI, log2(fnum))
    bitmask = UI(2^(bitsize + offset) - 1 - (2^offset - 1))
    value = UI((fid & bitmask) >> offset) + 1
    return value
end

@inline function find_random_fxs(fid::UI, fnums, probs) where UI <: Unsigned
    bit_offset = 0
    fx_offset = 0
    t_out = ()
    @inbounds begin
        for i = 1:length(fnums)
            idx = decode_fid(fid, bit_offset, fnums[i]) + fx_offset
            t_out = (t_out...,idx)
            bit_offset += ceil(UInt,log2(fnums[i]))
            fx_offset += fnums[i]
        end
    end

    return t_out
end
