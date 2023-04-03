using Fae

radial = @fum shader function radial(y, x; origin = (0,0))
    r = sqrt((x-origin[2])*(x-origin[2]) + (y-origin[1])*(y-origin[1]))

    red = 1
    green = min(1, 1/r)
    blue = 1
    alpha = min(1, 1/r)

    return red, green, blue, alpha
end

rectangle = @fum shader function rectangle(; position = (0,0), rotation = 0,
                                      scale_x = 1, scale_y = 1)
    if in_rectangle(x, y, position, rotation, scale_x, scale_y)
        return RGBA(1,1,1,1)
    end
    return color
end

ellipse = @fum shader function ellipse(; position = (0,0), rotation = 0,
                                  r1 = 1, r2 = 1)
    if in_ellipse(x, y, position, rotation, r1, r2)
        red = 1
        green = 1
        blue = 1
        alpha = 1
    else
        red = 0
        green = 0
        blue = 0
        alpha = 0
    end
    return red, green, blue, alpha
end

function shader_example(fum; ArrayType = Array, filename = "out.png")

    layer = ShaderLayer(fum; ArrayType = ArrayType, world_size = (9/4, 4),
                        ppu = 1920/4)

    run!(layer)

    write_image(layer; filename = filename)
end
