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
    object_fnums::Tuple
end

Hutchinson() = Hutchinson((),(),(),(),(),(),(),(),())

Base.length(H) = length(H.object_fnums)

function Hutchinson(fo::FractalOperator)
    kwargs, fis, fxs, color_kwargs, color_fis, color_fxs,
         prob_set, fnums = extract_info(fo)
    return Hutchinson(flatten(fxs), flatten(kwargs), flatten(fis),
                      flatten(color_fxs),
                      flatten(color_kwargs),
                      flatten(color_fis),
                      flatten(prob_set), (fnums,), (length(fnums),))
end

function Hutchinson(fos::T) where T <: Union{Tuple, Vector{FractalOperator}}
    kwargs, fis, fxs, color_kwargs, color_fis, color_fxs,
         prob_set, fnums = extract_info(fos)
    object_fnums = Tuple([length(fnums[i]) for i = 1:length(fnums)])
    return Hutchinson(flatten(fxs), flatten(kwargs), flatten(fis),
                      flatten(color_fxs),
                      flatten(color_kwargs),
                      flatten(color_fis),
                      flatten(prob_set), fnums, object_fnums)
end
