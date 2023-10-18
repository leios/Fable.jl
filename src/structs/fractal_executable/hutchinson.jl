export Hutchinson

mutable struct Hutchinson <: FractalExecutable
    fxs::Tuple
    call_set::Tuple
    kwargs::Tuple
    fis::Tuple
    color_fxs::Tuple
    color_call_set::Tuple
    color_kwargs::Tuple
    color_fis::Tuple
    prob_set::Tuple
    fnums::Tuple
end

Hutchinson() = Hutchinson((),(),(),(),(),(),(),(),(),())

Base.length(H::Hutchinson) = length(H.fnums)

function Hutchinson(fo::FractalOperator)
    kwargs, fis, fxs, color_kwargs,
         color_fis, color_fxs,
         prob_set, fnums = extract_info(fo)
    fxs, call_set = make_unique(fxs)
    color_fxs, color_call_set = make_unique(color_fxs)
    return Hutchinson(fxs, call_set, kwargs, fis,
                      color_fxs, color_call_set, color_kwargs, color_fis,
                      prob_set, (fnums,))
end

function Hutchinson(fos::T) where T <: Union{Tuple, Vector{FractalOperator}}
    kwargs, fis, fxs,
         color_kwargs, color_fis, color_fxs,
         prob_set, fnums = extract_info(fos)
    fxs, call_set = make_unique(fxs)
    color_fxs, color_call_set = make_unique(color_fxs)
    return Hutchinson(fxs, call_set, kwargs, fis,
                      color_fxs, color_call_set, color_kwargs, color_fis,
                      prob_set, fnums)
end
