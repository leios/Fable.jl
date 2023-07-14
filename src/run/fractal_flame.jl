#-------------fractal_flame.jl-------------------------------------------------#
# Before reading this file and judging me, please take a look at the errors on
# PR #64 (https://github.com/leios/Fable.jl/pull/64)
# 
# Long story short, I cannot access any Tuples of varying types with iteration:
#     i = 5
#     fxs[i](args...;kwargs...)
# This means that anything that cannot be represented as an NTuple{Type,...},
# will break. Functions have an inherent type, so they cannot be represented as
# an NTuple and must instead be represented as a Tuple{f1, f2, f3...}.
# 
# To call the functions, I need to call them with a statically known number.
# So instead of using `idx = 1`, `fxs[idx](...)`, I needed to create an
# `@generated` function that unrolls the loop for me. In the case of colors,
# where multiple colors could be used on for the same IFS function, I needed
# an additional helper function to call the Tuple one by one.
#
# It will unfortunately only get more complicated from here until Julia is fixed
#------------------------------------------------------------------------------#
export run!

@generated function call_pt_fx(fxs, pt, frame, kwargs, idx)
    exs = Expr[]
    ex = quote
        if idx == 1
            pt = fxs[1](pt.y, pt.x, frame; kwargs[1]...) 
        end
    end
    push!(exs, ex)
    for i = 2:length(fxs.parameters)
        ex = quote
            if idx == $i
                pt = fxs[$i](pt.y, pt.x, frame; kwargs[$i]...) 
            end
        end
        push!(exs, ex)
    end
    push!(exs, :(return pt))

    return Expr(:block, exs...)
end

# These functions essentially unroll the loops in the kernel because of a
# known julia bug preventing us from using for i = 1:10...
@generated function pt_loop(fxs, fid, pt, frame, fnums, kwargs;
                             bit_offset = 0, fx_offset = 0)
    exs = Expr[]
    push!(exs, :(bit_offset = bit_offset))
    push!(exs, :(fx_offset = fx_offset))
    for i = 1:length(fnums.parameters)
        ex = quote
            idx = decode_fid(fid, bit_offset, fnums[$i]) + fx_offset
            pt = call_pt_fx(fxs, pt, frame, kwargs, idx)
            bit_offset += ceil(UInt,log2(fnums[$i]))
            fx_offset += fnums[$i]
        end
        push!(exs, ex)
    end

    push!(exs, :(return pt))

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end

@generated function call_clr_fx(fxs, pt, clr, frame, kwargs, idx)
    exs = Expr[]
    ex = quote
        if idx == 1
            clr = call_clr_fx(fxs[1], pt, clr, frame, kwargs[1]) 
        end
    end
    push!(exs, ex)
    for i = 2:length(fxs.parameters)
        ex = quote
            if idx == $i
                clr = call_clr_fx(fxs[$i], pt, clr, frame, kwargs[$i])
            end
        end
        push!(exs, ex)
    end
    push!(exs, :(return clr))

    return Expr(:block, exs...)
end

@inline function call_clr_fx(fx, pt, clr, frame, kwargs)
    return fx(pt.y, pt.x, clr, frame; kwargs...)
end

@generated function call_clr_fx(fx::Tuple, pt::Point2D, clr,
                                frame, kwargs::Tuple)
    exs = Expr[]
    for i = 1:length(fx.parameters)
        ex = :(clr = fx[$i](pt.y, pt.x, clr, frame; kwargs[$i]...))
        push!(exs, ex)
    end

    push!(exs, :(return clr))

    return Expr(:block, exs...)
end

@generated function clr_loop(fxs, fid, pt, clr, frame, fnums, kwargs;
                             bit_offset = 0, fx_offset = 0)
    exs = Expr[]
    push!(exs, :(bit_offset = bit_offset))
    push!(exs, :(fx_offset = fx_offset))
    for i = 1:length(fnums.parameters)
        ex = quote
            idx = decode_fid(fid, bit_offset, fnums[$i]) + fx_offset
            clr = call_clr_fx(fxs, pt, clr, frame, kwargs, idx)
            bit_offset += ceil(UInt,log2(fnums[$i]))
            fx_offset += fnums[$i]
        end
        push!(exs, ex)
    end

    push!(exs, :(return clr))

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end

@generated function semi_random_loop!(layer_values, layer_reds, layer_greens,
                                      layer_blues, layer_alphas, fxs, clr_fxs, 
                                      pt, clr, frame, fnums, kwargs, clr_kwargs,
                                      probs, bounds, dims, bin_widths,
                                      iteration, num_ignore; fx_offset = 0)
    exs = Expr[]
    push!(exs, :(temp_prob = 0.0))
    push!(exs, :(fx_max_range = fx_offset + sum(fnums)))
    for i = 1:length(fxs.parameters)
        ex = quote
            if fx_offset + 1 <= $i <= fx_max_range
                pt = fxs[$i](pt.y, pt.x, frame; kwargs[$i]...)
                clr = clr_fxs[$i](pt.y, pt.x, clr, frame; clr_kwargs[$i]...)
                temp_prob += probs[$i]
                if isapprox(temp_prob, 1.0) || temp_prob >= 1.0
                    histogram_output!(layer_values, layer_reds, layer_greens,
                                      layer_blues, layer_alphas,
                                      pt, clr, bounds,
                                      dims, bin_widths, iteration, num_ignore)
                    temp_prob = 0.0
                end
            end
        end
        push!(exs, ex)
    end

    push!(exs)

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end

