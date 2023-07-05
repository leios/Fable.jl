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

FractalOperator(n::Nothing) = nothing

function FractalOperator(fum::FractalUserMethod, color::FractalUserMethod,
                         prob::Number)
    if !isapprox(prob, 1.0)
        @warn("Probabilities for FractalOperators should be 1!\n"*
              "Setting probability to 1!")
    end
    return FractalOperator((fum,), (color,), (1.0,), (1,))
end

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
        error("Fractal Operators must have a color and probability\n"*
              " for each function!")
    end

    return FractalOperator(Tuple(fums), Tuple(colors),
                           Tuple(probs), (length(fums),))
end

FractalOperator(fo::FractalOperator) = fo

function FractalOperator(fos::T) where T <: Union{Vector{FractalOperator},
                                                  Tuple}
    if isnothing(fos[1])
        curr_fo = fo(Smears.null, Shaders.null)
    else
        curr_fo = fos[1]
    end

    fxs = (curr_fo.ops,)
    clrs = (curr_fo.colors,)
    fnums = (curr_fo.fnums,)

    prob_check(curr_fo.probs)
    probs = (curr_fo.probs,)

    for i = 2:length(fos)
        curr_fo = fo(fos[i])
        if isnothing(curr_fo)
            curr_fo = fo(Smears.null, Shaders.null)
        end

        fxs = (fxs..., curr_fo.ops)
        clrs = (clrs..., curr_fo.colors)
        fnums = (fnums..., curr_fo.fnums)

        prob_check(curr_fo.probs)
        probs = (probs..., curr_fo.probs)
    end

    return FractalOperator(fxs, clrs, probs, fnums)
end

function extract_info(fos::T) where T <: Union{Tuple, Vector{FractalOperator}}
    kwargs, fis, fxs, color_kwargs, color_fis, color_fxs,
        probs, fnums = extract_info(fos[1])

    kwargs = (flatten(kwargs),)
    fis = (flatten(fis),)
    fxs = (flatten(fxs),)
    color_kwargs = (color_flatten(color_kwargs),)
    color_fis = (color_flatten(color_fis),)
    color_fxs = (color_flatten(color_fxs),)
    probs = (flatten(probs),)
    fnums = (flatten(fnums),)

    for i = 2:length(fos)
        new_kwargs, new_fis, new_fxs, new_color_kwargs,
            new_color_fis, new_color_fxs, new_probs,
            new_fnums = extract_info(fos[i])

        kwargs = (kwargs..., flatten(new_kwargs))
        fis = (fis..., flatten(new_fis))
        fxs = (fxs..., flatten(new_fxs))
        color_kwargs = (color_kwargs..., color_flatten(new_color_kwargs))
        color_fis = (color_fis..., color_flatten(new_color_fis))
        color_fxs = (color_fxs..., color_flatten(new_color_fxs))
        probs = (probs..., flatten(new_probs))
        fnums = (fnums..., flatten(new_fnums))
    end

    return kwargs, fis, fxs, color_kwargs, color_fis, color_fxs, probs, fnums
end

function extract_info(fo::FractalOperator)
    kwargs, fis, fxs = extract_ops_info(fo.ops)
    color_kwargs, color_fis, color_fxs = extract_ops_info(fo.colors)
    return flatten.((kwargs, fis, fxs, color_kwargs, color_fis, color_fxs,
            fo.probs, fo.fnums))
end

flatten(t) = (t,)
color_flatten(t) = (t,)

function flatten(t::Tuple)
    new_tuple = flatten(t[1])
    for i = 2:length(t)
        new_tuple = (new_tuple..., flatten(t[i])...)
    end
    return new_tuple
end

function color_flatten(t::Tuple)
    new_tuple = color_flatten(t[1])
    for i = 2:length(t)
        new_tuple = (new_tuple..., color_flatten(t[i])...)
    end

    # check to see if we have any sub layers
    is_tuple = false
    for i = 1:length(new_tuple)
        if isa(new_tuple[i], Tuple)
            is_tuple = true
        end
    end
    if is_tuple
        return new_tuple
    else
        return (new_tuple,)
    end
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
