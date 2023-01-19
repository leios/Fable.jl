export define_circle, update_circle!

# TODO:
#     1. Use Box--Muller so we don't need polar input
#     2. Add constant density disk
# Code examples modified from: https://www.math.uwaterloo.ca/~wgilbert/FractalGallery/IFS/IFS.html

naive_disk = Fae.@fum function naive_disk(x, y; radius = 1, pos = (0,0),
                                         function_index = 0)
    x_temp = (x-pos[2])/radius
    y_temp = (y-pos[1])/radius
    r = sqrt(x_temp*x_temp + y_temp*y_temp)

    theta = pi
    if !isapprox(r, 0)
        theta = atan(y_temp,x_temp)
        if y_temp < 0
            theta += 2*pi
        end
    end

    theta2 = (r+function_index)*pi
    r2 = theta/(2*pi)

    x = radius*r2*cos(theta2)+pos[2]
    y = radius*r2*sin(theta2)+pos[1]
end

constant_disk = Fae.@fum function constant_disk(x, y; radius = 1, pos = (0,0),
                                                function_index = 0)

    x_temp = (x-pos[2])/radius
    y_temp = (y-pos[1])/radius
    r = x_temp*x_temp + y_temp*y_temp

    theta = pi
    if !isapprox(r, 0)
        theta = atan(y_temp,x_temp)
        if y_temp < 0
            theta += 2*pi
        end
    end

    theta2 = (r+function_index)*pi
    r2 = sqrt(theta/(2*pi))

    x = radius*r2*cos(theta2)+pos[2]
    y = radius*r2*sin(theta2)+pos[1]

end

# Returns back H, colors, and probs for a circle
function define_circle(; position = [0.0, 0.0],
                         radius = 1.0,
                         color = Shaders.gray,
                         name = "circle",
                         chosen_fx = :constant_disk,
                         diagnostic = false)

    fums, fis = define_circle_operators(position, radius; chosen_fx = chosen_fx,
                                        name = name)
    if length(color) == 1 || eltype(color) <: Number
        color_set = [create_color(color) for i = 1:2]
    elseif length(color) == 2
        color_set = [create_color(color[i]) for i = 1:2]
    else
        error("cannot convert colors for circle, "*
              "maybe improper number of functions?")
    end
    fos = [FractalOperator(fums[i], color_set[i], 0.5) for i = 1:2]
    return Hutchinson(fos, fis; name = name, diagnostic = diagnostic)
end

# This specifically returns the fums for a circle
function define_circle_operators(pos::Union{Vector, Tuple}, radius;
                                 chosen_fx = :constant_disk,
                                 name = "circle")

    f_0 = fi("f_0_"*name, 0)
    f_1 = fi("f_1_"*name, 1)
    pos = fi("pos_"*name, Tuple(pos))
    radius = fi("radius_"*name, radius)
    if chosen_fx == :naive_disk
        d_0 = naive_disk(function_index = f_0, pos = pos, radius = radius)
        d_1 = naive_disk(function_index = f_1, pos = pos, radius = radius)
    elseif chosen_fx == :constant_disk
        d_0 = constant_disk(function_index = f_0, pos = pos, radius = radius)
        d_1 = constant_disk(function_index = f_1, pos = pos, radius = radius)
    else
        error("function not found for circle IFS!")
    end
    return [d_0, d_1], [f_0, f_1, pos, radius]

end

function update_circle!(H, pos, radius)
    update_circle!(H, pos, radius, nothing)
end

function update_circle!(H::Hutchinson, pos::Union{Vector, Tuple}, radius,
                        color::Union{Array, Tuple, Nothing})
    
    H.fi_set[3] = FractalInput(H.fi_set[3].index, H.fi_set[3].name, Tuple(pos))
    H.fi_set[4] = FractalInput(H.fi_set[4].index, H.fi_set[4].name, radius)
    
    H.symbols = configure_fis!(H.fi_set)
    if color != nothing
        H.color_set = new_color_array([color for i = 1:2], 4)
    end

end
