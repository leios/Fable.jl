#-------------splat.jl---------------------------------------------------------#
#
# Purpose: This implements the `@splat` output macro for use within fees, fos,
#          and fums.
#
#
#   Notes: I need to create a FableColor type that has RGBA, values, and
#              priority. I als need to create Base.:(+) for it.
#          I can create new on_image fucntions if the pt is in 3D
#
#------------------------------------------------------------------------------#

export splat

"""
    @splat method = simple atomic = true buffer = output_buffer

Will splat (output) a given point to screen. If no configuration is given, it
will default to a simple atomic operation where each point corresponds to a 
single pixel in the output buffer
"""
macro splat(ex...)
    # default configurations
    buffer = :output_buffer
    atomic = true
    method = __simple_splat

    # setting user configuration
    if length(ex) > 0
        for i = 1:length(ex)
            if ex[i].args[1] == :method
                println(ex[i].args[2])
                if ex[i].args[2] != :simple
                    error("Splat method ", ex[i].args[2], " not found!")
                end        
            elseif ex[i].args[1] == :atomic
                if ex[i].args[2] == true || ex[i].args[2] == false
                    atomic = ex[i].args[2]
                else
                    error("atomic splat config argument must be boolean!")
                end
            elseif ex[i].args[1] == :buffer
                if isa(ex[i].args[2], Symbol)
                    buffer = ex[i].args[2]
                else
                    error("buffer splat config must point to a buffer!")
                end
            else
                error("Incorrect splat config argument ", ex[i], "!")
            end
        end
    end

    return method(atomic, buffer)

end

#------------------------------------------------------------------------------#
# Splat methods
#------------------------------------------------------------------------------#

function __simple_splat(atomic, buffer)
    if atomic
        return quote
            if on_image(pt, bounds)
                bin = find_bin(pt, $buffer, bounds, bin_widths)
                @inbounds @atomic $buffer[bin] += color
            end
        end
    else
        return quote
            if on_image(pt, bounds)
                bin = find_bin(pt, $buffer, bounds, bin_widths)
                @inbounds $buffer[bin] += color
            end
        end
    end
end

#------------------------------------------------------------------------------#
# Aux methods
#------------------------------------------------------------------------------#

unsafe_ceil(T, x) = Base.unsafe_trunc(T, round(x, RoundUp))

@inline function find_bin(input::Point2D, histogram_output, bounds, bin_widths)

    @inbounds begin
        bin_y = unsafe_ceil(Int, (input.y - bounds[1]) / bin_widths[1])
        bin_x = unsafe_ceil(Int, (input.x - bounds[3]) / bin_widths[2])
    end

    return CartesianIndex(bin_y, bin_x)
end


# couldn't figure out how to get an n-dim version working for GPU
@inline function on_image(p::Point2D, bounds)
    flag = true
    if p.y <= bounds.ymin || p.y > bounds.ymax ||
       p.y == NaN || p.y == Inf
        flag = false
    end

    if p.x <= bounds.xmin || p.x > bounds.xmax ||
       p.x == NaN || p.x == Inf
        flag = false
    end
    return flag
end

