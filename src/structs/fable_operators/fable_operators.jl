export FableOperator, fo

struct FableOperator{G, F, KW} where {G <: AbstractGenerator,
                                      F <: Function, KW <: Tuple,
    gen::G
    fx::F
    kwargs::KW
end

"""
    @fo generator fxs = (fum_1, fum_2, fum_3) colors = (clr_1, clr_2, clr_3)

Will create a Fable Operator with a function that combines all the Fable User
Methods and associated colors.
"""
macro fo(gen, args...)
    if gen == :RandomGenerator
        expr = generate_random_fo(args...)
    else
        error("Unknown generator: ", gen, "!")
    end
end

@generated function fo(generator::G, fums, colors) where G <: AbstractGenerator
end
