export run!

@generated function hutchinson_loop(fxs, fid, thing, frame, fnums, kwargs)
    exs = Expr[]
    offset = 0
    for i = 1:length(fnums.parameters)
        ex = quote
            idx = decode_fid(fid, offset, fnums[$i])
            thing = fxs[idx](thing, frame; kwargs[idx]...)
            bit_offset += ceil(UInt,log2(fnums[$i]))
        end
        push!(exs, ex)
    end

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end

@generated function semi_random_loop!(layer_values, canvas, fxs, clr_fxs, 
                                      pt, clr, frame, fnums, kwargs, clr_kwargs,
                                      bounds, dims, bin_widths)
    exs = Expr[]
    offset = 0
    for i = 1:length(fnums.parameters)
        ex = quote
            idx = decode_fid(fid, offset, fnums[$i])
            pt = fxs[idx](pt, frame; kwargs[idx]...)
            clr = clr_fxs[idx](clr, frame; clr_kwargs[idx]...)
            bit_offset += ceil(UInt,log2(fnums[$i]))
            histogram_output!(layer_values, canvas, pt, clr,
                              bounds, dims, bin_widths)
        end
        push!(exs, ex)
    end

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end

@inline function histogram_output!(layer_values, canvas, pt, clr,
                                   bounds, dims, bin_widths)
    on_img_flag = on_image(pt.y,pt.x, bounds, dims)
    if i > num_ignore && on_img_flag
        @inbounds bin = find_bin(layer_values, pt.y, pt.x, bounds, bin_widths)
        if bin > 0 && bin <= length(layer_values)
            @inbounds @atomic layer_values[bin] += 1
            @inbounds @atomic canvas[bin] = 0.5*canvas[bin] + 0.5*clr
        end
    end
end


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

function iterate!(layer::FractalLayer, H::Hutchinson, n,
                  bounds, bin_widths, H2::Union{Nothing, Hutchinson};
                  frame = 0)
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

    if isnothing(H2)
        kernel!(layer.particles, n, H1.fxs, combine(H1.kwargs, H1.fis),
                H1.color_fxs, combine(H1.color_kwargs, H1.color_fis),
                H1.prob_set, H1.fnums, layer.values, layer.canvas,
                frame, bounds, Tuple(bin_widths),
                layer.params.num_ignore, max_range,
                ndrange=size(ps.positions)[1])
    else
        kernel!(layer.particles, n, H1.fxs, combine(H1.kwargs, H1.fis),
                H1.color_fxs, combine(H1.color_kwargs, H1.color_fis),
                H1.prob_set, H1.fnums,
                H2.fxs, combine(H2.kwargs, H2.fis),
                H2.color_fxs, combine(H2.color_kwargs, H2.color_fis),
                H2.prob_set, H2.fnums,
                layer.values, layer.canvas,
                frame, bounds, Tuple(bin_widths),
                layer.params.num_ignore, max_range,
                ndrange=size(ps.positions)[1])
        kernel!(layer.particles, n,
                              H.op, H.cop, H.prob_set, H.symbols, H.fnums,
                              H2.op, H2.cop, H2.symbols, H2.prob_set, H2.fnums,
                              layer.values, layer.canvas, frame, 
                              bounds, Tuple(bin_widths),
                              layer.params.num_ignore, max_range,
                              ndrange=size(ps.positions)[1])
    end
end

@kernel function naive_chaos_kernel!(points, n, H_fxs, H_kwargs,
                                     H_clrs, H_clr_kwargs,
                                     H_probs, H_fnums,
                                     layer_values, canvas, frame, bounds,
                                     bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)

 
    pt = points[tid]
    @uniform dims = dims(pt)
    clr = RGBA{Float32}(0,0,0,0)

    seed = quick_seed(tid)
    fid = create_fid(H_probs, H_fnums, seed)

    for i = 1:n
        # quick way to tell if in range to be calculated or not
        sketchy_sum = absum(pt)
        
        if sketchy_sum < max_range
            if length(H_fnums) > 1 || H_fnums[1] > 1
                seed = simple_rand(seed)
                fid = create_fid(H_probs, H_fnums, seed)
            else
                fid = 1
            end

            pt = hutchinson_loop(H_fxs, fid, pt, frame, fnums, H_kwargs)
            clr = hutchinson_loop(H_clrs, fid, clr, frame, fnums, H_clr_kwargs)

            histogram_output!(layer_values, canvas, pt, clr,
                              bounds, dims, bin_widths)
        end
    end

    @inbounds points[tid] = pt

