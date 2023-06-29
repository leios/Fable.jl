export FractalOperator, fo

function prob_check(probs::T) where T <: Tuple
    if eltype(probs) <: Number
        if !isapprox(sum(probs), 1)
            error("Fractal Operator probability != 1")
        end
    else
        for i = 1:length(probs)
            prob_check(probs[i])
        end
    end
end

struct FractalOperator
    ops::Tuple
    colors::Tuple
    probs::Tuple
    fnums::Union{Int, Tuple}
end

fo(args...; kwargs...) = FractalOperator(args...; kwargs...)

function FractalOperator(f::FractalUserMethod, c::FractalUserMethod)
    return FractalOperator((f,), (c,), (1.0,), (1,))
end

FractalOperator(f::FractalUserMethod) = FractalOperator((f,),
                                                        (Shaders.previous,),
                                                        (1.0,), (1,))
function FractalOperator(fums, colors, probs)
    if !isapprox(sum(probs), 1)
        error("Fractal Operator probability != 1")
    end

    if length(fums) != length(colors) || length(fums) != length(probs)
        error("Fractal Operators must have a color and probability"*
              " for each function!")
    end

    return FractalOperator(Tuple(fums), Tuple(colors),
                           Tuple(probs), (length(fums),))
end

FractalOperator(fo::FractalOperator) = fo

function FractalOperator(fos::T) where T <: Union{Vector{FractalOperator},
                                                  Tuple}
    fxs = (fos[1].ops,)
    clrs = (fos[1].colors,)
    fnums = (fos[1].fnums,)

    prob_check(fos[1].probs)
    probs = (fos[1].probs,)

    for i = 2:length(fos)
        curr_fo = fo(fos[i])
        fxs = (fxs..., curr_fo.ops)
        clrs = (clrs..., curr_fo.colors)
        fnums = (fnums..., curr_fo.fnums)

        prob_check(curr_fo.probs)
        probs = (probs..., curr_fo.probs)
    end

    return FractalOperator(fxs, clrs, probs, fnums)
end

function extract_info(fos::T) where T <: Union{Tuple, Vector{FractalOperator}}
    return extract_info(fo(fos))
end

function extract_info(fo::FractalOperator)
    info = extract_ops_info(fo.ops)
    color_info = extract_ops_info(fo.colors)
    return (info, color_info, flatten(fo.probs), flatten(fo.fnums))
end

flatten(t) = t

function flatten(t::Tuple)
    new_tuple = flatten(t[1])
    for i = 2:length(t)
        new_tuple = (new_tuple..., flatten(t[i])...)
    end
    return new_tuple
end

function extract_ops_info(ops::Tuple)
    kwargs, fis, fxs = extract_ops_info(ops[1])
    kwargs = (kwargs,)
    fis = (fis,)
    fxs = (fxs,)
    for i = 2:length(ops)
        new_kwargs, new_fis, new_fxs = extract_ops_info(ops[i])
        kwargs = (kwargs..., new_kwargs)
        fis = (fis..., new_fis)
        fxs = (fxs..., new_fxs)
    end
    return (kwargs, fis, fxs)
end

function extract_ops_info(op::FractalUserMethod)
    return (op.kwargs, op.fis, op.fx)
end
