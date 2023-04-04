export FractalOperator, fo

struct FractalOperator
    op::FractalUserMethod
    color::FractalUserMethod
    prob::Number
end

fo(args...; kwargs...) = FractalOperator(args...; kwargs...)

FractalOperator(f::FractalUserMethod) = FractalOperator(f,
                                                        Shaders.previous,
                                                        1)
FractalUserMethod(f::FractalOperator) = f.op
