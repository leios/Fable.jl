export FractalOperator, fo

struct FractalOperator
    op::FractalUserMethod
    color::Union{FractalUserMethod, Tuple}
    prob::Number
end

Base.length(fo::FractalOperator) = 1
fo(args...; kwargs...) = FractalOperator(args...; kwargs...)

function FractalOperator(f::FractalUserMethod, c::FractalUserMethod)
    return FractalOperator(f, c, 1.0)
end

FractalOperator(f::FractalUserMethod) = FractalOperator(f,
                                                        Shaders.previous,
                                                        1.0)
FractalUserMethod(f::FractalOperator) = f.op
