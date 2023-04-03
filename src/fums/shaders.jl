export Shaders, create_color

module Shaders

import Fae.@fum

custom = @fum color custom(; r = 0, g = 0, b = 0, a = 0) = RGBA(r, g, b, a)

previous = @fum color function previous() = color

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

