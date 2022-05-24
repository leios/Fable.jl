using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

AT = CuArray
FT = Float32

frames = 1

num_particles = 1000
num_iterations = 1000
bounds = [-2 2; -2 2]
res = (1000, 1000)

video_out = open_video((1000,1000); framerate = 30, filename = "out.mp4",
                       encoder_options = (crf=23, preset="medium"))

for i = 1:frames
    t = 1.5*(i-1)/frames

    H = Hutchinson([Flames.swirl,
                    Flames.polar,
                    Flames.heart,
                    Flames.horseshoe],
                   [],
                   [[0, 1, 0, 1.0],
                    [0, 0, 1, 1.0],
                    [1, 0, 1, 1.0],
                    [1, 0, 0, 1]],
                   (0.25,0.25, 0.25, 0.25);
                   final = false, diagnostic = true, AT = AT)

    H2 = Hutchinson([Flames.sinusoidal, Flames.identity],
                   [],
                   [[0.25, 0.25, 0.25, 1.0], [0,0,0,0]],
                   (1,0);
                   final = true, diagnostic = true, AT = AT, name = "2")

    pix = fractal_flame(H, H2, num_particles, num_iterations,
                        bounds, res; AT = AT, FT = FT)

    println("appending to video:")
    @time write_video!(video_out, [pix])

end

close_video(video_out)
