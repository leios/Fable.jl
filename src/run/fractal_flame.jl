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
    push!(exs, :(@inline))
    push!(exs, Expr(:inbounds, true))
    for i = 1:length(fxs.parameters)
        ex = quote
            if idx == $i
                pt = fxs[$i](pt.y, pt.x, frame; kwargs[$i]...) 
            end
        end
        push!(exs, ex)
    end
    push!(exs, Expr(:inbounds, :pop))
    push!(exs, :(return pt))

    return Expr(:block, exs...)
end

# These functions essentially unroll the loops in the kernel because of a
# known julia bug preventing us from using for i = 1:10...
@inline @generated function pt_loop(fxs, fid, pt, frame, fnums, kwargs;
                             bit_offset = UInt(0), fx_offset = 0)
    exs = Expr[]
    push!(exs, :(@inline))
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

@inline @generated function call_clr_fx(fxs, pt, clr, frame, kwargs, idx)
    exs = Expr[]
    push!(exs, :(@inline))
    for i = 1:length(fxs.parameters)
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

@inline @generated function call_clr_fx(fx::Tuple, pt::Point2D, clr,
                                frame, kwargs::Tuple)
    exs = Expr[]
    push!(exs, :(@inline))
    for i = 1:length(fx.parameters)
        ex = :(clr = fx[$i](pt.y, pt.x, clr, frame; kwargs[$i]...))
        push!(exs, ex)
    end

    push!(exs, :(return clr))

    return Expr(:block, exs...)
end

@inline @generated function clr_loop(fxs, fid, pt, clr, frame, fnums, kwargs;
                             bit_offset = UInt(0), fx_offset = 0)
    exs = Expr[]
    push!(exs, :(@inline))
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

@inline @generated function semi_random_loop!(layer_values, layer_reds, layer_greens,
                                      layer_blues, layer_alphas, priorities,
                                      fid, fxs, clr_fxs, pt, clr,
                                      frame, fnums, kwargs, clr_kwargs,
                                      probs, bounds, dims, bin_widths,
                                      iteration, num_ignore, overlay;
                                      fx_offset = 0)
    exs = Expr[]
    push!(exs, :(@inline))
    push!(exs, :(temp_prob = 0.0))
    push!(exs, :(fx_max_range = fx_offset + sum(fnums)))
    push!(exs, :(curr_pt = pt))
    push!(exs, :(curr_clr = clr))
    for i = 1:length(fxs.parameters)
        ex = quote
            if fx_offset + 1 <= $i <= fx_max_range
                curr_pt = fxs[$i](curr_pt.y, curr_pt.x, frame; kwargs[$i]...)
                curr_clr = clr_fxs[$i](curr_pt.y, curr_pt.x, curr_clr, frame;
                                       clr_kwargs[$i]...)
                temp_prob += probs[$i]
                if isapprox(temp_prob, 1.0) || temp_prob >= 1.0
                    output!(layer_values, layer_reds, layer_greens,
                            layer_blues, layer_alphas, priorities, fid+UInt($i),
                            curr_pt, curr_clr, overlay, bounds,
                            dims, bin_widths, iteration, num_ignore)
                    curr_pt = pt
                    curr_clr = clr
                    temp_prob = 0.0
                end
            end
        end
        push!(exs, ex)
    end

    # to return 3 separate colors to mix separately
    # return :(Expr(:tuple, $exs...))

    return Expr(:block, exs...)
end

@inline function output!(layer_values, layer_reds, layer_greens,
                         layer_blues, layer_alphas, priorities, fid,
                         pt, clr, overlay, bounds, dims,
                         bin_widths, i, num_ignore)
    if overlay
        histogram_output!(layer_values, layer_reds, layer_greens,
                          layer_blues, layer_alphas, priorities, fid,
                          pt, clr, bounds, dims, bin_widths, i, num_ignore)
    else
        atomic_histogram_output!(layer_values, layer_reds,
                                 layer_greens, layer_blues,
                                 layer_alphas, pt, clr, bounds, dims,
                                 bin_widths, i, num_ignore)

    end
end

@inbounds @inline function histogram_output!(layer_values,
                                             layer_reds, layer_greens,
                                             layer_blues, layer_alphas,
                                             priorities::AT, fid,
                                             pt, clr, bounds, dims,
                                             bin_widths, i,
                                             num_ignore) where AT<:AbstractArray
    on_img_flag = on_image(pt.y,pt.x, bounds, dims)
    if i > num_ignore && on_img_flag
        bin = find_bin(layer_values, pt.y, pt.x, bounds, bin_widths)
        if bin > 0 && bin <= length(layer_values) && priorities[bin] < fid
        #if bin > 0 && bin <= length(layer_values)
            layer_values[bin] = 1
            layer_reds[bin] = clr.r
            layer_greens[bin] = clr.g
            layer_blues[bin] = clr.b
            layer_alphas[bin] = clr.alpha
            priorities[bin] = fid
        end
    end
end

# this is a stupid hack so that things compile on the GPU. Otherwise, the GPU
# will try to compile the above function with priorities as nothing, which
# cannot access the [bin] index
@inbounds @inline function histogram_output!(layer_values, layer_reds,
     layer_greens, layer_blues, layer_alphas, priorities::AT, fid, pt, clr,
     bounds, dims, bin_widths, i, num_ignore) where AT<:Nothing
