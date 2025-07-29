export square, triangle, circle, sierpinski

function halfway(A::Point2D, B::Point2D)
    return FablePoint(0.5*(A.x + B.x), 0.5*(A.y + B.y))
end

#=-----------------------------------------------------------------------------#
    RECTANGLES
#-----------------------------------------------------------------------------=#

function rectangle(pix, cam,
                   num_iterations::Int,
                   pt::Point2D,
                   clr::RGBA{Float32},
                   args...;
                   g = do_nothing,
                   rotation = 0,
                   position = (0,0),
                   scale_x = 1,
                   scale_y = 1,
                   kwargs...)

    scale_x *= 0.5
    scale_y *= 0.5

    p_x = scale_x*cos(rotation) - scale_y*sin(rotation) + position.x
    p_y = scale_x*sin(rotation) + scale_y*cos(rotation) + position.y

    v_1 = point(p_y, p_x)

    p_x = scale_x*cos(rotation) + scale_y*sin(rotation) + position.x
    p_y = scale_x*sin(rotation) - scale_y*cos(rotation) + position.y

    v_2 = point(p_y, p_x)

    p_x = - scale_x*cos(rotation) + scale_y*sin(rotation) + position.x
    p_y = - scale_x*sin(rotation) - scale_y*cos(rotation) + position.y
    v_3 = point(p_y, p_x)

    p_x = - scale_x*cos(rotation) - scale_y*sin(rotation) + position.x
    p_y = - scale_x*sin(rotation) + scale_y*cos(rotation) + position.y
    v_4 = point(p_y, p_x)

    rectangle(pix, cam, num_iterations, pt, v_1, clr, v_2, clr, v_3, clr, v_4, clr, args...; g = g, kwargs...)
end

@generated function rectangle(pix, cam,
                              num_iterations::Int,
                              pt::Point2D,
                              clr::RGBA{Float32},
                              A::Point2D,
                              c_A::RGBA{Float32},
                              B::Point2D,
                              c_B::RGBA{Float32},
                              C::Point2D,
                              c_C::RGBA{Float32},
                              D::Point2D,
                              c_D::RGBA{Float32},
                              args...; g = do_nothing, kwargs...)
    expr = quote
        for i = 1:num_iterations
            chosen_fx = rand(1:4)
            if chosen_fx == 1
                pt = halfway(pt, A)
                clr = c_A
            elseif chosen_fx == 2
                pt = halfway(pt, B)
                clr = c_B
            elseif chosen_fx == 3
                pt = halfway(pt, C)
                clr = c_C
            elseif chosen_fx == 4
                pt = halfway(pt, D)
                clr = c_D
            end
            g(pix, cam, pt, clr, args...; kwargs...)
        end

        return pt
    end
end

#=-----------------------------------------------------------------------------#
    TRIANGLES
#-----------------------------------------------------------------------------=#

@generated function sierpinski(pix, cam,
                               num_iterations::Int,
                               pt::Point2D,
                               clr::RGBA{Float32},
                               A::Point2D,
                               c_A::RGBA{Float32},
                               B::Point2D,
                               c_B::RGBA{Float32},
                               C::Point2D,
                               c_C::RGBA{Float32},
                               args...; g = do_nothing, kwargs...)
    expr = quote
        for i = 1:num_iterations
            chosen_fx = rand(1:3)
            if chosen_fx == 1
                pt = halfway(pt, A)
                clr = c_A
            elseif chosen_fx == 2
                pt = halfway(pt, B)
                clr = c_B
            elseif chosen_fx == 3
                pt = halfway(pt, C)
                clr = c_C
            end
            g(pix, cam, pt, clr, args...; kwargs...)
        end

        return pt
    end
end

function triangle_fill(pt::Point2D;
                       A = point(0,0),
                       B = point(0,0),
                       C = point(0,0))
    midpoint_y = (A.y + B.y + C.y) ./ 3
    midpoint_x = (A.x + B.x + C.x) ./ 3

    y = midpoint_y - (pt.y - midpoint_y) * 0.5
    x = midpoint_x - (pt.x - midpoint_x) * 0.5
    return point(y,x)
end

@generated function triangle(pix, cam,
                               num_iterations::Int,
                               pt::Point2D,
                               clr::RGBA{Float32},
                               A::Point2D,
                               c_A::RGBA{Float32},
                               B::Point2D,
                               c_B::RGBA{Float32},
                               C::Point2D,
                               c_C::RGBA{Float32},
                               args...; g = do_nothing, kwargs...)
    expr = quote
        for i = 1:num_iterations
            chosen_fx = rand(1:4)
            if chosen_fx == 1
                pt = halfway(pt, A)
                clr = c_A
            elseif chosen_fx == 2
                pt = halfway(pt, B)
                clr = c_B
            elseif chosen_fx == 3
                pt = halfway(pt, C)
                clr = c_C
            elseif chosen_fx == 4
                pt = triangle_fill(pt; A, B, C)
                clr = c_C
            end
            g(pix, cam, pt, clr, args...; kwargs...)
        end

        return pt
    end
end

#=-----------------------------------------------------------------------------#
    CIRCLES
#-----------------------------------------------------------------------------=#

function naive_disk(pt::Point2D;
                    radius = 1,
                    position = point(0,0),
                    function_index = 0)

    @inbounds x_temp = (pt.x-position.x)/radius
    @inbounds y_temp = (pt.y-position.y)/radius
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

    @inbounds x = radius*r2*cos(theta2)+position.x
    @inbounds y = radius*r2*sin(theta2)+position.y
    return point(y,x)
end

function constant_disk(pt::Point2D;
                       radius = 1,
                       position = point(0,0),
                       function_index = 0)

    @inbounds x_temp = (pt.x-position.x)/radius
    @inbounds y_temp = (pt.y-position.y)/radius
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

    @inbounds x = radius*r2*cos(theta2)+position.x
    @inbounds y = radius*r2*sin(theta2)+position.y
    return point(y,x)
end

@generated function circle(pix, cam,
                           num_iterations::Int,
                           position::Point2D,
                           Radius::F,
                           c_A::RGBA{Float32},
                           c_B::RGBA{Float32},
                           args...;
                           g = do_nothing, kwargs...
                           ) where F <: AbstractFloat
    expr = quote
        for i = 1:num_iterations
            chosen_fx = rand(1:2)
            if chosen_fx == 1
                pt = constant_disk(pt; radius, position, function_index = 0)
                clr = c_A
            elseif chosen_fx == 2
                pt = constant_disk(pt; radius, position, function_index = 0)
                clr = c_B
            end
            g(pix, cam, pt, clr, args...; kwargs...)
        end

        return pt
    end
end

@generated function exponential_circle(pix, cam,
                                       num_iterations::Int,
                                       position::Point2D,
                                       Radius::F,
                                       c_A::RGBA{Float32},
                                       c_B::RGBA{Float32},
                                       args...;
                                       g = do_nothing, kwargs...
                                       ) where F <: AbstractFloat
    expr = quote
        for i = 1:num_iterations
            chosen_fx = rand(1:2)
            if chosen_fx == 1
                pt = naive_disk(pt; radius, position, function_index = 0)
                clr = c_A
            elseif chosen_fx == 2
                pt = naive_disk(pt; radius, position, function_index = 0)
                clr = c_B
            end
            g(pix, cam, pt, clr, args...; kwargs...)
        end

        return pt
    end
end


