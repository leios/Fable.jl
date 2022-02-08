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
    scene_1_frames = 60
    scene_2_frames = 300
    scene_3_frames = 90
    total_frames = scene_1_frames + scene_2_frames + scene_3_frames

    pos = [0.0, 0.0]
    color = [0.5, 0.25, 0.75, 1]
    rotation = 0.0
    scale = 0.75

    H = Fae.define_square(pos, rotation, scale, color; AT = AT)

    for i = 1:total_frames
        if i <= scene_1_frames
            if i <= 0.75*scene_1_frames
                rotation = (0.25*pi*(i-1))/(scene_1_frames*0.75)
            end
        
            color = [0.5, 0.25, 0.75 + 0.25*i/scene_1_frames, 1]
        elseif i > scene_1_frames && i <= scene_2_frames + scene_1_frames
            scene_frame = i - scene_1_frames

            rotation = 0.25*pi - (8.25*pi*scene_frame)/scene_2_frames

            scale = 0.75 - 0.35*scene_frame/scene_2_frames
            amp = (-2+scale)*scene_frame/scene_2_frames
            move_theta = 4*pi*scene_frame/scene_2_frames

            pos = [amp*cos(move_theta),0]

            color = [0.5 + 0.25*scene_frame/scene_2_frames,
                     0.25 - 0.25*scene_frame/scene_2_frames,
                     1 - 0.75*scene_frame / scene_2_frames, 1]
        elseif i > scene_2_frames + scene_1_frames
            scene_frame = i - scene_1_frames - scene_2_frames
            rotation = 0.0
            pos = [-2+scale,(1.125 - scale)*scene_frame/scene_3_frames]
            color = [0.75 + 0.25*scene_frame/scene_2_frames,
                     0 + 0.5*scene_frame/scene_2_frames,
                     0.25 + 0.75*scene_frame / scene_2_frames, 1]
        end

        println(color)

        Fae.update_square!(H, pos, rotation, scale, color; FT = FT, AT = AT)
        println(H.color_set)

        pix = Fae.fractal_flame(H, num_particles, num_iterations,
                                bounds, res; AT = AT, FT = FT)

        filename = "check"*lpad(i-1,5,"0")*".png"

        println("image time:")
        @time Fae.write_image([pix], filename)
    end
end

main()
