# TODO: test -> rng and check variance
# This is a simple RNG generator following:
#@inproceedings{mohanty2012efficient,
#  title={Efficient pseudo-random number generation for monte-carlo simulations using graphic processors},
#  author={Mohanty, Siddhant and Mohanty, AK and Carminati, F},
#  booktitle={Journal of Physics: Conference Series},
#  volume={368},
#  number={1},
#  pages={012024},
#  year={2012},
#  url={http://iopscience.iop.org/article/10.1088/1742-6596/368/1/012024/pdf},
#  organization={IOP Publishing}
#}

# This is a quick and dirty method to generate a seed
function quick_seed(id)
    return UInt(id*1099087573)
end

# This does a Tausworthe step
# TODO: Carrot (^) needs to be corrected
function taus_step(z::UInt, s1::Int, s2::Int, s3::Int, M::UInt)
    b = UInt(((z<<s1)^z)>>s2)
    return UInt(((z&M)<<s3)^b)
end

# This is a linear congruential generator (LCG)
function LCG_step(z::UInt, A::UInt, C::UInt)
    return UInt(A*z+C)
end

# This is a combination of both
# TODO: figure out what to do about seeds
function simple_rand(id; z1 = 0, z2 = 0, z3 = 0, z4 = 0)
    seed = quick_seed(id)
    if z1 == 0
        z1 = quick_seed(id)
    end
    if z2 == 0
        z2 = quick_seed(id+1)
    end
    if z3 == 0
        z3 = quick_seed(id+2)
    end
    if z4 == 0
        z4 = quick_seed(id+3)
    end
    @print(z1, '\t', z2, '\t', z3, '\t', z4, '\n')
    #return 2.3283064365387e-10*(
    return (taus_step(z1, 13, 19, 12, UInt(4294967294)))
           #taus_step(z1, 13, 19, 12, UInt(4294967294)) ^
           #taus_step(z2, 2, 25, 4, UInt(4294967288)) ^
           #taus_step(z3, 3, 11, 17, UInt(4294967280)) ^
           #LCG_step(z4, UInt(1664525), UInt(1013904223)))
end
