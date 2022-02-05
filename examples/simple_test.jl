using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

AT = CuArray
FT = Float32

t = 0.25

f_set = [Fae.square_1, Fae.square_2, Fae.square_3, Fae.square_4]
color_set = [[0,1,0,1], [1,0,1,1], [0,0,1,1], [1,0,0,1]]
prob_set = (0.25, 0.25, 0.25, 0.25)

H = Fae.Hutchinson(f_set, color_set, prob_set, 4; AT = AT, FT = FT)

num_particles = 10000
num_iterations = 10000
#num_particles = 10
#num_iterations = 10
bounds = [-1 1; -1 1]
res = (1000, 1000)

pix = Fae.fractal_flame(H, num_particles, num_iterations, bounds, res; AT = AT,
                        FT = FT, time = t)


println("image time:")
@time Fae.write_image([pix], "check.png")
