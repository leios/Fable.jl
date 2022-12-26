using Fae

radial = @fum function radial(y, x; origin = (0,0))
    r = sqrt((x-origin[2])*(x-origin[2]) + (y-origin[1])*(y-origin[1]))

    red = 1
    green = min(1, 1/r)
    blue = 1
    alpha = min(1, 1/r)
end

function shader_example(fum; res = (1080,1920), ArrayType = Array,
                        filename = "out.png")

    layer = ShaderLayer(fum; ArrayType = ArrayType, world_size = (9/4, 4),
                        ppu = 1920/4)

    run!(layer)

    write_image(layer; filename = filename)
end
