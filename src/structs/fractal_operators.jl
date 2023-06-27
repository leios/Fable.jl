export FractalOperator, fo

struct FractalOperator
    ops::Tuple
    colors::Tuple
    probs::Tuple
end

fo(args...; kwargs...) = FractalOperator(args...; kwargs...)

function FractalOperator(f::FractalUserMethod, c::FractalUserMethod)
    return FractalOperator((f,), (c,), (1.0,))
end

FractalOperator(f::FractalUserMethod) = FractalOperator((f,),
                                                        (Shaders.previous,),
                                                        (1.0,))
function FractalOperator(fums, colors, probs)
    if !isapprox(sum(probs), 1)
        error("Fractal Operator probability != 1")
    end

    if length(fums) != length(colors) || length(fums) != length(probs)
        error("Fractal Operators must have a color and probability"*
              " for each function!")
    end

    return FractalOperator(Tuple(fums), Tuple(colors), Tuple(probs))
end

function FractalOperator(fos::T) where T <: Union{Vector{FractalOperator},
                                                  Tuple}
    fxs = fos[1].ops
    clrs = fos[1].colors

    if !isapprox(sum(fos[1].probs), 1)
        error("Fractal Operator probability != 1")
    end
    probs = fos[1].probs

    for i = 2:length(fos)
        fxs = (fxs, fos[i].ops)
        clrs = (clrs, fos[i].colors)

        if !isapprox(sum(fos[i].probs), 1)
            error("Fractal Operator probability != 1")
        end
        probs = (probs, fos[i].probs)
    end

    return FractalOperator(fxs, clrs, probs)
end
