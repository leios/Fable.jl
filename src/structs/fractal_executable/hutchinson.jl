# fee = Fractal Executable
export fee, Hutchinson

mutable struct Hutchinson <: FractalExecutable
    op
    cop
    color_set::Vector{FractalUserMethod}
    fum_set::Vector{FractalUserMethod}
    fi_set::Vector{FractalInput}
    name_set::Vector{String}
    prob_set::Union{NTuple, Tuple}
    symbols::Union{NTuple, Tuple}
    fnums::Union{NTuple, Tuple}
    post::Bool
    chain::Bool
end

fee(H::Type{Hutchinson}, args...; kwargs...) = Hutchinson(args...; kwargs...)

# This will update the symbols and prob set for combined fees
function update!(post_H::Hutchinson, Hs::HT; diagnostic = false, name = "",
                 post = false,
                 chain = false) where HT <: Union{Vector{Hutchinson},
                                                  Tuple{Hutchinson}}

    symbols = [Hs[1].symbols[i] for i = 1:length(Hs[1].symbols)]
    prob_set = [Hs[1].prob_set[i] for i = 1:length(Hs[1].prob_set)]

    for j = 2:length(Hs)
        temp_prob = [Hs[j].prob_set[i] for i = 1:length(Hs[j].prob_set)]
        temp_symbols = [Hs[j].symbols[i] for i = 1:length(Hs[j].symbols)]

        prob_set = vcat(prob_set, temp_prob)
        symbols = vcat(symbols, temp_symbols)
    end

    post_H.symbols = Tuple(symbols)
    post_H.prob_set = Tuple(prob_set)

    if diagnostic
        println("combined color set:\n", post_H.color_set)
        println("combined fractal User Methods:\n", post_H.fum_set)
        println("combined fractal inputs:\n", post_H.fi_set)
        println("combined names:\n", post_H.name_set)
        println("combined probabilities:\n", post_H.prob_set)
        println("combined symbols:\n", post_H.symbols)
        println("combined function numbers:\n", post_H.fnums)
    end

end

function Hutchinson(Hs::HT; diagnostic = false, name = "", chain = false,
                    post = false) where HT <: Union{Vector{Hutchinson},
                                                     Tuple{Hutchinson}}
    color_set = Hs[1].color_set
    fum_set = Hs[1].fum_set
    fi_set = Hs[1].fi_set
    name_set = Hs[1].name_set
    prob_set = [Hs[1].prob_set[i] for i = 1:length(Hs[1].prob_set)]
    symbols = [Hs[1].symbols[i] for i = 1:length(Hs[1].symbols)]
    fnums = [Hs[1].fnums[i] for i = 1:length(Hs[1].fnums)]

    fsum = length(Hs[1].symbols)

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

        fsum += length(Hs[j].symbols)
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
                                 post = post, chain = chain)
    new_colors = configure_colors(color_set, fi_set, fnums; name = name,
                                  diagnostic = diagnostic, post = post)

    if diagnostic
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
                      Tuple(symbols), Tuple(fnums), post, chain)
end

function Hutchinson()
    return Hutchinson(null, color_null, [Shaders.previous],
                      [Flames.identity],
                      Vector{FractalInput}(), Vector{String}(),
                      Tuple(0), Tuple(0), Tuple(1), false, false)
end

function configure_hutchinson(fos::Vector{FractalOperator},
                              fis::Vector; name = "", chain = false,
                              diagnostic = false, post = false)
    configure_hutchinson(FractalUserMethod.(fos), fis; chain = chain,
                          name = name, diagnostic = diagnostic, post = post)
end

function configure_hutchinson(fums::Vector{FractalUserMethod},
                              fis::Vector; name = "", diagnostic = false,
                              post = false, evaluate = true, chain = false)

    fx_string = ""
    if evaluate
        fx_string = "@inline function H_"*name*"(_p, tid, symbols, choice)\n"
        if chain
            fx_string *= "x = _p[tid, 4] \n y = _p[tid, 3] \n"
        else
            fx_string *= "x = _p[tid, 2] \n y = _p[tid, 1] \n"
        end
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
        if post
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
                              post = false, evaluate = true,
                              chain = false)
    fx_string = "@inline function H_"*name*"(_p, tid, symbols, fid)\n"
    if chain
        fx_string *= "x = _p[tid, 4] \n y = _p[tid, 3] \n"
    else
        fx_string *= "x = _p[tid, 2] \n y = _p[tid, 1] \n"
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

        temp_string = configure_hutchinson(fums[f_range], fis;
                                           evaluate = false)
        fx_string *= temp_string
        fx_offset += fnums[i]
        bit_offset += ceil(UInt,log2(fnums[i]))
    end

    if evaluate
        if post
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

function Hutchinson(fums::Array{FractalUserMethod},
                    color_set, prob_set; name = "", chain = false,
                    diagnostic = false, post = false) where A <: Array
    Hutchinson(fums, [], color_set, prob_set; post = post, chain = chain,
               diagnostic = diagnostic, name = name)
end

# This is a constructor for when people read in an array of arrays for colors
function Hutchinson(fums::Array{FractalUserMethod},
                    fis::Vector, color_set, prob_set; name = "", chain = false,
                    diagnostic = false, post = false) where A <: Array

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
                             post = post, chain = chain)
    colors = configure_colors(temp_colors, fis; name = name,
                              diagnostic = diagnostic, post = post)
    return Hutchinson(H, colors, temp_colors, fums, fis, [name], prob_set,
                      symbols, Tuple(length(fums)), post, chain)
end

function Hutchinson(fos::Vector{FractalOperator}, fis::Vector; name = "",
                    diagnostic = false, post = false, chain = false)

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
                             post = post, chain = chain)
    colors = configure_colors(color_array, fis; name = name,
                              diagnostic = diagnostic, post = post)

    fums = FractalUserMethod.(fos)
    return Hutchinson(H, colors, color_array, fums, fis, [name], prob_set,
                      symbols, Tuple(length(fos)), post, chain)

end

function Hutchinson(fos::Vector{FractalOperator}; name = "", chain = false,
                    diagnostic = false, post = false)
    Hutchinson(fos, [], name = name, diagnostic = diagnostic, chain = chain, 
               post = post)
end

function update_fis!(H::Hutchinson, fis::Vector{FractalInput})
    H.symbols = configure_fis!(fis)
end

function update_colors!(H::Hutchinson, fx_id, h_id,
                        new_color::Union{RGB, RGBA, Vector{N}}) where N<:Number

    offset = 1
    for i = 2:h_id
        offset += H.fnums[i-1]
    end
    
    H.color_set[fx_id + offset] = create_color(new_color)
    H.cop[h_id] = configure_colors(H.color_set[offset:offset + H.fnums[h_id]],
                                   H.fi_set; name = H.name_set[h_id], 
                                   post = post)
end
