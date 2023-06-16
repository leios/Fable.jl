using Fable
using Images

radial = @fum shader function radial(y, x; origin = (0,0))
    r = sqrt((x-origin[2])*(x-origin[2]) + (y-origin[1])*(y-origin[1]))

    red = 1
    green = min(1, 1/r)
    blue = 1
    alpha = min(1, 1/r)

    return RGBA{Float32}(red, green, blue, alpha)
end

rectangle = @fum shader function rectangle(; position = (0,0), rotation = 0,
                                      scale_x = 1, scale_y = 1)
    if in_rectangle(y, x, position, rotation, scale_x, scale_y)
        return RGBA(1,1,1,1)
    end
    return color
end

ellipse = @fum shader function ellipse(; position = (0,0), rotation = 0,
                                  r1 = 1, r2 = 1)
    if in_ellipse(y, x, position, rotation, r1, r2)
        return RGBA{Float32}(1,1,1,1)
    else
        return RGBA{Float32}(0,0,0,0)
    end
end

function shader_example(fum; ArrayType = Array, filename = "out.png")

    layer = ShaderLayer(fum; ArrayType = ArrayType, world_size = (9/4, 4),
                        ppu = 1920/4)

    run!(layer)

    write_image(layer; filename = filename)
end

@info("Created Function: shader_example(fum; ArrayType = Array,
                                       filename = 'out.png')\n"*
      "Defined fums: rectangle(; position = (0,0), rotation = 0,
                          scale_x = 1, scale_y = 1)
              ellipse(; position = (0,0), rotation = 0,
                        r1 = 1, r2 = 1)
              radial(y, x; origin = (0,0))")
