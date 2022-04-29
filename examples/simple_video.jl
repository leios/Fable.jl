using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

AT = Array
FT = Float32

frames = 1

num_particles = 10000
num_iterations = 10000
bounds = [-2 2; -2 2]
res = (1000, 1000)

for i = 1:frames
    filename = "check"*lpad(i-1,5,"0")*".png"
    t = 1.5*(i-1)/frames

    H = Fae.Hutchinson([Fae.swirl,
                        Fae.polar,
                        Fae.heart,
                        Fae.horseshoe],
                       [],
                       [[0, 1, 0, 1.0],
                        [0, 0, 1, 1.0],
                        [1, 0, 1, 1.0],
                        [1, 0, 0, 1]],
                       (0.25,0.25, 0.25, 0.25);
                       final = false, diagnostic = true, AT = AT)

    H2 = Fae.Hutchinson([Fae.sinusoidal, Fae.identity],
                       [],
                       [[0.25, 0.25, 0.25, 1.0], [0,0,0,0]],
                       (1,0);
                       final = true, diagnostic = true, AT = AT, name = "2")

    pix = Fae.fractal_flame(H, H2, num_particles, num_iterations,
                            bounds, res; AT = AT, FT = FT)

    @time Fae.write_image([pix], filename)

end
