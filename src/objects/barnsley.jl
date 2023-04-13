export define_barnsley
function define_barnsley(; color = Shaders.grey, tilt = 0)
    fums = define_barnsley_operators(tilt = tilt)
    color_set = define_color_operators(color; fnum = 4)
    prob_set = (0.01, 0.85, 0.07, 0.07)
    fos = Tuple(FractalOperator(fums[i], color_set[i], prob_set[i]) for i = 1:4)
    return Hutchinson((fos,))
end

# This specifically returns the fums for a barnsley fern
function define_barnsley_operators(; tilt::Union{Number, FractalInput} = 0)

    s_1 = @fum function s_1()
        return point(0.16*y, 0.0)
    end

    s_2 = @fum function s_2(;tilt = 0)
        x_temp = x
        x = 0.85*x_temp + (0.04+tilt)*y
        y = -0.04*x_temp + 0.85*y + 1.6
        return point(y,x)
    end

    s_3 = @fum function s_3()
        x_temp = x
        x = 0.2*x_temp - 0.26*y
        y = 0.23*x_temp + 0.22*y + 1.6
        return point(y,x)
    end

    s_4 = @fum function s_4()
        x_temp = x
        x = -0.15*x_temp + 0.28*y
        y = 0.26*x_temp + 0.24*y + 0.44
        return point(y,x)
    end

    return [s_1, s_2(tilt = tilt), s_3, s_4]
end
