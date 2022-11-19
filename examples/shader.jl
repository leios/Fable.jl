using Fae

radial = @fum function radial(y, x; origin = (0,0))
    r = sqrt((x-origin[2])*(x-origin[2]) + (y-origin[1])*(y-origin[1]))

    red = 1
    green = min(1, 1/r)
    blue = 1
    alpha = min(1, 1/r)
end

function main(fum; res = (1080,1920), AT = Array, FT = Float32,
              filename = "out.png")

    bounds = [-4.5 4.5; -8 8] * 0.25

    layer = ShaderLayer(fum, res; AT = AT, FT = FT)

    run!(layer, res, bounds)

    write_image(layer, filename)
end