end

@kernel function semi_random_chaos_kernel!(points, n, H1_fxs, H1_kwargs,
                                           H1_clrs, H1_clr_kwargs,
                                           H1_probs, H1_fnums,
                                           H2_fxs, H2_kwargs,
                                           H2_clrs, H2_clr_kwargs,
                                           H2_probs, H2_fnums,
                                           layer_values, canvas, frame, bounds,
                                           bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)

    pt = points[tid]
    clr = RGBA{Float32}(0,0,0,0)
    @uniform dims = dims(pt)

    seed = quick_seed(tid)
    fid = create_fid(H1_probs, H1_fnums, seed)

    for i = 1:n
        # quick way to tell if in range to be calculated or not
        sketchy_sum = absum(pt)

        if sketchy_sum < max_range
            if length(H1_fnums) > 1 || H1_fnums[1] > 1
                seed = simple_rand(seed)
                fid = create_fid(H1_probs, H1_fnums, seed)
            else
                fid = 1
            end

            pt = hutchinson_loop(H1_fxs, fid, pt, frame, fnums, H1_kwargs)
            clr = hutchinson_loop(H1_clrs, fid, clr,
                                  frame, fnums, H1_clr_kwargs)

            semi_random_loop!(layer_values, canvas, H2.fxs, H2.clr_fxs, 
                              pt, clr, frame, fnums, H2.kwargs, H2.clr_kwargs,
                              bounds, dims, bin_widths)

        end
    end

    for i = 1:dims
        @inbounds points[tid] = pt
    end
end

@kernel function naive_chaos_kernel!(points, n, H1_fxs, H1_kwargs,
                                     H1_clrs, H1_clr_kwargs,
                                     H1_probs, H1_fnums,
                                     H2_fxs, H2_kwargs,
                                     H2_clrs, H2_clr_kwargs,
                                     H2_probs, H2_fnums,
                                     layer_values, canvas, frame, bounds,
                                     bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)

    pt = points[tid]
    output_pt = points[tid]
    @uniform dims = dims(pt)

    clr = RGBA{Float32}(0,0,0,0)
    output_clr = RGBA{Float32}(0,0,0,0)

    seed = quick_seed(tid)
    fid = create_fid(H1_probs, H1_fnums, seed)

    for i = 1:n
        # quick way to tell if in range to be calculated or not
        sketchy_sum = absum(pt)

        if sketchy_sum < max_range
            if length(H1_fnums) > 1 || H1_fnums[1] > 1
                seed = simple_rand(seed)
                fid = create_fid(H1_probs, H1_fnums, seed)
            else
                fid = 1
            end

            pt = hutchinson_loop(H1_fxs, fid, pt, frame, fnums, H1_kwargs)
            clr = hutchinson_loop(H1_clrs, fid, clr,
                                  frame, fnums, H1_clr_kwargs)

            output_pt = hutchinson_loop(H2_fxs, fid, pt,
                                        frame, fnums, H2_kwargs)
            output_clr = hutchinson_loop(H2_clrs, fid, clr,
                                         frame, fnums, H2_clr_kwargs)

            histogram_output!(layer_values, canvas, output_pt, output_clr,
                              bounds, dims, bin_widths)

        end
    end

    for i = 1:dims
        @inbounds points[tid] = pt
    end

end


function run!(layer::FractalLayer; frame = 0)

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
                  bounds, bin_widths, layer.H2; frame = frame))

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
