using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

scale_and_translate = @fo function scale_and_translate(x, y;
                                                       translation = (0,0),
                                                       scale = 1)
    x = scale*x + translation[2]
    y = scale*y + translation[1]
end


function main()
    AT = Array
    FT = Float32

    num_particles = 1000
    num_iterations = 1000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    pix = Pixels(res; AT = AT, FT = FT)

    #pos = [-1, -1.5]
    pos = [0, 0.]
    #color = [0.5, 0.25, 0.75, 1]
    color = [1., 1, 1, 1]
    radius = 0.25
    #radius = 1.0

    fi_array = fi("fi_array", [0.5 0.5 3; 0.5 5 6])

    new_loc = fi("loc",(0.5, 0.5))
    scale = fi("scale", 0.5)
    new_loc2 = fi("loc2",(-0.5, -0.5))
    scale2 = fi("scale2", 0.75)

    fo1 = scale_and_translate(translation = fi_array[1:2], scale = scale,
                              prob = 0.5, color = (1,0,1,1))
    fo2 = scale_and_translate(translation = new_loc2, scale = scale2,
                              prob = 0.5, color = (0,1,0,1))

    H = define_circle(pos, radius, color; AT = AT, diagnostic=true,
                      bounds = bounds, chosen_fx = :constant_disk)
    H2 = Hutchinson([fo1, fo2],
                    [new_loc, scale, new_loc2, scale2, fi_array];
                    final = true, diagnostic = true, AT = AT)

    fractal_flame!(pix, H, H2, num_particles, num_iterations,
                   bounds, res; AT = AT, FT = FT)

    filename = "check.png"

    @time write_image([pix], filename)
end

main()
