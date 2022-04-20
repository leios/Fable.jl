using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

function main()
    #AT = Array
    AT = CuArray
    FT = Float32


    wobble_freq = 5
    frame_array = [5,5,5]

    num_particles = 1000
    num_iterations = 1000
    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    pos = [0, 0.]
    color = [1., 1, 1, 1]
    radius = 0.4

    for i = 1:sum(frame_array)
        if i < frame_array[1]
        elseif i >= frame_array[1] && i < frame_array[2]
        elseif i >= frame_array[2] && i < frame_array[3]
        else
        end
    end
    new_loc = Fae.fi("loc",(0.5, 0.5))

    H = Fae.define_circle(pos, radius, color; AT = AT, diagnostic=true,
                          bounds = bounds, chosen_fx = :constant_disk)
    H2 = Fae.Hutchinson([Fae.shift(loc = new_loc), Fae.horseshoe], [new_loc],
                        [[1.0, 0, 1.0, 1.0],[0,1.0, 0, 1.0]], (0.75, 0.25);
                        final = true, diagnostic = true, AT = AT)

    pix = Fae.fractal_flame(H, H2, num_particles, num_iterations,
                            bounds, res; AT = AT, FT = FT)

    filename = "check.png"

    @time Fae.write_image([pix], filename)
end

main()
