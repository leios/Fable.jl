# Struct for function composition
function U(args...)
end

# use repr to go from expr -> string
# think about recursive unions (barnsley + sierpinski)
function generate_H(expr)
    fnum = length(expr.args)-1
    fx_string = "function H(p, tid, t, fid)\n"
    for i = 1:fnum
        temp_string = ""
        if i == 1
            f_str = repr(expr.args[i+1])[2:end]
            #println(f_str)
            temp_string = "if fid == "*string(i)*" "*f_str*"(p, tid, t)\n"
        else
            f_str = repr(expr.args[i+1])[2:end]
            #println(f_str)
            temp_string = "elseif fid == "*string(i)*" "*f_str*"(p, tid, t)\n"
        end
        fx_string *= temp_string
    end

    fx_string *= "else error('Function not found!')\n"
    fx_string *= "end\n"
    fx_string *= "end"

    H = Meta.parse(replace(fx_string, "'" => '"'))

    #println(fx_string)
    println(H)

    return eval(H)
end

function configure_hutchinson(frops::Vector{FractalOperator},
                              aux_frops::Vector{FractalOperator})
    return configure_hutchinson(vcat(frops, aux_frops), length(frops))
end

# TODO:
# This is a half-step towards where we want to be. I think the union syntax of
# the previous function is more elegant, but needs some work.
# Ultimately working towards an @hutchinson macro
function configure_hutchinson(frops::Vector{FractalOperator}, N)

    fx_string = "function H(p, tid, t, fid)\n"
    fx_string *= "x = p[tid, 2] \n y = p[tid, 1] \n t = t \n"

    for i = 1:N
        temp_string = ""
        if i == 1
            temp_string = "if fid == "*string(i)*"\n"*
                          create_frop_header(frops[i], frops)*
                          string(frops[i].body)*"\n"
        else
            temp_string = "elseif fid == "*string(i)*"\n"*
                          create_frop_header(frops[i], frops)*
                          string(frops[i].body)*"\n"
        end
        fx_string *= temp_string
    end

    fx_string *= "else error('Function not found!')\n"
    fx_string *= "end\n"
    fx_string *= "end"

    H = Meta.parse(replace(fx_string, "'" => '"'))

    #println(fx_string)
    println(H)

    return eval(H)
end


mutable struct Hutchinson
    op::Function
    color_set::Union{Array{T,2}, CuArray{T,2}} where T <: AbstractFloat
    prob_set::Union{NTuple, Tuple}
end

# This is a constructor for when people read in an array of arrays for colors
function Hutchinson(f_set, color_set::Array{A}, prob_set;
                    AT = Array, FT = Float64) where A <: Array

    fnum = length(f_set.args)-1
    temp_colors = zeros(FT,fnum,4)

    if !isapprox(sum(prob_set),1)
        println("probability set != 1, resetting to be equal probability...")
        prob_set = Tuple(1/fnum for i = 1:fnum)
    end

    for i = 1:4
        for j = 1:length(color_set)
            temp_colors[j,i] = color_set[j][i]
        end
    end

    H = generate_H(f_set)

    return Hutchinson(H, AT(temp_colors), prob_set)
end

