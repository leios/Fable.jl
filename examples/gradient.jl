using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end


function main()
    AT = Array
    FT = Float32

    gradient = @fum function gradient(x, y)
        red = abs(y)%1
        green = 0
        blue = abs(x)%1
        alpha = 1
    end

    num_particles = 10000
    num_iterations = 10000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    pos = [0.0, 0.0]
    rotation = 0.0
    scale_x = 0.5
    scale_y = 0.75

    #H = Fae.define_rectangle(pos, rotation, scale_x, scale_y, gradient; AT = AT)
    H = Fae.define_circle(pos, 1.0, gradient; AT = AT)
    #H = Fae.define_barnsley(gradient; AT = AT)
    #H = Fae.define_sierpinski([-1.,-1], [-1.,1], [0.,0], gradient; AT = AT)

    pix = Fae.fractal_flame(H, num_particles, num_iterations,
                            bounds, res; AT = AT, FT = FT)

    filename = "check.png"

    println("image time:")
    @time Fae.write_image([pix], filename)
end

main()
