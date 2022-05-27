export define_barnsley, update_barnsley!
function define_barnsley(color; AT = Array,
                         name = "barnsley",
                         diagnostic = false, FT = Float32)
    fums, fis = define_barnsley_operators()
    if length(color) == 1 || eltype(color) <: Number
        color_set = [create_color(color) for i = 1:4]
    else
        color_set = [create_color(color[i]) for i = 1:4]
    end
    prob_set = (0.01, 0.85, 0.07, 0.07)
    fos = [FractalOperator(fums[i], color_set[i], prob_set[i]) for i = 1:4]
    return Hutchinson(fos, fis; AT = AT, FT = FT,
                      name = name, diagnostic = diagnostic)
end

# This specifically returns the fums for a barnsley fern
function define_barnsley_operators()

    s_1 = @fum function s_1()
        x = 0
        y = 0.16*y
    end

    s_2 = @fum function s_2()
        x_temp = x
        x = 0.85*x_temp + 0.04*y
        y = -0.04*x_temp + 0.85*y + 1.6
    end

    s_3 = @fum function s_3()
        x_temp = x
        x = 0.2*x_temp - 0.26*y
        y = 0.23*x_temp + 0.22*y + 1.6
    end

    s_4 = @fum function s_4()
        x_temp = x
        x = -0.15*x_temp + 0.28*y
        y = 0.26*x_temp + 0.24*y + 0.44
    end

    return [s_1, s_2, s_3, s_4], []
end
