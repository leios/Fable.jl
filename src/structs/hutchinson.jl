function null(_p, tid, symbols, fid)
    _p[tid,3] = _p[tid,1]
    _p[tid,4] = _p[tid,2]
end

mutable struct Hutchinson
    op::Function
    color_set::Union{Array{T,2}, CuArray{T,2}} where T <: AbstractFloat
    prob_set::Union{NTuple, Tuple}
    symbols::Union{NTuple, Tuple}
end

function new_color_array(colors_in::Array{A}, fnum;
                         FT = Float64, AT = Array) where A
    temp_colors = zeros(FT,fnum,4)
    if fnum > 1
        for i = 1:4
            for j = 1:fnum
                temp_colors[j,i] = colors_in[j][i]
            end
        end
    elseif fnum == 1
        return AT(transpose(colors_in[1]))
    end

    return AT(temp_colors)
end

function configure_hutchinson(fos::Vector{FractalOperator},
                              fis::Vector; name = "", diagnostic = false,
                              final = false)

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
    if final
        fx_string *= "_p[tid, 4] = x \n _p[tid, 3] = y \n"
    else
        fx_string *= "_p[tid, 2] = x \n _p[tid, 1] = y \n"
    end
    fx_string *= "end"

    H = Meta.parse(replace(fx_string, "'" => '"'))

    if diagnostic
        println(H)
    end

    return eval(H)
end

function Hutchinson(fos::Array{FractalOperator},
                    color_set::Union{Array{A}, Array}, prob_set;
                    AT = Array, FT = Float64, name = "",
                    diagnostic = false, final = false) where A <: Array
    Hutchinson(fos, [], color_set, prob_set; final = final,
               diagnostic = diagnostic, AT = AT, FT = FT, name = name)
end


# This is a constructor for when people read in an array of arrays for colors
function Hutchinson(fos::Array{FractalOperator},
                    fis::Vector,
                    color_set::Union{Array{A}, Array}, prob_set;
                    AT = Array, FT = Float64, name = "",
                    diagnostic = false, final = false) where A <: Array

    fnum = length(fos)
    temp_colors = new_color_array(color_set, fnum; FT = FT, AT = AT)

    if !isapprox(sum(prob_set),1)
        println("probability set != 1, resetting to be equal probability...")
        prob_set = Tuple(1/fnum for i = 1:fnum)
    end

    symbols = ()
    if length(fis) > 0
        symbols = configure_fis!(fis)
    end
    H = configure_hutchinson(fos, fis; name = name, diagnostic = diagnostic,
                             final = final)

    return Hutchinson(H, temp_colors, prob_set, symbols)
end

function update_fis!(H::Hutchinson, fis::Vector{FractalInput};
                     max_symbols = length(fis)*2)

    H.symbols = configure_fis!(fis; max_symbols = max_symbols)
end

