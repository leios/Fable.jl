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
Hutchinson(H::Hutchinson) = H

function Hutchinson(fum::FractalUserMethod, color_fum::FractalUserMethod,
                    prob::Number)
    return Hutchinson((fum.fx,), (fum.kwargs,), (fum.fis,),
                      (color_fum.fx,), (color_fum.kwargs,), (color_fum.fis,),
                      (prob,), (1,))
end

function Hutchinson(fo::FractalOperator; depth = 0)
    if depth == 1 && fo.prob != 1
        @warn("Setting probability to 1 for standalone FractalOperator...")
        prob = 1
    else
        prob = fo.prob
    end
    return Hutchinson((fo.op.fx,), (fo.op.kwargs,), (fo.op.fis,),
                      (fo.color.fx,), (fo.color.kwargs,), (fo.color.fis,),
                      (prob,), (1,))
end

function Hutchinson(H1::Hutchinson, H2::Hutchinson)
    return Hutchinson((H1.fxs..., H2.fxs...),
                      (H1.kwargs..., H2.kwargs...),
                      (H1.fis..., H2.fis...),
                      (H1.color_fxs..., H2.color_fxs...),
                      (H1.color_kwargs..., H2.color_kwargs...),
                      (H1.color_fis..., H2.color_fis...),
                      (H1.prob_set..., H2.prob_set...),
                      (H1.fnums..., H2.fnums...))
end

function Hutchinson(fos::Union{Tuple, Vector}; depth = 0)
    if depth > 1
        error("Cannot create Hutchinson operators of depth > 2! (#65)")
    end

    if length(fos) == 0
        error("No FractalOperator provided!")
    elseif length(fos) == 1
        return Hutchinson(fos[1]; depth = 1)
    else
        H = Hutchinson()
        multilayer_flag = false
        prob = 0.0
        for i = 1:length(fos)
            if typeof(fos[i]) <: Tuple
                multilayer_flag = true
            elseif depth > 0
                prob += fos[i].prob
            end

            H = Hutchinson(H, Hutchinson(fos[i]; depth = depth+1))
        end

        if multilayer_flag
            H.fnums = length.(fos)
        else
            H.fnums = Tuple(1 for i = 1:length(fos))
            if prob > 1.0
                @warn("Probabilities do not add up to 1!\n"*
                      "Setting all operators to be equally likely...")
                H.prob_set = Tuple([1/length(fos) for i = 1:length(fos)])
            end
        end

        return H
    end
end
