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
function quick_seed(id)
    return UInt(id*1099087573)
end

# This is a linear congruential generator (LCG)
# This uses a default modulo 64 for UInt
function LCG_step(x::UInt, a::UInt, c::UInt)
    return UInt(a*x+c) #%m, where m = 64
end

# This is a combination of both
function simple_rand(x::Union{Int, UInt})

    return LCG_step(UInt(x), UInt(2862933555777941757), UInt(1))
end
