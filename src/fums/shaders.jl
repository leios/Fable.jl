export Shaders, create_color

module Shaders

import Fae.@fum

previous = @fum color function previous()
    return (red, green, blue, alpha)
end

# for now, to force a color, just make each color channel = -channel + 2*color
# used only for final colors
force_red = @fum color function force_red()
    red = -red + 2
    green = -green
    blue = -blue
    alpha = -alpha + 2
    return (red, green, blue, alpha)
end

custom = @fum color function custom(; r = 0, g = 0, b = 0, a = 0)
    red = red
    green = green
    blue = blue
    alpha = alpha
    return (red, green, blue, alpha)
end

gray = @fum color function gray()
    red = 0.5
    green = 0.5
    blue = 0.5
    alpha = 1
    return (red, green, blue, alpha)
end

grey = gray

red = @fum color function red()
    red = 1
    green = 0
    blue = 0
    alpha = 1
    return (red, green, blue, alpha)
end

green = @fum color function green()
    red = 0
    green = 1
    blue = 0
    alpha = 1
    return (red, green, blue, alpha)
end

blue = @fum color function blue()
    red = 0
    green = 0
    blue = 1
    alpha = 1
    return (red, green, blue, alpha)
end

magenta = @fum color function magenta()
    red = 1
    green = 0
    blue = 1
    alpha = 1
    return (red, green, blue, alpha)
end

white = @fum color function white()
    red = 1
    green = 1
    blue = 1
    alpha = 1
    return (red, green, blue, alpha)
end

black = @fum color function black()
    red = 0
    green = 0
    blue = 0
    alpha = 1
    return (red, green, blue, alpha)
end

end

create_color(a::FractalUserMethod) = a

function create_color(a::Union{Array, Tuple, RGB, RGBA})
    if isa(a, Array) || isa(a, Tuple)
        if length(a) == 3
            choice = "_" * string(round(a[1]; digits=4))*
                           string(round(a[2]; digits=4))*
                           string(round(a[3]; digits=4))
            choice = replace(choice, "." => "_")
            return Shaders.custom(red = a[1],
                                  green = a[2],
                                  blue = a[3],
                                  alpha = 1, name = choice)
        elseif length(a) == 4
            if a[4] > 0
                choice = "_" * string(round(a[1]; digits=4))*
                               string(round(a[2]; digits=4))*
                               string(round(a[3]; digits=4))*
                               string(round(a[4]; digits=4))
                choice = replace(choice, "." => "_")
                return Shaders.custom(red = a[1],
                                      green = a[2],
                                      blue = a[3],
                                      alpha = a[4], name = choice)
            else
                return Shaders.previous
            end
        else
            error("Colors must have either 3 or 4 elements!")
        end
    elseif isa(a, RGB)
        choice = "_" * string(round(a.r; digits=4))*
                       string(round(a.g; digits=4))*
                       string(round(a.b; digits=4))
        choice = replace(choice, "." => "_")
        return Shaders.custom(red = a.r,
                              green = a.g,
                              blue = a.b,
                              alpha = 1, name = choice)
    elseif isa(a, RGBA)
        choice = "_" * string(round(a.r; digits=4))*
                       string(round(a.g; digits=4))*
                       string(round(a.b; digits=4))*
                       string(round(a.alpha; digits=4))
        choice = replace(choice, "." => "_")
        if a.alpha > 0
            return Shaders.custom(red = a.r,
                                  green = a.g,
                                  blue = a.b,
                                  alpha = a.alpha, name = choice)
        else
                return Shaders.previous
        end
    else
        error("Element " * string(i) * " of color array is a " *
              string(typeof(a)) *
              " which cannot be converted to Fractal User Method!")
    end
end

