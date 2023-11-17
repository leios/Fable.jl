export current_frame, current_time, set_fps!

global FPS = 30.0
TimeInterface = Union{Int, AbstractFloat, Quantity}

function current_frame(f::Int)
    return f
end

function current_frame(t::AbstractFloat)
    return floor(Int, t*FPS)
end

function current_frame(q::Quantity)
    if !isa(q, Unitful.Time)
        error(string(q) * " does not have units of time!")
    end
    return floor(Int, (uconvert(u"s", q)*FPS).val)
end

function current_time(f::Int)
    return f/FPS
end

function current_time(t::AbstractFloat)
    return t
end

function current_time(q::Quantity)
    if !isa(q, Unitful.Time)
        error(string(q) * " does not have units of time!")
    end
    return q
end

set_fps!(fps) = (global FPS = fps)
