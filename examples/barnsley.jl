using Fae, Images, CUDA
using Fae: Colors

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

    fo_1 = scale_and_translate(prob = 0.5, color = Colors.previous,
                               translation = (0.5, 0.5), scale = 0.5)
    fo_2 = FractalOperator(Flames.identity, Colors.magenta, 0.5)

    H2 = fee([fo_1, fo_2]; name = "2", final = true)

    #println(fo_1, '\n', fo_2)

    fractal_flame!(pix, H, H2, num_particles, num_iterations,
                   bounds, res; AT = AT, FT = FT)

    filename = "check.png"

    @time write_image([pix], filename)
end

main()
