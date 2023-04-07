export run!

# These functions essentially unroll the loops in the kernel because of a
# known julia bug preventing us from using for i = 1:10...
@generated function pt_loop(fxs, fid, pt, frame, fnums, kwargs)
    exs = Expr[]
    push!(exs, :(bit_offset = 0))
    for i = 1:length(fnums.parameters)
        ex = quote
            idx = decode_fid(fid, bit_offset, fnums[$i])
            pt = fxs[idx](pt.y, pt.x, frame; kwargs[idx]...)
            #pt = fxs[idx](pt.y, pt.x, frame)
            bit_offset += ceil(UInt,log2(fnums[$i]))
        end
        push!(exs, ex)
    end

    push!(exs, :(return pt))

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end

@generated function clr_loop(fxs, fid, pt, clr, frame, fnums, kwargs)
    exs = Expr[]
    push!(exs, :(bit_offset = 0))
    for i = 1:length(fnums.parameters)
        ex = quote
            idx = decode_fid(fid, bit_offset, fnums[$i])
            clr = fxs[idx](pt.y, pt.x, clr, frame; kwargs[idx]...)
            bit_offset += ceil(UInt,log2(fnums[$i]))
        end
        push!(exs, ex)
    end

    push!(exs, :(return clr))

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end


@generated function semi_random_loop!(layer_values, canvas, fxs, clr_fxs, 
                                      pt, clr, frame, fnums, kwargs, clr_kwargs,
                                      bounds, dims, bin_widths,
                                      iteration, num_iignore)
    exs = Expr[]
    push!(exs, :(bit_offset = 0))
    for i = 1:length(fnums.parameters)
        ex = quote
            idx = decode_fid(fid, bit_offset, fnums[$i])
            pt = fxs[idx](pt.y, pt.x, frame; kwargs[idx]...)
            clr = clr_fxs[idx](pt.y, pt.x, clr, frame; clr_kwargs[idx]...)
            bit_offset += ceil(UInt,log2(fnums[$i]))
            histogram_output!(layer_values, canvas, pt, clr,
                              bounds, dims, bin_widths, iteration, num_ignore)
        end
        push!(exs, ex)
    end

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end

@inline function histogram_output!(layer_values, canvas, pt, clr,
                                   bounds, dims, bin_widths, i, num_ignore)
    on_img_flag = on_image(pt.y,pt.x, bounds, dims)
    if i > num_ignore && on_img_flag
        @inbounds bin = find_bin(layer_values, pt.y, pt.x, bounds, bin_widths)
        if bin > 0 && bin <= length(layer_values)
            @inbounds @atomic layer_values[bin] += 1
            #@inbounds @atomic canvas[bin] = 0.5*canvas[bin] + 0.5*clr
            #@inbounds Atomix.@atomic canvas[bin] += RGBA{Float32}(0,0,0,0)
            canvas[bin] = 0.5*canvas[bin] + 0.5*clr
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

function iterate!(layer::FractalLayer, H1::Hutchinson, n,
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
    if layer.params.ArrayType <: Array
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
                ndrange=size(layer.particles)[1])
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
                ndrange=size(layer.particles)[1])
    end
end

@kernel function naive_chaos_kernel!(points, n, H_fxs, H_kwargs,
                                     H_clrs, H_clr_kwargs,
                                     H_probs, H_fnums,
                                     layer_values, canvas, frame, bounds,
                                     bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)

 
    pt = points[tid]
    dims = Fae.dims(pt)
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
                fid = UInt(1)
            end

            pt = pt_loop(H_fxs, fid, pt, frame, H_fnums, H_kwargs)
            clr = clr_loop(H_clrs, fid, pt, clr, frame, H_fnums, H_clr_kwargs)

            histogram_output!(layer_values, canvas, pt, clr,
                              bounds, dims, bin_widths, i, num_ignore)
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
    dims = Fae.dims(pt)

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
                fid = UInt(1)
            end

            pt = pt_loop(H1_fxs, fid, pt, frame, H1_fnums, H1_kwargs)
            clr = clr_loop(H1_clrs, fid, pt, clr,
                           frame, H1_fnums, H1_clr_kwargs)

            semi_random_loop!(layer_values, canvas, H2_fxs, H2_clrs, 
                              pt, clr, frame, H2_fnums, H2_kwargs,
                              H2_clr_kwargs, bounds, dims, bin_widths, i,
                              num_ignore )

        end
    end

    @inbounds points[tid] = pt
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
    dims = Fae.dims(pt)

    clr = RGBA{Float32}(0,0,0,0)
    output_clr = RGBA{Float32}(0,0,0,0)

    seed = quick_seed(tid)
    fid = create_fid(H1_probs, H1_fnums, seed)
    fid_2 = create_fid(H2_probs, H2_fnums, seed)

    for i = 1:n
        # quick way to tell if in range to be calculated or not
        sketchy_sum = absum(pt)

        if sketchy_sum < max_range
            if length(H1_fnums) > 1 || H1_fnums[1] > 1
                seed = simple_rand(seed)
                fid = create_fid(H1_probs, H1_fnums, seed)
            else
                fid = UInt(1)
            end

            if length(H2_fnums) > 1 || H2_fnums[1] > 1
                seed = simple_rand(seed)
                fid_2 = create_fid(H2_probs, H2_fnums, seed)
            else
                fid_2 = UInt(1)
            end

            pt = pt_loop(H1_fxs, fid, pt, frame, H1_fnums, H1_kwargs)
            clr = clr_loop(H1_clrs, fid, pt, clr,
                           frame, H1_fnums, H1_clr_kwargs)

            #output_pt = pt_loop(H2_fxs, fid, pt, frame, H2_fnums, H2_kwargs)
            #output_clr = clr_loop(H2_clrs, fid_2, pt, clr,
            #                      frame, H2_fnums, H2_clr_kwargs)

            output_pt = pt
            output_clr = clr
            histogram_output!(layer_values, canvas, output_pt, output_clr,
                              bounds, dims, bin_widths, i, num_ignore)

        end
    end

    @inbounds points[tid] = pt

end


function run!(layer::FractalLayer; frame = 0)

    res = size(layer.canvas)
    bounds = find_bounds(layer)

    bin_widths = zeros(div(length(values(bounds)),2))
    for i = 1:length(bin_widths)
        bin_widths[i] = (bounds[i*2]-bounds[i*2-1])/res[i]
    end

    bounds = find_bounds(layer)

    wait(iterate!(layer, layer.H1, layer.params.num_iterations,
                  bounds, bin_widths, layer.H2; frame = frame))

    return layer

end
