mutable struct Hutchinson
    op::Function
    color_set::Union{Array{T,2}, CuArray{T,2}} where T <: AbstractFloat
    prob_set::Union{NTuple, Tuple}
    symbols::Union{NTuple, Tuple}
end

function new_color_array(colors_in::Array{A}, fnum;
                         FT = Float64, AT = Array) where A
    temp_colors = zeros(FT,fnum,4)
    for i = 1:4
        for j = 1:fnum
            temp_colors[j,i] = colors_in[j][i]
        end
    end

    return AT(temp_colors)
end

# use repr to go from expr -> string
# think about recursive unions (barnsley + sierpinski)
function generate_H(expr)
    fnum = length(expr.args)-1
    fx_string = "function H(p, tid, symbols, fid)\n"
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

# TODO:
# This is a half-step towards where we want to be. I think the union syntax of
# the previous function is more elegant, but needs some work.
# Ultimately working towards an @hutchinson macro
function configure_hutchinson(fos::Vector{FractalOperator},
                              fis::Vector; name = "")

    fx_string = "function H_"*name*"(_p, tid, symbols, fid)\n"
    fx_string *= "x = _p[tid, 2] \n y = _p[tid, 1] \n"
    for i = 1:length(fis)
        fx_string *= fis[i].name*" = symbols["*string(fis[i].index)*"]\n"
    end

    for i = 1:length(fos)
        temp_string = ""
        if i == 1
            temp_string = "if fid == "*string(i)*"\n"*
                          create_header(fos[i])*
                          string(fos[i].body)*"\n"
        else
            temp_string = "elseif fid == "*string(i)*"\n"*
                          create_header(fos[i])*
                          string(fos[i].body)*"\n"
        end
        fx_string *= temp_string
    end

    fx_string *= "else error('Function not found!')\n"
    fx_string *= "end\n"
    fx_string *= "_p[tid, 2] = x \n _p[tid, 1] = y \n"
    fx_string *= "end"

    H = Meta.parse(replace(fx_string, "'" => '"'))

    #println(fx_string)
    println(H)

    return eval(H)
end

# This is a constructor for when people read in an array of arrays for colors
function Hutchinson(fos::Array{FractalOperator},
                    fis::Vector,
                    color_set::Array{A}, prob_set;
                    AT = Array, FT = Float64, name = "") where A <: Array

    fnum = length(fos)
    temp_colors = new_color_array(color_set, fnum; FT = FT, AT = AT)

    if !isapprox(sum(prob_set),1)
        println("probability set != 1, resetting to be equal probability...")
        prob_set = Tuple(1/N for i = 1:N)
    end

    symbols = ()
    if length(fis) > 0
        symbols = configure_fis!(fis)
    end
    H = configure_hutchinson(fos, fis; name = name)

    return Hutchinson(H, AT(temp_colors), prob_set, symbols)
end

