export SimpleCamera

abstract type AbstractCamera end;

struct SimpleCamera{F, P, WP} <: AbstractCamera
    ppu::F
    world_size::P
    world_position::WP
end

function find_camera_width(cam::SimpleCamera)
    if (cam.world_size.x == 0)
        return 1.0f0
    end

    return ceil(Float32, cam.world_size.x * cam.ppu)
end

function find_camera_height(cam::SimpleCamera)
    if (cam.world_size.y == 0)
        return 1.0f0
    end

    return ceil(Float32, cam.world_size.y * cam.ppu)
end

