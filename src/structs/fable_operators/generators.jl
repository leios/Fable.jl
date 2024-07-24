#-------------generators.jl----------------------------------------------------#
#
# Purpose: Generators are types used to determine how the final `run` function
#          is `@generated` at the end. To see how this works, look at the 
#          files in the `run/` directory as well as in `fable_operators.jl`
#
#------------------------------------------------------------------------------#
export AbstractGenerator, ChaosGenerator, StandardGenerator

abstract type AbstractGenerator end;

struct ChaosGenerator{A, I <: Integer,
                      P <: Tuple, F <: Tuple} <: AbstractGenerator
    args::A
    iterations::I
    prob_set::P
    fnums::F
end

struct StandardGenerator{A, ND} <: AbstractGenerator
    args::A
    ndrange::ND
end

# For post transformations
struct SequentialGenerator{A, ND} <: AbstractGenerator
    args::A
    ndrange::ND
end

struct RandomGenerator{A, ND} <: AbstractGenerator
    args::A
    ndrange::ND
end
