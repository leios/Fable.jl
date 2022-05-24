# fee = Fractal Executable
export Hutchinson, update_fis!, update_colors!, new_color_array, fee

fee(args...) = Hutchonson(args...)

function null(_p, tid, symbols, fid)
    _p[tid,3] = _p[tid,1]
    _p[tid,4] = _p[tid,2]
end

mutable struct Hutchinson
    ops::Tuple{Function}
    cops::Tuple{Function}
    color_set::Vector{FractalUserMethod}
    fi_set::Vector{FractalInput}
    name_set::Vector{String}
    prob_set::Union{NTuple, Tuple}
    symbols::Union{NTuple, Tuple}
    fnums::Union{NTuple, Tuple}
end

function Hutchinson()
    return Hutchinson((Fae.null,), Tuple(Fae.null,), [Colors.previous],
                      [FractalInput()], [FractalOperator()], [""],
                      Tuple(0), Tuple(0), Tuple(0))
end

function configure_hutchinson(fos::Vector{FractalOperator},
                              fis::Vector; name = "",
                              diagnostic = false, final = false)
    configure_hutchinson(FractalUserMethod.(fos), fis;
                          name = name, diagnostic = diagnostic, final = final)
end

function new_color_array(color_array; diagnostic = false)
    temp_array = [Colors.previous for i = 1:length(color_array)]
    for i = 1:length(color_array)
        temp_array[i] = create_color(color_array[i])
    end

    return temp_array
end

function configure_hutchinson(fums::Vector{FractalUserMethod},
                              fis::Vector; name = "",
                              diagnostic = false, final = false)

    fx_string = "function H_"*name*"(_p, tid, symbols, fid)\n"
    fx_string *= "x = _p[tid, 2] \n y = _p[tid, 1] \n"
    for i = 1:length(fis)
        fx_string *= fis[i].name*" = symbols["*string(fis[i].index)*"]\n"
    end

    for i = 1:length(fums)
        temp_string = ""
        if i == 1
            temp_string = "if fid == "*string(i)*"\n"*
                          create_header(fums[i])*
                          string(fums[i].body)*"\n"
        else
            temp_string = "elseif fid == "*string(i)*"\n"*
                          create_header(fums[i])*
                          string(fums[i].body)*"\n"
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

function configure_colors(fums::Vector{FractalUserMethod},
                          fis::Vector; name = "",
                          diagnostic = false, final = false)

    fx_string = "function color_"*name*"(_clr, _p, tid, symbols, fid)\n"
    fx_string *= "x = _p[tid, 2] \n"
    fx_string *= "y = _p[tid, 1] \n"
    fx_string *= "red = _clr[tid, 1] \n"
    fx_string *= "green = _clr[tid, 2] \n"
    fx_string *= "blue = _clr[tid, 3] \n"
    fx_string *= "alpha = _clr[tid, 4] \n"

    for i = 1:length(fis)
        fx_string *= fis[i].name*" = symbols["*string(fis[i].index)*"]\n"
    end

    for i = 1:length(fums)
        temp_string = ""
        if i == 1
            temp_string = "if fid == "*string(i)*"\n"*
                          create_header(fums[i])*
                          string(fums[i].body)*"\n"
        else
            temp_string = "elseif fid == "*string(i)*"\n"*
                          create_header(fums[i])*
                          string(fums[i].body)*"\n"
        end
        fx_string *= temp_string
    end

    fx_string *= "else error('Function not found!')\n"
    fx_string *= "end\n"
    fx_string *= "_clr[tid, 1] += red \n"
    fx_string *= "_clr[tid, 2] += green \n"
    fx_string *= "_clr[tid, 3] += blue \n"
    fx_string *= "_clr[tid, 4] += alpha \n"
    fx_string *= "end"

    H = Meta.parse(replace(fx_string, "'" => '"'))

    if diagnostic
        println(H)
    end

    return eval(H)
end

function Hutchinson(fums::Array{FractalUserMethod},
                    color_set::Union{Array{A}, Array, RGB, RGBA}, prob_set;
                    AT = Array, FT = Float64, name = "",
                    diagnostic = false, final = false) where A <: Array
    Hutchinson(fums, [], color_set, prob_set, (length(fums)); final = final,
               diagnostic = diagnostic, AT = AT, FT = FT, name = name)
end

# This is a constructor for when people read in an array of arrays for colors
function Hutchinson(fums::Array{FractalUserMethod},
                    fis::Vector,
                    color_set::Union{Array{A}, Array, RGB, RGBA}, prob_set;
                    AT = Array, FT = Float64, name = "",
                    diagnostic = false, final = false) where A <: Array

    fnum = length(fums)
    temp_colors = new_color_array(color_set, diagnostic = diagnostic)

    if !isapprox(sum(prob_set),1)
        println("probability set != 1, resetting to be equal probability...")
        prob_set = Tuple(1/fnum for i = 1:fnum)
    end

    symbols = ()
    if length(fis) > 0
        symbols = configure_fis!(fis)
    end
    H = configure_hutchinson(fums, fis; name = name, diagnostic = diagnostic,
                             final = final)
    colors = configure_colors(temp_colors, fis; name = name,
                              diagnostic = diagnostic)
    return Hutchinson((H,), (colors,), temp_colors, fis, [name], prob_set,
                      symbols, Tuple(length(fums)))
end

function Hutchinson(fos::Vector{FractalOperator}, fis::Vector;
                    AT = Array, FT = Float64, name = "",
                    diagnostic = false, final = false)

    # constructing probabilities and colors
    fnum = length(fos)
    prob_array = zeros(fnum)
    color_array = [fos[i].color for i = 1:fnum]

    prob_set = Tuple(prob_array)

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
    colors = configure_colors(color_array, fis; name = name,
                              diagnostic = diagnostic)

    return Hutchinson((H,), (colors,), fis, [name], prob_set,
                      symbols, Tuple(length(fos)))

end

function Hutchinson(fos::Vector{FractalOperator};
                    AT = Array, FT = Float64, name = "",
                    diagnostic = false, final = false)
    Hutchinson(fos, [], AT = AT, FT = FT, name = name, diagnostic = diagnostic,
               final = final)
end

function update_fis!(H::Hutchinson, fis::Vector{FractalInput})
    H.symbols = configure_fis!(fis)
end

function update_colors!(H::Hutchinson, fx_id, h_id,
                        new_color::Union{RGB, RGBA, Vector{N}};
                        AT = Array) where N<:Number

    offset = 1
    for i = 2:h_id
        offset += H.fnums[i-1]
    end
    
    H.color_set[fx_id + offset] = create_color(new_color)
    H.cops[h_id] = configure_colors(H.color_set[offset:offset + H.fnums[h_id]],
                                    H.fi_set, name = H.name_set[h_id])
end
