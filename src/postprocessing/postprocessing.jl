@kernel function zero_kernel!(pix_values, pix_reds, pix_greens, pix_blues)
    tid = @index(Global, Cartesian)
    pix_values[tid] = 0
    pix_reds[tid] = 0
    pix_greens[tid] = 0
    pix_blues[tid] = 0
end

function zero!(pix; numthreads = 256, numcores = 4)
    
    if isa(pix.reds, Array)
        kernel! = zero_kernel!(CPU(), numcores)
    else
        kernel! = zero_kernel!(CUDADevice(), numthreads)
    end

    kernel!(pix.values, pix.reds, pix.greens, pix.blues,
            ndrange = size(pix.values))

end

function find_point!(tile, bin_widths, tid, bounds, lid)

    tile[lid,2] = bounds[2] + (tid[2]+0.5)*bin_widths[2]
    tile[lid,1] = bounds[1] + (tid[1]+0.5)*bin_widths[1]
    
end

function postprocess!(H::Hutchinson, pix::Pixels, bounds;
                      numcores = 4, numthreads=256)
    pix_out = Pixels(CuArray(zeros(Int, size(pix.values))),
                     CuArray(zeros(size(pix.reds))), 
                     CuArray(zeros(size(pix.greens))), 
                     CuArray(zeros(size(pix.blues))))

    wait(postprocess!(H, pix, pix_out, bounds,
                      numcores = numcores, numthreads = numthreads))

    pix.values[:] .= pix_out.values[:]
    pix.reds[:] .= pix_out.reds[:]
    pix.greens[:] .= pix_out.greens[:]
    pix.blues[:] .= pix_out.blues[:]
end

function postprocess!(H::Hutchinson, pix_in::Pixels, pix_out::Pixels, bounds;
                     numcores = 4, numthreads=256)

    if size(H.color_set)[1] !== 1
        println("unable to perform postprocessing step, " *
                "more than one function found!")
        return
    end

    wait(zero!(pix_out; numthreads = numthreads, numcores = numcores))

    res = size(pix_in.values)
    bin_widths = zeros(size(bounds)[1])
    for i = 1:length(bin_widths)
        bin_widths[i] = (bounds[i,2]-bounds[i,1])/res[i]
    end

    if isa(pix_in.reds, Array)
        kernel! = postprocess_kernel!(CPU(), numcores)
    else
        kernel! = postprocess_kernel!(CUDADevice(), numthreads)
    end

    kernel!(H.op, H.color_set, H.prob_set, H.symbols,
            pix_in.values, pix_in.reds, pix_in.greens, pix_in.blues,
            pix_out.values, pix_out.reds, pix_out.greens, pix_out.blues,
            Tuple(bounds), Tuple(bin_widths), ndrange=size(pix_in.values))
end

@kernel function postprocess_kernel!(H, H_clrs, H_probs, symbols,
                                     pin_values, pin_reds, pin_greens,
                                     pin_blues, pout_values, pout_reds,
                                     pout_greens, pout_blues,
                                     bounds, bin_widths)

    tid = @index(Global,Cartesian)
    lid = @index(Local,Linear)

    @uniform FT = eltype(pout_reds)

    @uniform gs = @groupsize()[1]
    shared_tile = @localmem FT (gs,2)
    find_point!(shared_tile, bin_widths, tid, bounds, lid)

    @inbounds H(shared_tile, lid, symbols, 1)

    on_img_flag = on_image(shared_tile[lid,1], shared_tile[lid,2],
                           bounds, 2)
    if on_img_flag
        bin = find_bin(pout_values, shared_tile, lid, 2,
                       bounds, bin_widths)
        if bin > 0 && bin < length(pout_values)
            atomic_add!(pointer(pout_values, bin), pin_values[tid])
            atomic_add!(pointer(pout_reds, bin), pin_reds[tid])
            atomic_add!(pointer(pout_greens, bin), pin_greens[tid])
            atomic_add!(pointer(pout_blues, bin), pin_blues[tid])

            if !isapprox(H_clrs[4], 0)
                atomic_add!(pointer(pout_values, bin), Int(1))
                atomic_add!(pointer(pout_reds, bin),
                            FT(H_clrs[1]*H_clrs[4]))
                atomic_add!(pointer(pout_greens, bin),
                            FT(H_clrs[2]*H_clrs[4]))
                atomic_add!(pointer(pout_blues, bin),
                            FT(H_clrs[3]*H_clrs[4]))
            end
        end
    end
end
