export FractalOperator, fo

function prob_check(probs::T) where T <: Tuple
    if eltype(probs) <: Number
        if !isapprox(sum(probs), 1)
            error("Fractal Operator probability != 1")
        end
    else
        for i = 1:length(probs)
            @inbounds prob_check(probs[i])
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

FractalOperator(n::Nothing) = fo(Smears.null, Shaders.null)

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
    @inbounds begin
        if isnothing(fos[1])
            curr_fo = fo(Smears.null, Shaders.null)
        else
            curr_fo = fos[1]
        end
    end

    fxs = (curr_fo.ops,)
    clrs = (curr_fo.colors,)
    fnums = curr_fo.fnums

    prob_check(curr_fo.probs)
    probs = (curr_fo.probs,)

    for i = 2:length(fos)
        @inbounds curr_fo = fo(fos[i])
        if isnothing(curr_fo)
            curr_fo = fo(Smears.null, Shaders.null)
        end

        fxs = (fxs..., curr_fo.ops)
        clrs = (clrs..., curr_fo.colors)
        fnums = (fnums..., curr_fo.fnums...)

        prob_check(curr_fo.probs)
        probs = (probs..., curr_fo.probs)
    end

    return FractalOperator(fxs, clrs, probs, fnums)
end

function extract_info(fos::T) where T <: Union{Tuple, Vector{FractalOperator}}
    @inbounds begin
        kwargs, fis, fxs, color_kwargs, color_fis, color_fxs,
            probs, fnums = extract_info(fos[1])
    end

    kwargs, fis, fxs,
        color_kwargs, color_fis, color_fxs,
        probs, fnums = flatten(kwargs, fis, fxs,
                               color_kwargs, color_fis, color_fxs,
                               probs, fnums)
    #fis = (fis,)
    #fxs = (fxs,)
    #color_kwargs = (color_kwargs,)
    #color_fis = (color_fis,)
    #color_fxs = (color_fxs,)
    #probs = (probs,)
    fnums = (fnums,)

    for i = 2:length(fos)
        @inbounds begin
            new_kwargs, new_fis, new_fxs, new_color_kwargs,
                new_color_fis, new_color_fxs, new_probs,
                new_fnums = extract_info(fos[i])
        end
        new_kwargs, new_fis, new_fxs,
            new_color_kwargs, new_color_fis, new_color_fxs,
            new_probs, new_fnums = flatten(new_kwargs, new_fis, new_fxs,
                                           new_color_kwargs,
                                           new_color_fis,
                                           new_color_fxs,
                                           new_probs, new_fnums)
        new_fnums = (new_fnums,)

        kwargs = (kwargs..., new_kwargs...)
        fis = (fis..., new_fis...)
        fxs = (fxs..., new_fxs...)
        color_kwargs = (color_kwargs..., new_color_kwargs...)
        color_fis = (color_fis..., new_color_fis...)
        color_fxs = (color_fxs..., new_color_fxs...)
        probs = (probs..., new_probs...)
        fnums = (fnums..., new_fnums...)
    end

    return kwargs, fis, fxs, color_kwargs, color_fis, color_fxs, probs, fnums
end

function extract_info(fo::FractalOperator)
    kwargs, fis, fxs = extract_ops_info(fo.ops)
    color_kwargs, color_fis, color_fxs = extract_ops_info(fo.colors)
    return flatten(kwargs, fis, fxs, color_kwargs, color_fis, color_fxs,
                   fo.probs, fo.fnums)
end

flatten(t) = (t,)

function flatten(kwargs, fis, fxs,
                 color_kwargs, color_fis, color_fxs,
                 probs, fnums)
    return ((kwargs,), (fis,), (fxs,),
            (color_kwargs,), (color_fis,), (color_fxs,),
            (probs,), (fnums,))
end

function flatten(kwargs::Tuple, fis::Tuple, fxs::Tuple,
                 color_kwargs::Tuple, color_fis::Tuple, color_fxs::Tuple,
                 probs::Tuple, fnums)
    @inbounds begin
        new_kwargs, new_fis, new_fxs,
            new_color_kwargs, new_color_fis, new_color_fxs,
            new_probs, new_fnums = flatten(kwargs[1], fis[1], fxs[1],
                                           color_kwargs[1],
                                           color_fis[1],
                                           color_fxs[1],
                                           probs[1], fnums[1])

        for i = 2:length(fxs)
            temp_kwargs, temp_fis, temp_fxs,
                temp_color_kwargs, temp_color_fis, temp_color_fxs,
                temp_probs, temp_fnums = flatten(kwargs[i], fis[i], fxs[i],
                                                 color_kwargs[i],
                                                 color_fis[i],
                                                 color_fxs[i],
                                                 probs[i], new_fnums[1])


            new_kwargs = (new_kwargs..., temp_kwargs...)
            new_fis = (new_fis..., temp_fis...)
            new_fxs = (new_fxs..., temp_fxs...)
            new_color_kwargs = (new_color_kwargs..., temp_color_kwargs...)
            new_color_fis = (new_color_fis..., temp_color_fis...)
            new_color_fxs = (new_color_fxs..., temp_color_fxs...)
            new_probs = (new_probs..., temp_probs...)
            new_fnums = (new_fnums..., temp_fnums...)
        end
    end
    return (new_kwargs, new_fis, new_fxs,
            new_color_kwargs, new_color_fis, new_color_fxs,
            new_probs, fnums)
end

function flatten(t::Tuple)
    @inbounds begin
        new_tuple = flatten(t[1])
        for i = 2:length(t)
            new_tuple = (new_tuple..., flatten(t[i])...)
        end
    end
    return new_tuple
end

function extract_ops_info(ops::Tuple)
    @inbounds begin
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
    end
    return (kwargs, fis, fxs)
end

function extract_ops_info(op::FractalUserMethod)
    return (op.kwargs, op.fis, op.fx)
end
