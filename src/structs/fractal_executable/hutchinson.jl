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

Base.length(H) = length(H.fxs)

function Hutchinson(fo::FractalOperator)
    kwargs, fis, fxs, color_kwargs, color_fis, color_fxs,
         prob_set, fnums = extract_info(fo)
    return Hutchinson((fxs,), (kwargs,), (fis,),
                      (color_fxs,), (color_kwargs,), (color_fis,),
                      (prob_set,), (fnums,))
end

function Hutchinson(fos::T) where T <: Union{Tuple, Vector{FractalOperator}}
    kwargs, fis, fxs, color_kwargs, color_fis, color_fxs,
         prob_set, fnums = extract_info(fos)
    return Hutchinson(fxs, kwargs, fis,
                      color_fxs, color_kwargs, color_fis,
                      prob_set, fnums)
end
