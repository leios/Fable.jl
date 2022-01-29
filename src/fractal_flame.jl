# couldn't figure out how to get an n-dim version working for GPU
@inline function on_image(p_x, p_y, bounds, dims)
    flag = true
    if p_x < bounds[1,1] || p_x > bounds[1,2] ||
       p_x == NaN || p_x == Inf
        flag = false
    end

    if p_y < bounds[2,1] || p_y > bounds[2,2] ||
       p_y == NaN || p_y == Inf
        flag = false
    end
    return flag
end

@inline function find_fid(prob_set, fnum, seed)
    rnd = seed/typemax(UInt)
    p = 0.0

    for i = 1:fnum
        p += prob_set[i]
        if rnd <= p
            return i
        end
    end

    return 0

end

function iterate!(ps::Points, pxs::Pixels, H::Hutchinson, n, gamma,
                  bounds, bin_widths, final_fx, final_clr;
                  numcores = 4, numthreads=256, num_ignore = 20)
    AT = Array
    max_range = maximum(bounds)*10
    if isa(ps.positions, Array)
        kernel! = naive_chaos_kernel!(CPU(), numcores)
    else
        AT = CuArray
        kernel! = naive_chaos_kernel!(CUDADevice(), numthreads)
    end
    kernel!(ps.positions, n, H.op, H.color_set, H.prob_set,
            final_fx, final_clr, pxs.values, pxs.reds, pxs.greens, pxs.blues,
            gamma, AT(bounds), AT(bin_widths), num_ignore, max_range,
            ndrange=size(ps.positions)[1])
end

@kernel function naive_chaos_kernel!(points, n, H, H_clrs, H_probs,
                                     final_fx, final_clr, pixel_values,
                                     pixel_reds, pixel_greens, pixel_blues,
                                     gamma, bounds, bin_widths, num_ignore,
                                     max_range)

    tid = @index(Global,Linear)
    lid = @index(Local,Linear)

    @uniform dims = size(points)[2]
    @uniform fnum = size(H_clrs)[1]

    @uniform FT = eltype(pixel_reds)

    @uniform gs = @groupsize()[1]
    shared_tile = @localmem FT (gs,3)

    for i = 1:dims
        @inbounds shared_tile[lid,i] = points[tid,i]
    end

    seed = quick_seed(tid)

    for i = 1:n
        seed = simple_rand(seed)
        fid = find_fid(H_probs, fnum, seed)

        sketchy_sum = 0
        for i = 1:dims
            @inbounds sketchy_sum += abs(shared_tile[lid,i])
        end
        if sketchy_sum < max_range
            @inbounds H(shared_tile, lid, fid)

            if final_fx != Fae.null
                final_fx(shared_tile, lid)
            end

            on_img_flag = on_image(shared_tile[lid,1], shared_tile[lid,2],
                                   bounds, dims)
            if i > num_ignore && on_img_flag
                bin = find_bin(pixel_values, shared_tile, lid, dims,
                               bounds, bin_widths)
                if bin > 0 && bin < length(pixel_values)
                    atomic_add!(pointer(pixel_values, bin), Int(1))
                    atomic_add!(pointer(pixel_reds, bin),
                                FT(H_clrs[fid,1]*H_clrs[fid,4]))
                    atomic_add!(pointer(pixel_greens, bin),
                                FT(H_clrs[fid,2]*H_clrs[fid,4]))
                    atomic_add!(pointer(pixel_blues, bin),
                                FT(H_clrs[fid,3]*H_clrs[fid,4]))
                    if final_fx != Fae.null
                        atomic_add!(pointer(pixel_values, bin), Int(1))
                        atomic_add!(pointer(pixel_reds, bin),
                                    FT(final_clr[1]*final_clr[4]))
                        atomic_add!(pointer(pixel_greens, bin),
                                    FT(final_clr[2]*final_clr[4]))
                        atomic_add!(pointer(pixel_blues, bin),
                                    FT(final_clr[3]*final_clr[4]))
                    end
                end
            end
        end
    end

    for i = 1:dims
        @inbounds points[tid,i] = shared_tile[lid,i]
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
# H = Fae.Hutchinson(
#   (Fae.swirl, Fae.heart, Fae.polar, Fae.horseshoe),
#   [RGB(0,1,0), RGB(0,0,1), RGB(1,0,1), RGB(1,0,0)],
#   [0.25, 0.25, 0.25, 0.25])
function fractal_flame(H::Hutchinson, num_particles::Int, num_iterations::Int,
                       bounds, res; dims=2, filename="check.png", AT = Array,
                       FT = Float64, gamma = 2.2, A_set = [], 
                       final_fx = Fae.null, final_clr=(0,0,0,0),
                       num_ignore = 20, numthreads = 256, numcores = 4)

    #println(typeof(final_fxs))
    pts = Points(num_particles; FT = FT, dims = dims, AT = AT, bounds = bounds)

    pix = Pixels(res; AT = AT, FT = FT)

    bin_widths = zeros(size(bounds)[1])
    for i = 1:length(bin_widths)
        bin_widths[i] = (bounds[i,2]-bounds[i,1])/res[i]
    end

    println(bin_widths)
    println(maximum(pts.positions), '\t', minimum(pts.positions))

    wait(iterate!(pts, pix, H, num_iterations, gamma,
                  bounds, bin_widths, final_fx, final_clr;
                  numcores=numcores, numthreads=numthreads,
                  num_ignore=num_ignore))

    println(sum(pix.values))

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
