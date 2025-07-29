abstract type AbstractCamera end;

struct SimpleCamera <: AbstractCamera
    ppu::Float32
    world_size::Point2D
    world_position::Point2D
end

function find_camera_width(cam::SimpleCamera)
    if (cam.world_size.x == 0)
        return 1
    end

    return ceil(cam.world_size.x * cam.ppu)
end

function find_camera_height(cam::SimpleCamera)
    if (cam.world_size.y == 0)
        return 1
    end

    return ceil(cam.world_size.y * cam.ppu)
end

