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
    scene_1_frames = 5
    scene_2_frames = 32
    scene_3_frames = 32
    total_frames = scene_1_frames + scene_2_frames + scene_3_frames

    pos = [0.0, 0.0]
    color = [0.5, 0.25, 0.75, 1]
    rotation = 0.0
    scale_x = 0.5
    scale_y = 0.5

#=
    H = Fae.define_rectangle(pos, rotation, scale_x, scale_y, color; AT = AT)

    H_2 = Fae.Hutchinson([Fae.test_flame], [], [1.0, 0, 1.0, 1.0], (1.0,);
                         AT = AT, name = "test")
=#

    fos, fis = Fae.define_rectangle_operators(pos, rotation, scale_x, scale_y)

    println(typeof(fos))
    fos_2 = [fos[1], fos[2], fos[3], fos[4], Fae.test_flame]

    prob_set = (0.2, 0.2, 0.2, 0.2, 0.2)

    color_set = [color for i = 1:5]

    H = Fae.Hutchinson(fos_2, fis, color_set, prob_set; AT = AT, FT = FT,
                       name = "meh")

    frequency_factor = 1.5
    exp_factor = 5

    for i = 1:total_frames
        if i <= scene_1_frames
            if i <= 0.75*scene_1_frames
                rotation = (0.25*pi*(i-1))/(scene_1_frames*0.75)
            end
        
            color = [0.5, 0.25, 0.75 + 0.25*i/scene_1_frames, 1]
        elseif i > scene_1_frames && i <= scene_2_frames + scene_1_frames
            scene_frame = i - scene_1_frames

            if scene_frame <= 0.25*scene_2_frames
                scale_y = 0.5 + 0.35*scene_frame/(0.25*scene_2_frames)
            else
                y = (scene_frame - 0.25*scene_2_frames-1)/(0.75*scene_2_frames)
                move_theta = frequency_factor*2*pi*y
                scale_y = 0.5 + 0.35*cos(move_theta)*exp(-exp_factor*y)
            end

        elseif i > scene_1_frames + scene_2_frames
            scale_y = 0.5
            scene_frame = i - scene_1_frames - scene_2_frames

            if scene_frame < 0.25*scene_3_frames
                scale_x = 0.5 + 0.35*scene_frame/(0.25*scene_3_frames)
            else
                x = (scene_frame - 0.25*scene_3_frames-1)/(0.75*scene_3_frames)
                move_theta = frequency_factor*2*pi*x
                scale_x = 0.5 + 0.35*cos(move_theta)*exp(-exp_factor*x)
            end

        end

        Fae.update_rectangle!(H, pos, rotation, scale_x, scale_y, color;
                              FT = FT, AT = AT, fnum = 5)

        pix = Fae.fractal_flame(H, num_particles, num_iterations,
                                bounds, res; AT = AT, FT = FT)

        filename = "check"*lpad(i-1,5,"0")*".png"

        println("image time:")
        @time Fae.write_image([pix], filename)
    end
end

main()
