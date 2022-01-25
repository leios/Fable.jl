function iterate!(ps::Points, pxs::Pixels, H::Hutchinson, n, gamma,
                  bounds, bin_widths, final_fxs, final_clrs;
                  numcores = 4, numthreads=256, num_ignore = 20)
    AT = Array
    if isa(input, Array)
        kernel! = naive_chaos_kernel!(CPU(), numcores)
    else
        AT = CuArray
        kernel! = naive_chaos_kernel!(CUDADevice(), numthreads)
    end
    kernel!(ps.positions, n, H.f_set, H.clr_set, H.prob_set,
            final_fxs, pxs.values, pxs.reds, pxs.greens, pxs.blues,
            gamma, AT(bounds), AT(bin_widths), num_ignore,
            ndrange=size(input)[1])
end

@kernel function naive_chaos_kernel!(points, n, H_fxs::NTuple, H_clrs, H_probs,
                                     final_fxs, final_clrs, pixel_values,
                                     pixel_reds, pixel_greens, pixel_blues,
                                     gamma, bounds, bin_widths, num_ignore)

    tid = @index(Global,Linear)
    lid = @index(Global,Linear)

    dims = size(points)[2]

    FT = eltype(pixel_reds)

    @uniform gs = @groupsize()[1]
    shared_tile = @localmem FT (gs,3)

    for i = 1:dims
        shared_tile[lid,i] = points[tid,i]
    end

    for i = 1:n
        fid = rand(1:length(H_fxs))
        shared_tile[lid] = H_fxs[fid](shared_tile[lid])
        if i > num_ignore
            bin = find_bin(pixel_values, points, tid, dims,
                           bounds, bin_widths)
            atomic_add!(pointer(pixel_values, bin), Int(1))
            for i = 1:3
                atomic_add!(pointer(pixel_reds, bin),
                            FT(H_clrs[fid,1]*H_clrs[fid,4]))
                atomic_add!(pointer(pixel_greenss, bin),
                            FT(H_clrs[fid,2]*H_clrs[fid,4]))
                atomic_add!(pointer(pixel_blues, bin),
                            FT(H_clrs[fid,3]*H_clrs[fid,4]))
            end
        end
        for j = 1:size(final_fxs)[1]
            shared_tile[lid] = final_fxs[j](shared_tile[lid])
            if i > num_ignore
                bin = find_bin(pixel_values, points, tid, dims,
                               bounds, bin_widths)
                atomic_add!(pointer(pixel_values, bin), Int(1))
                for i = 1:3
                    atomic_add!(pointer(pixel_reds, bin),
                                FT(final_clrs[i,1]*final_clrs[i,4]))
                    atomic_add!(pointer(pixel_greenss, bin),
                                FT(final_clrs[i,2]*final_clrs[i,4]))
                    atomic_add!(pointer(pixel_blues, bin),
                                FT(final_clrs[i,3]*final_clrs[i,4]))
                end
            end
        end
    end

    for i = 1:dims
        points[tid,i] = shared_tile[lid,i]
    end
end

#TODO: 1. Super sampling must be implemented by increasing the number of bins 
#         before sampling down. Gamma correction at that stage
#TODO: Parallelize with large number of initial points
#TODO: Allow Affine transforms to have a time variable and allow for 
#      supersampling across time with different timesteps all falling into the
#      same bin -- might require 2 buffers: one for log of each step, another
#      for all logs
#TODO: think about directional motion blur
# Example H:
# H = FFlamify.Hutchinson(
#   (FFlamify.swirl, FFlamify.heart, FFlamify.polar, FFlamify.horseshoe),
#   [RGB(0,1,0), RGB(0,0,1), RGB(1,0,1), RGB(1,0,0)],
#   [0.25, 0.25, 0.25, 0.25])
function fractal_flame(H::Hutchinson, num_particles::Int, num_iterations::Int,
                       bounds, res; dims=2, filename="check.png", AT = Array,
                       gamma = 2.2, A_set = [], final_fxs = (), num_ignore = 20,
                       numthreads = 256, numcores = 4)
    pts = Points(num_particles; dims = dims, AT = AT)

    pix = Pixels(res; AT = AT)

    wait(iterate!(pts, pix, H, num_iterations, gamma,
                  bounds, bin_widths, final_fxs, final_clrs;
                  numcores=numcores, numthreads=numthreads,
                  num_ignore=num_ignore))

    @time write_image(pix, filename; gamma = gamma)

end

function chaos_game(n::Int, bounds)
    points = [Point(0, 0) for i = 1:n]

    triangle_points = [Point(-1, -1), Point(1,-1), Point(0, sqrt(3)/2)]
    [points[1].x, points[1].y] .= -0.5.*(bounds) + rand(2).*bounds

    for i = 2:n
        points[i] = sierpinski(points[i-1], triangle_points)
    end

    return points
end
