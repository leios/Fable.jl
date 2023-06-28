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

function Hutchinson(fos::T) where T <: Union{Tuple, Vector{FractalOperator},
                                             FractalOperator}
    info, color_info, prob_set, fnums = extract_info(fos)
    return Hutchinson(info[3], info[1], info[2],
                      color_info[3], color_info[1], color_info[2],
                      prob_set, fnums)
end
