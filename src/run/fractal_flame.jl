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
export run!

# couldn't figure out how to get an n-dim version working for GPU
@inline function on_image(p_y, p_x, bounds, dims)
    flag = true
    if p_y <= bounds.ymin || p_y > bounds.ymax ||
       p_y == NaN || p_y == Inf
        flag = false
    end

    if p_x <= bounds.xmin || p_x > bounds.xmax ||
       p_x == NaN || p_x == Inf
        flag = false
    end
    return flag
end

function iterate!(ps::Points, layer::FractalLayer, H::Hutchinson, n,
                  bounds, bin_widths, H2::Union{Nothing, Hutchinson};
                  frame = 0, diagnostic = false)
    if isnothing(H2) 
        fx = naive_chaos_kernel!
    elseif layer.params.solver_type == :semi_random
        fx = semi_random_chaos_kernel!
    elseif layer.params.solver_type == :random
        fx = naive_chaos_kernel!
    else
        @warn(string(layer.params.solver_type)*" is not a valid solver type!\n"*
              "Defaulting to random...")
        fx = naive_chaos_kernel!
    end

    max_range = maximum(values(bounds))*10
    if isa(ps.positions, Array)
        kernel! = fx(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = fx(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = fx(ROCDevice(), layer.params.numthreads)
    end

    if diagnostic
        @invokelatest kernel!(ps.positions, n, H.op, H.cop,
                              H.prob_set, H.symbols, H.fnums,
                              layer.values, layer.reds, layer.greens,
                              layer.blues, layer.alphas, frame, 
                              bounds, Tuple(bin_widths),
                              layer.params.num_ignore, max_range,
                              ndrange=size(ps.positions)[1])
    else
        @invokelatest kernel!(ps.positions, n, H.op, H.cop,
                              H.prob_set, H.symbols, H.fnums,
                              H2.op, H2.cop, H2.symbols, H2.prob_set, H2.fnums,
                              layer.values, layer.reds, layer.greens,
                              layer.blues, layer.alphas, frame, 
                              bounds, Tuple(bin_widths),
                              layer.params.num_ignore, max_range,
                              ndrange=size(ps.positions)[1])
    end
end

@kernel function naive_chaos_kernel!(points, n, H1, H1_clrs, H1_probs,
                                     H1_symbols, H1_fnums,
                                     layer_values, layer_reds, layer_greens,
                                     layer_blues, layer_alphas, frame, bounds,
                                     bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)
    lid = @index(Local, Linear)

    @uniform dims = size(points)[2]

    @uniform FT = eltype(layer_reds)

    @uniform gs = @groupsize()[1]
    shared_tile = @localmem FT (gs, 2)
    shared_colors = @localmem FT (gs, 4)

    seed = quick_seed(tid)
    fid = create_fid(H1_probs, H1_fnums, seed)

    offset = 1

    for i = 1:n
        for k = 1:4
            @inbounds shared_colors[lid,k] = 0
        end

        # quick way to tell if in range to be calculated or not
        sketchy_sum = 0
        for i = 1:dims
            @inbounds sketchy_sum += abs(shared_tile[lid,i])
        end

        if sketchy_sum < max_range
            if length(H1_fnums) > 1 || H1_fnums[1] > 1
                seed = simple_rand(seed)
                fid = create_fid(H1_probs, H1_fnums, seed)
            else
                fid = 1
            end

            H1(shared_tile, lid, H1_symbols, fid, frame)
            H1_clrs(shared_colors, shared_tile, lid, H1_symbols, fid, frame)

            @inbounds on_img_flag = on_image(shared_tile[lid,1],
                                             shared_tile[lid,2],
                                             bounds, dims)
            if i > num_ignore && on_img_flag

                @inbounds bin = find_bin(layer_values, shared_tile[lid,1],
                                         shared_tile[lid,2], bounds,
                                         bin_widths)
                if bin > 0 && bin <= length(layer_values)

                    @inbounds @atomic layer_values[bin] += 1
                    @inbounds @atomic layer_reds[bin] +=
                                  shared_colors[lid, 1] *
                                  shared_colors[lid, 4]
                    @inbounds @atomic layer_greens[bin] +=
                                  shared_colors[lid, 2] *
                                  shared_colors[lid, 4]
                    @inbounds @atomic layer_blues[bin] +=
                                  shared_colors[lid, 3] *
                                  shared_colors[lid, 4]
                    @inbounds @atomic layer_alphas[bin] += shared_colors[lid, 4]
                end
            end
        end
    end

    for i = 1:dims
        @inbounds points[tid,i] = shared_tile[lid,i]
    end

end

@kernel function semi_random_chaos_kernel!(points, n, H1, H1_clrs, H1_probs,
                                           H1_symbols, H1_fnums, H2, H2_clrs,
                                           H2_symbols, H2_probs, H2_fnums,
                                           layer_values, layer_reds,
                                           layer_greens, layer_blues,
                                           layer_alphas, frame, bounds,
                                           bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)
    lid = @index(Local, Linear)

    @uniform dims = size(points)[2]

    @uniform FT = eltype(layer_reds)

    @uniform gs = @groupsize()[1]
    shared_tile = @localmem FT (gs, 4)
    shared_colors = @localmem FT (gs, 4)

    seed = quick_seed(tid)
    fid = create_fid(H1_probs, H1_fnums, seed)

    offset = 1

    for i = 1:n
        for k = 1:4
            @inbounds shared_colors[lid,k] = 0
        end

        # quick way to tell if in range to be calculated or not
        sketchy_sum = 0
        for i = 1:dims
            @inbounds sketchy_sum += abs(shared_tile[lid,i])
        end

        if sketchy_sum < max_range
            if length(H1_fnums) > 1 || H1_fnums[1] > 1
                seed = simple_rand(seed)
                fid = create_fid(H1_probs, H1_fnums, seed)
            else
                fid = 1
            end

            H1(shared_tile, lid, H1_symbols, fid, frame)
            H1_clrs(shared_colors, shared_tile, lid, H1_symbols, fid, frame)

            for j = 1:length(H2_fnums)
                for fid_2 = 1:H2_fnums[j]

                    H2(shared_tile, lid, H2_symbols, fid_2, frame)
                    H2_clrs(shared_colors, shared_tile, lid,
                            H2_symbols, fid_2, frame)

                    @inbounds on_img_flag = on_image(shared_tile[lid,3],
                                                     shared_tile[lid,4],
                                                     bounds, dims)
                    if i > num_ignore && on_img_flag

                        @inbounds bin = find_bin(layer_values,
                                                 shared_tile[lid,3],
                                                 shared_tile[lid,4], bounds,
                                                 bin_widths)
                        if bin > 0 && bin <= length(layer_values)
    
                            @inbounds @atomic layer_values[bin] += 1
                            @inbounds @atomic layer_reds[bin] +=
                                          shared_colors[lid, 1] *
                                          shared_colors[lid, 4]
                            @inbounds @atomic layer_greens[bin] +=
                                          shared_colors[lid, 2] *
                                          shared_colors[lid, 4]
                            @inbounds @atomic layer_blues[bin] +=
                                          shared_colors[lid, 3] *
                                          shared_colors[lid, 4]
                            @inbounds @atomic layer_alphas[bin] +=
                                          shared_colors[lid, 4]
                        end
                    end
                end
            end
        end
    end

    for i = 1:dims
        @inbounds points[tid,i] = shared_tile[lid,i]
    end
end

@kernel function naive_chaos_kernel!(points, n, H1, H1_clrs, H1_probs,
                                     H1_symbols, H1_fnums, H2, H2_clrs,
                                     H2_symbols, H2_probs, H2_fnums,
                                     layer_values, layer_reds, layer_greens,
                                     layer_blues, layer_alphas, frame, bounds,
                                     bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)
    lid = @index(Local, Linear)

    @uniform dims = size(points)[2]

    @uniform FT = eltype(layer_reds)

    @uniform gs = @groupsize()[1]
    shared_tile = @localmem FT (gs, 4)
    shared_colors = @localmem FT (gs, 4)

    seed = quick_seed(tid)
    fid = create_fid(H1_probs, H1_fnums, seed)
    fid_2 = create_fid(H2_probs, H2_fnums, seed)

    offset = 1

    for i = 1:n
        for k = 1:4
            @inbounds shared_colors[lid,k] = 0
        end

        # quick way to tell if in range to be calculated or not
        sketchy_sum = 0
        for i = 1:dims
            @inbounds sketchy_sum += abs(shared_tile[lid,i])
        end

        if sketchy_sum < max_range
            if length(H1_fnums) > 1 || H1_fnums[1] > 1
                seed = simple_rand(seed)
                fid = create_fid(H1_probs, H1_fnums, seed)
            else
                fid = 1
            end

            H1(shared_tile, lid, H1_symbols, fid, frame)
            H1_clrs(shared_colors, shared_tile, lid, H1_symbols, fid, frame)

            if H2 != Fae.null
                if length(H2_fnums) > 1 || H2_fnums[1] > 1
                    seed = simple_rand(seed)
                    fid_2 = create_fid(H2_probs, H2_fnums, seed)
                else
                    fid_2 = 1
                end
            end

            H2(shared_tile, lid, H2_symbols, fid_2, frame)
            H2_clrs(shared_colors, shared_tile, lid, H2_symbols, fid_2, frame)

            @inbounds on_img_flag = on_image(shared_tile[lid,3],
                                             shared_tile[lid,4],
                                             bounds, dims)
            if i > num_ignore && on_img_flag

                @inbounds bin = find_bin(layer_values, shared_tile[lid,3],
                                         shared_tile[lid,4], bounds,
                                         bin_widths)
                if bin > 0 && bin <= length(layer_values)

                    @inbounds @atomic layer_values[bin] += 1
                    @inbounds @atomic layer_reds[bin] +=
                                  shared_colors[lid, 1] *
                                  shared_colors[lid, 4]
                    @inbounds @atomic layer_greens[bin] +=
                                  shared_colors[lid, 2] *
                                  shared_colors[lid, 4]
                    @inbounds @atomic layer_blues[bin] +=
                                  shared_colors[lid, 3] *
                                  shared_colors[lid, 4]
                    @inbounds @atomic layer_alphas[bin] += shared_colors[lid, 4]
                end
            end
        end
    end

    for i = 1:dims
        @inbounds points[tid,i] = shared_tile[lid,i]
    end

end


function run!(layer::FractalLayer; diagnostic = false, frame = 0)

    res = size(layer.canvas)
    bounds = find_bounds(layer)
    pts = Points(layer.params.num_particles; FloatType = eltype(layer.reds),
                 dims = layer.params.dims,
                 ArrayType = layer.params.ArrayType, bounds = bounds)

    bin_widths = zeros(div(length(values(bounds)),2))
    for i = 1:length(bin_widths)
        bin_widths[i] = (bounds[i*2]-bounds[i*2-1])/res[i]
    end

    bounds = find_bounds(layer)

    wait(iterate!(pts, layer, layer.H1, layer.params.num_iterations,
                  bounds, bin_widths, layer.H2; diagnostic = diagnostic,
                  frame = frame))

    return layer

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
