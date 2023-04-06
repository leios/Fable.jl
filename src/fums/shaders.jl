export Shaders, create_color

module Shaders

import Fae.@fum

custom = @fum color custom(; r = 0, g = 0, b = 0, a = 0) = RGBA(r, g, b, a)

previous = @fum color previous() = color

red = @fum color red() = RGBA(1, 0, 0, 1)
green = @fum color green() = RGBA(0,1,0,1)
blue = @fum color blue() = RGBA(0,0,1,1)
magenta = @fum color magenta() = RGBA(1,0,1,1)
white = @fum color white() = RGBA(1,1,1,1)
black = @fum color black() = RGBA(0,0,0,1)
gray = @fum color gray() = RGBA(0.5, 0.5, 0.5, 1)
grey = gray

end

create_color(a::FractalUserMethod) = a

function create_color(a::Union{Array, Tuple})
    if length(a) == 3
        return Shaders.custom(r = a[1], g = a[2], b = a[3], a = 1)
    elseif length(a) == 4
        return Shaders.custom(r = a[1], g = a[2], b = a[3], a = a[4])
    else
        error("Colors must have either 3 or 4 elements!")
    end

end

function create_color(a::RGB)
    return Shaders.custom(r = a.r, g = a.g, b = a.b, a = 1)
end

function create_color(a::RGBA)
    return Shaders.custom(r = a.r, g = a.g, b = a.b, a = a.alpha)
end

function define_color_operators(color::Union{RGBA, RGB, FractalUserMethod};
                                fnum = 4)
    color = create_color(color)
    return [color for i = 1:fnum]
end

function define_color_operators(t_color::Union{Tuple, Vector}; fnum = 4)
    if length(t_color) != fnum
        error("Expected color tuple of length "*string(fnum)*"!\n"*
              "Got "*string(length(t_color))*" instead!")
    end
    color = create_color(t_color)
    return [color for i = 1:fnum]
end

