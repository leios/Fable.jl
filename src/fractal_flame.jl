# couldn't figure out how to get an n-dim version working for GPU
@inline function on_image(p_y, p_x, bounds, dims)
    flag = true
    if p_y < bounds[1] || p_y > bounds[3] ||
       p_y == NaN || p_y == Inf
        flag = false
    end

    if p_x < bounds[2] || p_x > bounds[4] ||
       p_x == NaN || p_x == Inf
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

function iterate!(ps::Points, pxs::Pixels, H::Hutchinson, n,
                  bounds, bin_widths, H2_fx, H2_clrs, H2_symbols, H2_probs;
                  diagnostic = false, numcores = 4, numthreads=256,
                  num_ignore = 20)

    max_range = maximum(bounds)*10
    if isa(ps.positions, Array)
        kernel! = naive_chaos_kernel!(CPU(), numcores)
    else
        kernel! = naive_chaos_kernel!(CUDADevice(), numthreads)
    end

    if diagnostic
        println(H.symbols)
    end

    kernel!(ps.positions, n, H.op, H.color_set, H.prob_set, H.symbols,
            H2_fx, H2_clrs, H2_symbols, H2_probs,
            pxs.values, pxs.reds, pxs.greens, pxs.blues,
            Tuple(bounds), Tuple(bin_widths), num_ignore, max_range,
            ndrange=size(ps.positions)[1])
end

@kernel function naive_chaos_kernel!(points, n, H, H_clrs, H_probs, symbols,
                                     H2_fx, H2_clrs, H2_symbols, H2_probs,
                                     pixel_values, pixel_reds, pixel_greens,
                                     pixel_blues, bounds, bin_widths,
                                     num_ignore, max_range)

    tid = @index(Global,Linear)
    lid = @index(Local,Linear)

    @uniform dims = size(points)[2]
    @uniform fnum = size(H_clrs)[1]
    @uniform fnum_2 = 1
    if !isa(H2_clrs, Union{Tuple, NTuple})
        fnum_2 = size(H2_clrs)[1]
    end

    @uniform FT = eltype(pixel_reds)

    @uniform gs = @groupsize()[1]
    shared_tile = @localmem FT (gs,4)

    for i = 1:dims
        @inbounds shared_tile[lid,i] = points[tid,i]
    end

    seed = quick_seed(tid)

    for i = 1:n
        sketchy_sum = 0
        for i = 1:dims
            @inbounds sketchy_sum += abs(shared_tile[lid,i])
        end
        if sketchy_sum < max_range
            seed = simple_rand(seed)
            fid = find_fid(H_probs, fnum, seed)

            @inbounds H(shared_tile, lid, symbols, fid)

            fid_2 = fnum_2

            if H2_fx != Fae.null
                if fid_2 > 1
                    seed = simple_rand(seed)
                    fid_2 = find_fid(H2_probs, fnum_2, seed)
                end
            end

            H2_fx(shared_tile, lid, H2_symbols, fid_2)

            on_img_flag = on_image(shared_tile[lid,3], shared_tile[lid,4],
                                   bounds, dims)
            if i > num_ignore && on_img_flag
                bin = find_bin(pixel_values, shared_tile[lid,3],
                               shared_tile[lid,4], bounds, bin_widths)
                if bin > 0 && bin < length(pixel_values)
                    atomic_add!(pointer(pixel_values, bin), Int(1))
                    atomic_add!(pointer(pixel_reds, bin),
                                FT(H_clrs[fid,1]*H_clrs[fid,4]))
                    atomic_add!(pointer(pixel_greens, bin),
                                FT(H_clrs[fid,2]*H_clrs[fid,4]))
                    atomic_add!(pointer(pixel_blues, bin),
                                FT(H_clrs[fid,3]*H_clrs[fid,4]))
                    if H2_fx != Fae.null && H2_clrs[fid_2+3*fnum_2] > 0
                        atomic_add!(pointer(pixel_values, bin), Int(1))
                        atomic_add!(pointer(pixel_reds, bin),
                            FT(H2_clrs[fid_2]*H2_clrs[fid_2+3*fnum_2]))
                        atomic_add!(pointer(pixel_greens, bin),
                            FT(H2_clrs[fid_2+1*fnum_2]*H2_clrs[fid_2+3*fnum_2]))
                        atomic_add!(pointer(pixel_blues, bin),
                            FT(H2_clrs[fid_2+2*fnum_2]*H2_clrs[fid_2+3*fnum_2]))
                    end
                end
            end
        end
    end

    for i = 1:dims
        @inbounds points[tid,i] = shared_tile[lid,i]
    end
