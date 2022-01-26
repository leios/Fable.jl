using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

AT = Array

f_set = (Fae.swirl, Fae.heart, Fae.polar, Fae.horseshoe)
color_set = [[0,1,0,1], [0,0,1,1], [1,0,1,1], [1,0,0,1]]
final_fx = Fae.swirl
final_clr = (0.0, 1.0, 0.0, 1.0)
prob_set = (0.25, 0.25, 0.25, 0.25)
#prob_set = (0.33, 0.33, 0.34)

H = Fae.Hutchinson(f_set, color_set, prob_set; AT = AT)

num_particles = 10000
num_iterations = 10000
bounds = [-2 2; -2 2]
res = (1000, 1000)

Fae.fractal_flame(H, num_particles, num_iterations, bounds, res; AT = AT,
                  final_fx = final_fx, final_clr = final_clr)
