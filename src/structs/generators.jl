#-------------generators.jl----------------------------------------------------#
#
# Purpose: Generators are types used to determine how the final `run` function
#          is `@generated` at the end. To see how this works, look at the 
#          files in the `run/` directory
#
#------------------------------------------------------------------------------#
export AbstractGenerator, ChaosGenerator, StandardGenerator

abstract type AbstractGenerator end;

struct ChaosGenerator{A, I, P, F} where {I <: Integer, P <: Tuple, F <: Tuple}
    args::A
    iterations::I
    prob_set::P
    fnums::F
end

struct StandardGenerator{A, ND}
    args::A
    ndrange::ND
end