end

function fractal_flame(H_1::Hutchinson, H2::Hutchinson, num_particles::Int,
                       num_iterations::Int, bounds, res;
                       dims = 2, AT = Array, FT = Float32, diagnostic = false,
                       A_set = [], num_ignore = 20, numthreads = 256,
                       numcores = 4)

    pix = Pixels(res; AT = AT, FT = FT)

    fractal_flame!(pix, H_1, num_particles, num_iterations, bounds, res;
                   dims = dims, AT = AT, FT = FT, A_set = A_set, 
                   H2_fx = H2.op, H2_clrs = H2.color_set, 
                   H2_symbols = H2.symbols, H2_probs = H2.prob_set,
                   num_ignore = num_ignore, diagnostic = diagnostic,
                   numthreads = numthreads, numcores = numcores)
end

function fractal_flame!(pix::Pixels, H_1::Hutchinson, H2::Hutchinson,
                        num_particles::Int, num_iterations::Int, bounds, res;
                        dims = 2, AT = Array, FT = Float32, diagnostic = false, 
                        A_set = [], num_ignore = 20, numthreads = 256,
                        numcores = 4)

    fractal_flame!(pix, H_1, num_particles, num_iterations, bounds, res;
                   dims = dims, AT = AT, FT = FT, A_set = A_set, 
                   H2_fx = H2.op, H2_clrs = H2.color_set, 
                   H2_symbols = H2.symbols, H2_probs = H2.prob_set,
                   num_ignore = num_ignore, diagnostic = diagnostic,
                   numthreads = numthreads, numcores = numcores)

end

function fractal_flame(H::Hutchinson, num_particles::Int,
                       num_iterations::Int, bounds, res;
                       dims = 2, AT = Array, FT = Float32, A_set = [],
                       H2_fx = Fae.null, H2_clrs=(0,0,0,0), H2_symbols = (()),
                       H2_probs = ((1,)), num_ignore = 20, diagnostic = false,
                       numthreads = 256, numcores = 4)

    pix = Pixels(res; AT = AT, FT = FT)

    fractal_flame!(pix, H, num_particles, num_iterations, bounds, res;
                   dims = dims, AT = AT, FT = FT, A_set = A_set,
                   H2_fx = H2_fx, H2_clrs = H2_clrs,
                   H2_symbols = H2_symbols, H2_probs = H2_probs, 
                   num_ignore = num_ignore, diagnostic = diagnostic,
                   numthreads = numthreads, numcores = numcores)
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
function fractal_flame!(pix::Pixels, H::Hutchinson, num_particles::Int,
                        num_iterations::Int, bounds, res;
                        dims = 2, AT = Array, FT = Float32, A_set = [],
                        H2_fx = Fae.null, H2_clrs=(0,0,0,0), H2_symbols = (()),
                        H2_probs = ((1,)), num_ignore = 20, diagnostic = false,
                        numthreads = 256, numcores = 4)


    pts = Points(num_particles; FT = FT, dims = dims, AT = AT, bounds = bounds)

    bin_widths = zeros(size(bounds)[1])
    for i = 1:length(bin_widths)
        bin_widths[i] = (bounds[i,2]-bounds[i,1])/res[i]
    end

    println("kernel time:")
    CUDA.@time wait(iterate!(pts, pix, H, num_iterations,
                             bounds, bin_widths, H2_fx, H2_clrs,
                             H2_symbols, H2_probs;
                             numcores=numcores, numthreads=numthreads,
                             num_ignore=num_ignore, diagnostic = diagnostic))

    return pix

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
