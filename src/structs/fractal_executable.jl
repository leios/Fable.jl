# fee = Fractal Executable
export Hutchinson, update_fis!, update_colors!, new_color_array, fee

fee(args...; kwargs...) = Hutchinson(args...; kwargs...)

function color_null(_clr, _p, tid, symbols, choice)
    _clr[tid,1] += _clr[tid,1]
    _clr[tid,2] += _clr[tid,2]
    _clr[tid,3] += _clr[tid,3]
    _clr[tid,4] += _clr[tid,4]
    _clr[tid,1] *= 0.5
    _clr[tid,2] *= 0.5
    _clr[tid,3] *= 0.5
    _clr[tid,4] *= 0.5
end

function null(_p, tid, symbols, choice)
    _p[tid,3] = _p[tid,1]
    _p[tid,4] = _p[tid,2]
end

mutable struct Hutchinson
    op
    cop
    color_set::Vector{FractalUserMethod}
    fum_set::Vector{FractalUserMethod}
    fi_set::Vector{FractalInput}
    name_set::Vector{String}
    prob_set::Union{NTuple, Tuple}
    symbols::Union{NTuple, Tuple}
    fnums::Union{NTuple, Tuple}
end

function Hutchinson(Hs::HT; diagnostic = false, name = "",
                    final = false) where HT <: Union{Vector{Hutchinson},
                                                     Tuple{Hutchinson}}
    color_set = Hs[1].color_set
    fum_set = Hs[1].fum_set
    fi_set = Hs[1].fi_set
    name_set = Hs[1].name_set
    prob_set = [Hs[1].prob_set[i] for i = 1:length(Hs[1].prob_set)]
    symbols = [Hs[1].symbols[i] for i = 1:length(Hs[1].symbols)]
    fnums = [Hs[1].fnums[i] for i = 1:length(Hs[1].fnums)]

    fsum = sum(Hs[1].fnums)-1

    for j = 2:length(Hs)
        if length(Hs[j].color_set) > 0
            color_set = vcat(color_set, Hs[j].color_set)
        end

        if length(Hs[j].fi_set) > 0
            fi_set = vcat(fi_set, add(Hs[j].fi_set, fsum))
        end

        if length(Hs[j].name_set) > 0
            name_set = vcat(name_set, Hs[j].name_set)
        end

        if length(Hs[j].fum_set) > 0
            fum_set = vcat(fum_set, Hs[j].fum_set)
        end

        temp_prob = [Hs[j].prob_set[i] for i = 1:length(Hs[j].prob_set)]
        temp_symbols = [Hs[j].symbols[i] for i = 1:length(Hs[j].symbols)]
        temp_fnums = [Hs[j].fnums[i] for i = 1:length(Hs[j].fnums)]

        prob_set = vcat(prob_set, temp_prob)
        symbols = vcat(symbols, temp_symbols)
        fnums = vcat(fnums, temp_fnums)

        fsum += sum(Hs[j].fnums)-1
    end

    if length(fi_set) == 0
        fi_set = Vector{FractalInput}()
    end
    if length(name_set) == 0
        name_set = Vector{String}()
    end

    if name == ""
        for i = 1:length(name_set)
            name *= name_set[i] * "_"
        end
    end
    new_H = configure_hutchinson(fum_set, fi_set, fnums;
                                 name = name, diagnostic = diagnostic,
                                 final = final)
    new_colors = configure_colors(color_set, fi_set, fnums; name = name,
                                  diagnostic = diagnostic, final = final)

    if diagnostic
        println("combined color set:\n", color_set)
        println("combined fractal User Methods:\n", fum_set)
        println("combined fractal inputs:\n", fi_set)
        println("combined names:\n", name_set)
        println("combined probabilities:\n", prob_set)
        println("combined symbols:\n", symbols)
        println("combined function numbers:\n", fnums)
        println("combined fractal executables:\n", new_H)
        println("combined colors:\n", new_colors)
    end

    return Hutchinson(new_H, new_colors,
                      color_set, fum_set, fi_set, name_set, Tuple(prob_set),
                      Tuple(symbols), Tuple(fnums))
end

