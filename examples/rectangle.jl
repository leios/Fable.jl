using Fae, Images, CUDA

if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
end

function main(num_particles, num_iterations, total_frames, AT)
    FT = Float32

    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)
    scene_1_frames = total_frames / 2
    scene_2_frames = total_frames / 2

    pos = [0.0, 0.0]
    color = [0.5, 0.25, 0.75, 1]
    rotation = 0.0
    scale_x = 0.5
    scale_y = 0.75

    H = Fae.define_rectangle(pos, rotation, scale_x, scale_y, color; AT = AT)

    for i = 1:total_frames
        if i <= scene_1_frames
            if i <= 0.75*scene_1_frames
                rotation = (0.25*pi*(i-1))/(scene_1_frames*0.75)
            end
        
            color = [0.5, 0.25, 0.75 + 0.25*i/scene_1_frames, 1]
        elseif i > scene_1_frames && i <= scene_2_frames + scene_1_frames
            scene_frame = i - scene_1_frames

            scale_y = 0.75 - 0.35*scene_frame/scene_2_frames
            scale_x = 0.5 + 0.35*scene_frame/scene_2_frames

            color = [0.5 + 0.25*scene_frame/scene_2_frames,
                     0.25 - 0.25*scene_frame/scene_2_frames,
                     1 - 0.75*scene_frame / scene_2_frames, 1]
        end

        Fae.update_rectangle!(H, pos, rotation, scale_x, scale_y, color;
                              FT = FT, AT = AT)

        pix = Fae.fractal_flame(H, num_particles, num_iterations,
                                bounds, res; AT = AT, FT = FT)

        filename = "check"*lpad(i-1,5,"0")*".png"

        println("image time:")
        @time Fae.write_image([pix], filename)
    end
end