@inline function histogram_output!(layer_values, layer_reds, layer_greens,
                                   layer_blues, layer_alphas, pt, clr,
                                   bounds, dims, bin_widths, i, num_ignore)
    on_img_flag = on_image(pt.y,pt.x, bounds, dims)
    if i > num_ignore && on_img_flag
        @inbounds bin = find_bin(layer_values, pt.y, pt.x, bounds, bin_widths)
        if bin > 0 && bin <= length(layer_values)
            @inbounds @atomic layer_values[bin] += 1
            @inbounds @atomic layer_reds[bin] += clr.r
            @inbounds @atomic layer_greens[bin] += clr.g
            @inbounds @atomic layer_blues[bin] += clr.b
            @inbounds @atomic layer_alphas[bin] += clr.alpha
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
                  bounds, bin_widths, H_post::Union{Nothing, Hutchinson};
                  frame = 0)
    if isnothing(H_post) 
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
    backend = get_backend(layer.canvas)
    kernel! = fx(backend, layer.params.numthreads)

    if isnothing(H_post)
        kernel!(layer.particles, n, H.fxs, combine(H.kwargs, H.fis),
                H.color_fxs, combine(H.color_kwargs, H.color_fis),
                H.prob_set, H.fnums, layer.values,
                layer.reds, layer.greens, layer.blues, layer.alphas,
                frame, bounds, Tuple(bin_widths),
                layer.params.num_ignore, max_range,
                ndrange=size(layer.particles)[1])
    else
        kernel!(layer.particles, n, H.fxs, combine(H.kwargs, H.fis),
                H.color_fxs, combine(H.color_kwargs, H.color_fis),
                H.prob_set, H.fnums,
                H_post.fxs, combine(H_post.kwargs, H_post.fis),
                H_post.color_fxs, combine(H_post.color_kwargs,
                                          H_post.color_fis),
                H_post.prob_set, H_post.fnums,
                layer.values, layer.reds, layer.greens, layer.blues,
                layer.alphas, frame, bounds, Tuple(bin_widths),
                layer.params.num_ignore, max_range,
                ndrange=size(layer.particles)[1])
    end
end

@kernel function naive_chaos_kernel!(points, n, H_fxs, H_kwargs,
                                     H_clrs, H_clr_kwargs,
                                     H_probs, H_fnums,
                                     layer_values, layer_reds, layer_greens,
                                     layer_blues, layer_alphas, frame, bounds,
                                     bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)

    dims = Fable.dims(points[tid])

    seed = quick_seed(tid)

    clr = RGBA{Float32}(0,0,0,0)
    bit_offset = UInt(0)
    fx_offset = 0
    for j = 1:size(points,2)
        pt = points[tid, j]
        total_fxs = sum(H_fnums[j])
        for i = 1:n
            # quick way to tell if in range to be calculated or not
            sketchy_sum = absum(pt)
    
            if sketchy_sum < max_range
                if length(H_fnums[j]) > 1 || H_fnums[j][1] > 1
                    seed = simple_rand(seed)
                    fid = create_fid(H_probs, H_fnums[j], seed, fx_offset + 1)
                else
                    fid = UInt(1)
                end

                #println(fx_offset, '\t', H_fnums[j], '\t', fid)
                pt = pt_loop(H_fxs, fid, pt, frame, H_fnums[j],
                             H_kwargs; bit_offset, fx_offset)
                clr = clr_loop(H_clrs, fid, pt, clr, frame,
                               H_fnums[j], H_clr_kwargs;
                               bit_offset, fx_offset)

                histogram_output!(layer_values, layer_reds, layer_greens,
                                  layer_blues, layer_alphas, pt, clr,
                                  bounds, dims, bin_widths, i, num_ignore)
            end
        end
        #bit_offset += ceil(UInt,log2(total_fxs))
        fx_offset += total_fxs
        @inbounds points[tid, j] = pt
    end

end

