using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

AT = CuArray
FT = Float32

H = Fae.define_square([0.0,0.0], 0.0, 1.0, [0.5, 0, 0.5, 1]; AT = AT)

num_particles = 10000
num_iterations = 10000
#num_particles = 10
#num_iterations = 10
bounds = [-1 1; -1 1]
res = (1000, 1000)

pix = Fae.fractal_flame(H, num_particles, num_iterations, bounds, res; AT = AT,
                        FT = FT)


println("image time:")
@time Fae.write_image([pix], "check.png")
