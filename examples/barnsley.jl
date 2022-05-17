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

function create_stars(n; scale_factor = 1, max_range = 2, color = [1, 1, 1, 1])
    fos = [FractalOperator() for i = 1:n]
    fos = [FractalOperator() for i = 1:n]
    for i = 1:n
        temp_translation = (rand()*2*max_range - max_range,
                            rand()*2*max_range - max_range)
        temp_scale = scale_factor*(0.5*(rand()-1) + 1)
        temp_fo = scale_and_translate(translation = temp_translation,
                                      scale = temp_scale, prob = 1/n,
                                      color = color)
        fos[i] = temp_fo
    end
    return Hutchinson(fos; final = true, name = "stars", diagnostic = true)

end

function main()
    AT = Array
    FT = Float32

    num_particles = 1000
    num_iterations = 1000
    bounds = [0 10; -8 8]
    res = (1080, 1920)

    pix = Pixels(res; AT = AT, FT = FT)

    pos = [0, 0.]
    color = [1., 1, 1, 1]
    radius = 1

    color_1 = [1.,1,1,1]
    color_2 = [1.,0,0,1]
    color_3 = [0.,1,0,1]
    color_4 = [0.,0,1,1]

    H = define_barnsley(color_1, color_2, color_3, color_4;
                        AT = AT, diagnostic=true)

    #H2 = create_stars(10; max_range = 1, scale_factor = 0.1)

    fractal_flame!(pix, H, num_particles, num_iterations,
                   bounds, res; AT = AT, FT = FT)

    filename = "check.png"

    @time write_image([pix], filename)
end

main()
