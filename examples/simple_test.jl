using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

AT = CuArray

f_set = (Fae.swirl, Fae.heart, Fae.polar, Fae.horseshoe)
color_set = [[0,1,0,1], [0,0,1,1], [1,0,1,1], [1,0,0,1]]
prob_set = (0.25, 0.25, 0.25, 0.25)

H = Fae.Hutchinson(f_set, color_set, prob_set; AT = AT)

num_particles = 1000
num_iterations = 1000
bounds = [-2 2; -2 2]
res = (1000, 1000)

Fae.fractal_flame(H, num_particles, num_iterations, bounds, res; AT = AT)
