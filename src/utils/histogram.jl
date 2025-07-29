export find_bin, do_nothing, simple_output

function find_bin(pt::Point2D, cam::SimpleCamera)
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

function do_nothing(pix, cam, pt, clr)
end

function simple_output(pix, cam, pt, clr)
    bin = ceil(Int, find_bin(pt, cam))
    if bin > 1
        pix[bin] = clr
    end
end

