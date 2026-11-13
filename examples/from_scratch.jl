using Images

struct FablePoint{X, Y}
    x::X
    y::Y
end

struct FableSimpleCamera{P, W, WP}
    ppu::P
    world_size::W
    world_position::WP
end

function do_nothing(pix, cam, pt, clr)
end

function simple_output(pix, cam, pt, clr)
    bin = ceil(Int, find_bin(pt, cam))
    if bin > 1
        pix[bin] = clr
    end
end

function find_camera_width(cam::FableSimpleCamera)
    if (cam.world_size.x == 0)
        return 1
    end

    return ceil(cam.world_size.x * cam.ppu)
end

function find_camera_height(cam::FableSimpleCamera)
    if (cam.world_size.y == 0)
        return 1
    end

    return ceil(cam.world_size.y * cam.ppu)
end


function find_bin(pt::FablePoint, cam::FableSimpleCamera)
    width = find_camera_width(cam)
    height = find_camera_height(cam)

    x_bin = 0
    if (cam.world_size.x > 0)
        x_bin = floor(width * ((pt.x - cam.world_position.x)/cam.world_size.x))
    end

    if (x_bin < 0 || x_bin > width)
        return -1
    end

    y_bin = 0;
    if (cam.world_size.y > 0)
        y_bin = floor(height * ((pt.y - cam.world_position.y)/cam.world_size.y))
    end

    if (y_bin < 0 || y_bin > height)
        return -1
    end

    return y_bin + x_bin * height
end

function halfway(A::FablePoint, B::FablePoint)
    return FablePoint(0.5*(A.x + B.x), 0.5*(A.y + B.y))
end

@generated function square(pix, cam,
                           num_iterations::Int,
                           pt::FablePoint,
                           clr::RGBA{Float32},
                           A::FablePoint,
                           c_A::RGBA{Float32},
                           B::FablePoint,
                           c_B::RGBA{Float32},
                           C::FablePoint,
                           c_C::RGBA{Float32},
                           D::FablePoint,
                           c_D::RGBA{Float32},
                           g, args...; kwargs...)
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
            else
            end
            g(pix, cam, pt, clr, args...; kwargs...)
        end

        return pt
    end
end

macro square_macro(num_iterations::Int,
                   A,
                   c_A,
                   B,
                   c_B,
                   C,
                   c_C,
                   D,
                   c_D,
                   ex)
    expr = quote
        pt = FablePoint(0.0, 0.0)
        clr = RGBA{Float32}(0,0,0,0)
        for i = 1:$num_iterations
            chosen_fx = rand(1:4)
            if chosen_fx == 1
                pt = halfway(pt, $A)
                clr = $c_A
            elseif chosen_fx == 2
                pt = halfway(pt, $B)
                clr = $c_B
            elseif chosen_fx == 3
                pt = halfway(pt, $C)
                clr = $c_C
            elseif chosen_fx == 4
                pt = halfway(pt, $D)
                clr = $c_D
            else
            end
            $ex
        end
    end

end

