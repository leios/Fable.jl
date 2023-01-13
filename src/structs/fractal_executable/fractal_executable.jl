# fee = Fractal Executable
export FractalExecutable, update_fis!, update_colors!, new_color_array, update!

abstract type FractalExecutable end;

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

function new_color_array(color_array; diagnostic = false)
    if eltype(color_array) <: Number
       return [create_color(color_array)]
    else
        temp_array = [Shaders.previous for i = 1:length(color_array)]
        for i = 1:length(color_array)
            temp_array[i] = create_color(color_array[i])
        end
        return temp_array
    end

end

function configure_colors(fums::Vector{FractalUserMethod},
                          fis::Vector; name = "", diagnostic = false,
                          post = false, evaluate = true)

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
        if post
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
                          post = false, evaluate = true)
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
                                       evaluate = false, post = post)
        fx_string *= temp_string
        fx_string *= "fx_count += 1\n"
        fx_offset += fnums[i]
        bit_offset += ceil(UInt,log2(fnums[i]))
    end

    fx_string *= "_clr[tid, 1] += (red / fx_count) \n"
    fx_string *= "_clr[tid, 2] += (green / fx_count) \n"
    fx_string *= "_clr[tid, 3] += (blue / fx_count) \n"
    fx_string *= "_clr[tid, 4] += (alpha / fx_count) \n"

    if post
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
