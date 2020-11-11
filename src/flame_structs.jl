struct Point
    x::Float64
    y::Float64
    c::Union{RGB, RGBA}
end

Point(x, y) = Point(x, y, RGB(0))

mutable struct Pixel
    val::Float64
    c::Union{RGB, RGBA}
end

Pixel(x) = Pixel(x, RGB(0))