function Hutchinson()
    return Hutchinson(null, color_null, [Colors.previous],
                      [Flames.identity],
                      Vector{FractalInput}(), Vector{String}(),
                      Tuple(0), Tuple(0), Tuple(1))
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
                              fis::Vector; name = "", diagnostic = false,
                              final = false, evaluate = true)

    fx_string = ""
    if evaluate
        fx_string = "@inline function H_"*name*"(_p, tid, symbols, choice)\n"
        fx_string *= "x = _p[tid, 2] \n y = _p[tid, 1] \n"
    end
    for i = 1:length(fis)
        fx_string *= fis[i].name*" = symbols["*string(fis[i].index)*"]\n"
    end

    for i = 1:length(fums)
        temp_string = ""
        if i == 1
            temp_string = "if choice == "*string(i)*"\n"*
                          create_header(fums[i])*
                          string(fums[i].body)*"\n"
        else
            temp_string = "elseif choice == "*string(i)*"\n"*
                          create_header(fums[i])*
                          string(fums[i].body)*"\n"
        end
        fx_string *= temp_string
    end

    fx_string *= "else error('Function not found!')\n"
    fx_string *= "end\n"

    if evaluate
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
    else
        return fx_string
    end
end

function configure_hutchinson(fums::Vector{FractalUserMethod},
                              fis::Vector, fnums::Vector;
                              name = "", diagnostic = false,
                              final = false, evaluate = true)
    fx_string = "@inline function H_"*name*"(_p, tid, symbols, fid)\n"
    fx_string *= "x = _p[tid, 2] \n y = _p[tid, 1] \n"

    fx_offset = 1
    bit_offset = 0

    for i = 1:length(fnums)
        fx_string *= "bit_offset = " * string(bit_offset) *"\n"
        f_range = fx_offset:fx_offset + fnums[i] - 1

        fx_string *= "bitsize = ceil(UInt, log2("*string(fnums[i])*"))\n"
        fx_string *= "bitmask = UInt(2^(bitsize + bit_offset) - 1"*
                     " - (2^bit_offset - 1))\n"
        fx_string *= "choice = UInt((fid & bitmask) >> bit_offset) + 1\n"

        temp_string = configure_hutchinson(fums[f_range], fis;
                                           evaluate = false)
        fx_string *= temp_string
        fx_offset += fnums[i]
        bit_offset += ceil(UInt,log2(fnums[i]))
    end

    if evaluate
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
    else
        return fx_string
    end

end


function configure_colors(fums::Vector{FractalUserMethod},
                          fis::Vector; name = "", diagnostic = false,
                          final = false, evaluate = true)

    fx_string = ""
    if evaluate
        fx_string *= "@inline function color_"*name*"(_clr, _p, tid,"*
                     " symbols, choice)\n"
        fx_string *= "x = _p[tid, 2] \n"
        fx_string *= "y = _p[tid, 1] \n"
        fx_string *= "red = _clr[tid, 1] \n"
        fx_string *= "green = _clr[tid, 2] \n"
        fx_string *= "blue = _clr[tid, 3] \n"
        fx_string *= "alpha = _clr[tid, 4] \n"

        for i = 1:length(fis)
            fx_string *= fis[i].name*" = symbols["*string(fis[i].index)*"]\n"
        end
    end

    for i = 1:length(fums)
        temp_string = ""
        if i == 1
            temp_string = "if choice == "*string(i)*"\n"*
                          create_header(fums[i])*
                          string(fums[i].body)*"\n"
        else
            temp_string = "elseif choice == "*string(i)*"\n"*
                          create_header(fums[i])*
                          string(fums[i].body)*"\n"
        end
        fx_string *= temp_string
    end

    fx_string *= "else error('Function not found!')\n"
    fx_string *= "end\n"
    if evaluate
        fx_string *= "_clr[tid, 1] += red \n"
        fx_string *= "_clr[tid, 2] += green \n"
        fx_string *= "_clr[tid, 3] += blue \n"
        fx_string *= "_clr[tid, 4] += alpha \n"
        if final
            fx_string *= "_clr[tid, 1] *= 0.5 \n"
            fx_string *= "_clr[tid, 2] *= 0.5 \n"
            fx_string *= "_clr[tid, 3] *= 0.5 \n"
            fx_string *= "_clr[tid, 4] *= 0.5 \n"
        end
        fx_string *= "end"
    end

    if evaluate
        H = Meta.parse(replace(fx_string, "'" => '"'))

        if diagnostic
            println(H)
        end

        return eval(H)
    else
        return fx_string
    end
