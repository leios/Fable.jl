export SimpleCamera
export find_bin, simple_output

abstract type AbstractCamera end;

struct SimpleCamera{F, P, WP} <: AbstractCamera
    ppu::F
    world_size::P
    world_position::WP
end

function find_camera_width(cam::SimpleCamera)::Int32
    if (cam.world_size.x == 0)
        return Int32(1)
    end

    return ceil(Int32, cam.world_size.x * cam.ppu)
end

function find_camera_height(cam::SimpleCamera)::Int32
    if (cam.world_size.y == 0)
        return Int32(1)
    end

    return ceil(Int32, cam.world_size.y * cam.ppu)
end

function find_bin(pt::Point2D, cam::SimpleCamera)::Int32
    width::Int32 = find_camera_width(cam)
    height::Int32 = find_camera_height(cam)

    x_bin::Int32 = 0
    if (cam.world_size.x > 0)
        x_bin = floor(Int32, width * ((pt.x - cam.world_position.x)/cam.world_size.x))
    end

    if (x_bin < 0 || x_bin > width)
        return Int32(-1)
    end

    y_bin::Int32 = 0;
    if (cam.world_size.y > 0)
        y_bin = floor(Int32, height * ((pt.y - cam.world_position.y)/cam.world_size.y))
    end

    if (y_bin < 0 || y_bin > height)
        return Int32(-1)
    end

    return y_bin + x_bin * height
end

function simple_output(pix, cam, pt, clr)
    bin = find_bin(pt, cam)
    if bin > 1
        pix[bin] = clr
    end
end

