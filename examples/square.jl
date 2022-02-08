using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

function main()
    AT = CuArray
    FT = Float32

    num_particles = 10000
    num_iterations = 10000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)
    frames = 10

    pos = [0.0, 0.0]
    color = [0.5, 0.25, 0.75, 1]
    rotation = 0
    scale = 0.5

    #This is to overcome KA issue #287
    Hs = Array{Fae.Hutchinson}(undef, frames)

    for i = 1:frames
        rotation = 2*pi*i/frames
        Hs[i] = Fae.define_square(pos, rotation, scale, color; AT = AT)


        pix = Fae.fractal_flame(Hs[i], num_particles, num_iterations,
                                bounds, res; AT = AT, FT = FT)

        filename = "check"*lpad(i-1,5,"0")*".png"

        println("image time:")
        @time Fae.write_image([pix], filename)
    end
end

main()