end

function configure_colors(fums::Vector{FractalUserMethod},
                          fis::Vector, fnums::Vector;
                          name = "", diagnostic = false,
                          final = false, evaluate = true)
    fx_string = "@inline function color_"*name*"(_clr, _p, tid, symbols, fid)\n"
    fx_string *= "x = _p[tid, 2] \n"
    fx_string *= "y = _p[tid, 1] \n"
    fx_string *= "red = _clr[tid, 1] \n"
    fx_string *= "green = _clr[tid, 2] \n"
    fx_string *= "blue = _clr[tid, 3] \n"
    fx_string *= "alpha = _clr[tid, 4] \n"
    fx_string *= "fx_count = 0 \n"

    for i = 1:length(fis)
        fx_string *= fis[i].name*" = symbols["*string(fis[i].index)*"]\n"
    end

    fx_offset = 1
    bit_offset = 0

    for i = 1:length(fnums)
        fx_string *= "bit_offset = " * string(bit_offset) *"\n"
        f_range = fx_offset:fx_offset + fnums[i] - 1

        fx_string *= "bitsize = ceil(UInt, log2("*string(fnums[i])*"))\n"
        fx_string *= "bitmask = UInt(2^(bitsize + bit_offset) - 1"*
                     " - (2^bit_offset - 1))\n"
        fx_string *= "choice = UInt((fid & bitmask) >> bit_offset) + 1\n"

        temp_string = configure_colors(fums[f_range], fis;
                                       evaluate = false, final = final)
        fx_string *= temp_string
        fx_string *= "fx_count += 1\n"
        fx_offset += fnums[i]
        bit_offset += ceil(UInt,log2(fnums[i]))
    end

    fx_string *= "_clr[tid, 1] += (red / fx_count) \n"
    fx_string *= "_clr[tid, 2] += (green / fx_count) \n"
    fx_string *= "_clr[tid, 3] += (blue / fx_count) \n"
    fx_string *= "_clr[tid, 4] += (alpha / fx_count) \n"

    if final
        fx_string *= "_clr[tid, 1] *= 0.5 \n"
        fx_string *= "_clr[tid, 2] *= 0.5 \n"
        fx_string *= "_clr[tid, 3] *= 0.5 \n"
        fx_string *= "_clr[tid, 4] *= 0.5 \n"
    end
    fx_string *= "end"

    if evaluate
        H = Meta.parse(replace(fx_string, "'" => '"'))

        if diagnostic
            println(H)
        end

        return eval(H)
    else
        return fx_string
    end
end

function Hutchinson(fums::Array{FractalUserMethod},
                    color_set, prob_set;
                    AT = Array, FT = Float64, name = "",
                    diagnostic = false, final = false) where A <: Array
    Hutchinson(fums, [], color_set, prob_set; final = final,
               diagnostic = diagnostic, AT = AT, FT = FT, name = name)
end

# This is a constructor for when people read in an array of arrays for colors
function Hutchinson(fums::Array{FractalUserMethod},
                    fis::Vector,
                    color_set, prob_set;
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
                              diagnostic = diagnostic, final = final)
    return Hutchinson(H, colors, temp_colors, fums, fis, [name], prob_set,
                      symbols, Tuple(length(fums)))
end

function Hutchinson(fos::Vector{FractalOperator}, fis::Vector;
                    AT = Array, FT = Float64, name = "",
                    diagnostic = false, final = false)

    # constructing probabilities and colors
    fnum = length(fos)
    prob_array = [fos[i].prob for i = 1:fnum]
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
                              diagnostic = diagnostic, final = final)

    fums = FractalUserMethod.(fos)
    return Hutchinson(H, colors, color_array, fums, fis, [name], prob_set,
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
    H.cop[h_id] = configure_colors(H.color_set[offset:offset + H.fnums[h_id]],
                                   H.fi_set; name = H.name_set[h_id], 
                                   final = final)
end