end

@inbounds @inline function atomic_histogram_output!(layer_values, layer_reds,
                                                    layer_greens, layer_blues,
                                                    layer_alphas, pt,
                                                    clr, bounds, dims,
                                                    bin_widths, i, num_ignore)
    on_img_flag = on_image(pt.y,pt.x, bounds, dims)
    if i > num_ignore && on_img_flag
        bin = find_bin(layer_values, pt.y, pt.x, bounds, bin_widths)
        if bin > 0 && bin <= length(layer_values)
            @atomic layer_values[bin] += 1
            @atomic layer_reds[bin] += clr.r
            @atomic layer_greens[bin] += clr.g
            @atomic layer_blues[bin] += clr.b
            @atomic layer_alphas[bin] += clr.alpha
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
                layer.priorities, frame, bounds, Tuple(bin_widths),
                layer.params.num_ignore, max_range, layer.params.overlay,
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
                layer.alphas, layer.priorities,
                frame, bounds, Tuple(bin_widths),
                layer.params.num_ignore, max_range, layer.params.overlay,
                ndrange=size(layer.particles)[1])
    end
end

@kernel function naive_chaos_kernel!(points, n, H_fxs, H_kwargs,
                                     H_clrs, H_clr_kwargs,
                                     H_probs, H_fnums,
                                     layer_values, layer_reds, layer_greens,
                                     layer_blues, layer_alphas, priorities,
                                     frame, bounds, bin_widths,
                                     num_ignore, max_range, overlay)

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

                pt = pt_loop(H_fxs, fid, pt, frame, H_fnums[j],
                             H_kwargs; fx_offset)
                clr = clr_loop(H_clrs, fid, recenter(pt, bounds, bin_widths),
                               clr, frame, H_fnums[j], H_clr_kwargs; fx_offset)

                fid = (fid+1) << bit_offset+1

                output!(layer_values, layer_reds, layer_greens,
                        layer_blues, layer_alphas, priorities, fid,
                        pt, clr, overlay,
                        bounds, dims, bin_widths, i, num_ignore)
            end
        end

        fx_offset += total_fxs
        bit_offset += ceil(UInt,log2(total_fxs))+1
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
                                           layer_alphas, priorities,
                                           frame, bounds, bin_widths,
                                           num_ignore, max_range, overlay)

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
                             fx_offset)
                clr = clr_loop(H_clrs, fid, recenter(pt, bounds, bin_widths),
                               clr, frame, H_fnums[j], H_clr_kwargs; fx_offset)

                fid = (fid+1) << bit_offset

                semi_random_loop!(layer_values, layer_reds, layer_greens,
                                  layer_blues, layer_alphas, priorities, fid, 
                                  H_post_fxs, H_post_clrs,
                                  pt, clr, frame, H_post_fnums[j],
                                  H_post_kwargs, H_post_clr_kwargs,
                                  H_post_probs, bounds, dims, bin_widths,
                                  i, num_ignore, overlay;
                                  fx_offset = post_fx_offset)

            end
        end
        total_fxs = sum(H_fnums[j])
        fx_offset += total_fxs
        bit_offset += ceil(UInt, log2(total_fxs)) +
                      ceil(UInt, log2(sum(H_post_fnums[j])))
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
                                     layer_blues, layer_alphas, priorities,
                                     frame, bounds, bin_widths, num_ignore,
                                     max_range, overlay)

    tid = @index(Global,Linear)

    output_pt = points[tid]
    dims = Fable.dims(points[tid])

    output_clr = RGBA{Float32}(0,0,0,0)

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

                if length(H_post_fnums[j]) > 1 || H_post_fnums[j][1] > 1
                    seed = simple_rand(seed)
                    fid_2 = create_fid(H_post_probs, H_post_fnums[j], seed,
                                       post_fx_offset + 1)
                else
                    fid_2 = UInt(1)
                end

                pt = pt_loop(H_fxs, fid, pt, frame, H_fnums[j], H_kwargs;
                             fx_offset)
                clr = clr_loop(H_clrs, fid, recenter(pt, bounds, bin_widths),
                               clr, frame, H_fnums[j], H_clr_kwargs; fx_offset)

                output_pt = pt_loop(H_post_fxs, fid, pt, frame,
                                    H_post_fnums[j], H_post_kwargs;
                                    fx_offset = post_fx_offset)
                output_clr = clr_loop(H_post_clrs, fid_2,
                                      recenter(pt, bounds, bin_widths), clr,
                                      frame, H_post_fnums[j],
                                      H_post_clr_kwargs;
                                      fx_offset = post_fx_offset)

                # a bit sketchy
                fid = (fid+1) << bit_offset

                output!(layer_values, layer_reds, layer_greens,
                        layer_blues, layer_alphas, priorities, fid, output_pt,
                        output_clr, overlay, bounds, dims, bin_widths,
                        i, num_ignore)

            end
        end
        total_fxs = sum(H_fnums[j])
        fx_offset += total_fxs
        bit_offset += ceil(UInt, log2(total_fxs)) +
                      ceil(UInt, log2(sum(H_post_fnums[j])))

        post_total_fxs = sum(H_post_fnums[j])
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
