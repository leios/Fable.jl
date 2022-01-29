using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

AT = Array
FT = Float32

frames = 60

for i = 1:frames
    theta = 2*pi*i/frames
    polar_theta(x,y) = Fae.polar(x,y;theta=theta)
    polar_heart(x,y) = Fae.polar(x,y;theta=theta)

    f_set = (Fae.swirl, polar_heart, polar_theta, Fae.horseshoe)
    color_set = [[0,1,0,1], [0,0,1,1], [1,0,1,1], [1,0,0,1]]
    final_fx = Fae.swirl
    final_clr = (FT(0.0), FT(1.0), FT(0.0), FT(1.0))
    prob_set = (0.25, 0.25, 0.25, 0.25)
    #prob_set = (0.33, 0.33, 0.34)

    H = Fae.Hutchinson(f_set, color_set, prob_set; AT = AT, FT = FT)

    num_particles = 10000
    num_iterations = 10000
    #num_particles = 10
    #num_iterations = 10
    bounds = [-2 2; -2 2]
    res = (1000, 1000)

    filename = "check"*lpad(i,5,"0")*".png"

    Fae.fractal_flame(H, num_particles, num_iterations, bounds, res; AT = AT,
                      FT = FT, filename = filename)
                      #FT = FT, final_fx = final_fx, final_clr = final_clr)
end
