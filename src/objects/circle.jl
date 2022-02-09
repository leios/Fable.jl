circle_0 = Fae.@fo function circle_0(x, y; radius = 1, pos = (0,0))
    # recentering x / y
    x_temp = x
    y_temp = y
    #x_temp = x - pos[1]
    #y_temp = y - pos[2]

    r = sqrt(x_temp*x_temp + y_temp*y_temp)
    theta = atan(y/x)

    k = - (3/8)*(sin(theta) + cos(theta)) +
        sqrt(1 - (9/64)*(sin(theta) - cos(theta))^2)

    x = r*k*cos(theta)
    y = r*k*sin(theta)
end

circle_odd = Fae.@fo function circle_odd(x, y; radius = 1, n = 0)
    # recentering x / y
    x_temp = x
    y_temp = y
    #x_temp = x - pos[1]
    #y_temp = y - pos[2]

    r = sqrt(x_temp*x_temp + y_temp*y_temp)
    theta = atan(y/x)

    k = - (3/8)*(sin(theta) + cos(theta)) +
        sqrt(1 - (9/64)*(sin(theta) - cos(theta))^2)

    x = r*k*cos(theta) + (3*sqrt(2)/8)*cos(n*pi/4)
    y = r*k*sin(theta) + (3*sqrt(2)/8)*sin(n*pi/4)

end

circle_even = Fae.@fo function circle_even(x, y; radius = 1, n = 0)
    # recentering x / y
    x_temp = x
    y_temp = y
    #x_temp = x - pos[1]
    #y_temp = y - pos[2]

    r = sqrt(x_temp*x_temp + y_temp*y_temp)
    theta = atan(y/x)

    k = - (3/8)*(sin(theta) + cos(theta)) +
        sqrt(1 - (9/64)*(sin(theta) - cos(theta))^2)

    x = r*k*(cos(theta)*cos(pi/4) + sin(theta)*sin(pi/4)) +
        (3*sqrt(2)/8)*cos(n*pi/4)
    y = r*k*(sin(theta)*cos(pi/4) + sin(pi/4)*cos(theta)) +
        (3*sqrt(2)/8)*sin(n*pi/4)

end

# Returns back H, colors, and probs for a circle
function define_circle(pos::Vector{FT}, radius::FT, color::Array{FT};
                       AT = Array, name = "circle") where FT <: AbstractFloat

    fos, fis = define_circle_operators(pos, radius)
    fo_num = length(fos)
    prob_set = Tuple([1/fo_num for i = 1:fo_num])
    println(prob_set)
    color_set = [color for i = 1:9]
    return Hutchinson(fos, fis, color_set, prob_set; AT = AT, FT = FT,
                      name = name)
end

# This specifically returns the fos for a circle
function define_circle_operators(pos::Vector{FT},
                                 radius) where FT <: AbstractFloat

   pos = fi("pos", pos)
   c_0 = circle_0(radius = radius)
   c_1 = circle_odd(radius = radius, n = 1)
   c_2 = circle_even(radius = radius, n = 2)
   c_3 = circle_odd(radius = radius, n = 3)
   c_4 = circle_even(radius = radius, n = 4)
   c_5 = circle_odd(radius = radius, n = 5)
   c_6 = circle_even(radius = radius, n = 6)
   c_7 = circle_odd(radius = radius, n = 7)
   c_8 = circle_even(radius = radius, n = 8)
   return [c_0, c_1, c_2, c_3, c_4, c_5, c_6, c_7, c_8], [pos]
   #return [circle_0], []

end

function update_circle!(H, pos, radius)
    update_circle!(H, pos, radius, nothing)
end

function update_circle!(H::Hutchinson, pos::Vector{F},
                       radius, color::Union{Array{F}, Nothing};
                       FT = Float64, AT = Array) where F <: AbstractFloat

    H.symbols = configure_fis!([p1, p2, p3, p4])
    if color != nothing
        H.color_set = new_color_array([color for i = 1:4], 4; FT = FT, AT = AT)
    end

end
