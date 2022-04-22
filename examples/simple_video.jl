using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

AT = CuArray
FT = Float32

frames = 1

num_particles = 10000
num_iterations = 10000
bounds = [-1.5 1.5; -1.5 1.5]
res = (1000, 1000)

for i = 1:frames
    filename = "check"*lpad(i-1,5,"0")*".png"
    t = 1.5*(i-1)/frames

    H = Fae.Hutchinson([Fae.rotate,
                        Fae.heart,
                        Fae.horseshoe],
                       [],
                       [[1.0, 0.25, 0.25, 1.0],
                        [1, 0, 1, 1.0],
                        [0.25, 0.25, 1, 1]],
                       (0.33, 0.33, 0.34);
                       final = false, diagnostic = true, AT = AT)

    pix = Fae.fractal_flame(H, num_particles, num_iterations,
                            bounds, res; AT = AT, FT = FT)

    @time Fae.write_image([pix], filename)

end