@kernel function semi_random_chaos_kernel!(points, n, H_fxs, H_kwargs,
                                           H_clrs, H_clr_kwargs,
                                           H_probs, H_fnums,
                                           H_post_fxs, H_post_kwargs,
                                           H_post_clrs, H_post_clr_kwargs,
                                           H_post_probs, H_post_fnums,
                                           layer_values, layer_reds,
                                           layer_greens, layer_blues,
                                           layer_alphas, frame, bounds,
                                           bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)

    dims = Fable.dims(points[tid])

    seed = quick_seed(tid)

    bit_offset = UInt(0)
    fx_offset = 0
    post_fx_offset = 0
    for j = 1:size(points, 2)
        pt = points[tid, j]
        clr = RGBA{Float32}(0,0,0,0)
        for i = 1:n
            # quick way to tell if in range to be calculated or not
            sketchy_sum = absum(pt)

            if sketchy_sum < max_range
                if length(H_fnums[j]) > 1 || H_fnums[j][1] > 1
                    seed = simple_rand(seed)
                    fid = create_fid(H_probs, H_fnums[j], seed, fx_offset + 1)
                else
                    fid = UInt(1)
                end

                pt = pt_loop(H_fxs, fid, pt, frame, H_fnums[j], H_kwargs;
                             bit_offset, fx_offset)
                clr = clr_loop(H_clrs, fid, pt, clr,
                               frame, H_fnums[j], H_clr_kwargs;
                               bit_offset, fx_offset)

                semi_random_loop!(layer_values, layer_reds, layer_greens,
                                  layer_blues, layer_alphas,
                                  H_post_fxs, H_post_clrs,
                                  pt, clr, frame, H_post_fnums[j],
                                  H_post_kwargs, H_post_clr_kwargs,
                                  H_post_probs, bounds, dims, bin_widths,
                                  i, num_ignore; fx_offset = post_fx_offset)

            end
        end
        total_fxs = sum(H_fnums[j])
        bit_offset += ceil(UInt,log2(total_fxs))
        fx_offset += total_fxs
        post_fx_offset += sum(H_post_fnums[j])
        @inbounds points[tid, j] = pt
    end

end

@kernel function naive_chaos_kernel!(points, n, H_fxs, H_kwargs,
                                     H_clrs, H_clr_kwargs,
                                     H_probs, H_fnums,
                                     H_post_fxs, H_post_kwargs,
                                     H_post_clrs, H_post_clr_kwargs,
                                     H_post_probs, H_post_fnums,
                                     layer_values, layer_reds, layer_greens,
                                     layer_blues, layer_alphas, frame, bounds,
                                     bin_widths, num_ignore, max_range)

    tid = @index(Global,Linear)

    output_pt = points[tid]
    dims = Fable.dims(points[tid])

    output_clr = RGBA{Float32}(0,0,0,0)

    seed = quick_seed(tid)

    bit_offset = UInt(0)
    fx_offset = 0

    post_bit_offset = UInt(0)
    post_fx_offset = 0
    for j = 1:size(points, 2)
        pt = points[tid, j]
        clr = RGBA{Float32}(0,0,0,0)
        for i = 1:n
            # quick way to tell if in range to be calculated or not
            sketchy_sum = absum(pt)

            if sketchy_sum < max_range
                if length(H_fnums[j]) > 1 || H_fnums[j][1] > 1
                    seed = simple_rand(seed)
                    fid = create_fid(H_probs, H_fnums[j], seed, fx_offset + 1)
                else
                    fid = UInt(1)
                end

                if length(H_post_fnums[j]) > 1 || H_post_fnums[j][1] > 1
                    seed = simple_rand(seed)
                    fid_2 = create_fid(H_post_probs, H_post_fnums[j], seed,
                                       post_fx_offset + 1)
                else
                    fid_2 = UInt(1)
                end

                pt = pt_loop(H_fxs, fid, pt, frame, H_fnums[j], H_kwargs;
                             fx_offset, bit_offset)
                clr = clr_loop(H_clrs, fid, pt, clr,
                               frame, H_fnums[j], H_clr_kwargs;
                               fx_offset, bit_offset)

                output_pt = pt_loop(H_post_fxs, fid, pt, frame,
                                    H_post_fnums[j], H_post_kwargs;
                                    bit_offset = post_bit_offset,
                                    fx_offset = post_fx_offset)
                output_clr = clr_loop(H_post_clrs, fid_2, pt, clr,
                                      frame, H_post_fnums[j],
                                      H_post_clr_kwargs;
                                      bit_offset = post_bit_offset,
                                      fx_offset = post_fx_offset)

                histogram_output!(layer_values, layer_reds, layer_greens,
                                  layer_blues, layer_alphas, output_pt,
                                  output_clr, bounds, dims, bin_widths,
                                  i, num_ignore)

            end
        end
        total_fxs = sum(H_fnums[j])
        bit_offset += ceil(UInt,log2(total_fxs))
        fx_offset += total_fxs

        post_total_fxs = sum(H_post_fnums[j])
        post_bit_offset += ceil(UInt,log2(post_total_fxs))
        post_fx_offset += post_total_fxs
        @inbounds points[tid, j] = pt
    end


end


function run!(layer::FractalLayer; frame = 0)

    res = size(layer.canvas)
    bounds = find_bounds(layer)

    bin_widths = zeros(div(length(values(bounds)),2))
    for i = 1:length(bin_widths)
        bin_widths[i] = (bounds[i*2]-bounds[i*2-1])/res[i]
    end

    bounds = find_bounds(layer)

    iterate!(layer, layer.H, layer.params.num_iterations,
             bounds, bin_widths, layer.H_post; frame = frame)

    return layer

end
