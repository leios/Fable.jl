export Hutchinson

mutable struct Hutchinson <: FractalExecutable
    fxs::Tuple
    kwargs::Tuple
    fis::Tuple
    color_fxs::Tuple
    color_kwargs::Tuple
    color_fis::Tuple
    prob_set::Tuple
    fnums::Tuple
end

Hutchinson() = Hutchinson((),(),(),(),(),(),(),())
Hutchinson(H::Hutchinson; depth = 0) = H

function Hutchinson(fum::FractalUserMethod, color_fum::FractalUserMethod,
                    prob::Number)
    return Hutchinson(((fum.fx,),), ((fum.kwargs,),), ((fum.fis,),),
                      ((color_fum.fx,),), ((color_fum.kwargs,),),
                      ((color_fum.fis,),), ((prob,),), ((1,),))
end

function color_splat(fo_color::FractalUserMethod)
    return ((fo_color.fx,), (fo_color.kwargs,), (fo_color.fis,))
end

function color_splat(fo_color::Tuple)
    fxs = [fo_color[i].fx for i = 1:length(fo_color)]
    kwargs = [fo_color[i].kwargs for i = 1:length(fo_color)]
    fis = [fo_color[i].fis for i = 1:length(fo_color)]

    return ((Tuple(fxs),), (Tuple(kwargs),), (Tuple(fis),))
end

function Hutchinson(fo::FractalOperator; depth = 0)
    if depth <= 1 && fo.prob != 1
        @warn("Setting probability to 1 for standalone FractalOperator...")
        prob = 1
    else
        prob = fo.prob
    end
    return Hutchinson(((fo.op.fx,),), ((fo.op.kwargs,),), ((fo.op.fis,),),
                      (color_splat(fo.color)...,),
                      ((prob,),), ((1,),))
end

function Hutchinson(H::Hutchinson, H_post::Hutchinson)
    return Hutchinson((H.fxs..., H_post.fxs...),
                      (H.kwargs..., H_post.kwargs...),
                      (H.fis..., H_post.fis...),
                      (H.color_fxs..., H_post.color_fxs...),
                      (H.color_kwargs..., H_post.color_kwargs...),
                      (H.color_fis..., H_post.color_fis...),
                      (H.prob_set..., H_post.prob_set...),
                      (H.fnums..., H_post.fnums...))
end

function Hutchinson(fos::Union{Tuple, Vector}; depth = 0)
    if depth > 1
        error("Cannot create Hutchinson operators of depth > 2! (#65)")
    end

    if length(fos) == 0
        error("No FractalOperator provided!")
    elseif length(fos) == 1
        H = Hutchinson(fos[1]; depth = 1)
        H.fnums = (length(fos[1]),)
        return H
    else
        H = Hutchinson()
        multilayer_flag = false
        prob = 0.0
        for i = 1:length(fos)
            if isa(fos[i], Union{Tuple, Vector})
                multilayer_flag = true
            elseif depth > 0
                prob += fos[i].prob
            end

            H = Hutchinson(H, Hutchinson(fos[i]; depth = depth+1))
        end

        if multilayer_flag
            H.fnums = length.(fos)
        else
            if !(eltype(fos) <: Hutchinson)
                H.fnums = Tuple(1 for i = 1:length(fos))
            end
            if prob > 1.0
                @warn("Probabilities do not add up to 1!\n"*
                      "Setting all operators to be equally likely...")
                H.prob_set = Tuple([1/length(fos) for i = 1:length(fos)])
            end
        end

        return H
    end
end
