function find_point!(tile, tid, res, bounds, lid)
    
end

function postprocess!(H::Hutchinson, pix::Pixels, bounds;
                      numcores = 4, numthreads=256)
    pix_out = deep_copy(pix)

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

    res = size(pix.values)
    bin_widths = zeros(size(bounds)[1])
    for i = 1:length(bin_widths)
        bin_widths[i] = (bounds[i,2]-bounds[i,1])/res[i]
    end

    AT = Array
    if isa(ps.positions, Array)
        kernel! = postprocess_kernel!(CPU(), numcores)
    else
        AT = CuArray
        kernel! = postprocess_kernel!(CUDADevice(), numthreads)
    end

    kernel!(H.op, H.color_set, H.prob_set, H.symbols,
            pxs_in.values, pxs_in.reds, pxs_in.greens, pxs_in.blues,
            pxs_out.values, pxs_out.reds, pxs_out.greens, pxs_out.blues,
            AT(bounds), AT(bin_widths), ndrange=size(pix.values))
end

@kernel function postprocess_kernel!(H, H_clrs, H_probs, symbols,
                                     pin_values, pin_reds, pin_greens,
                                     pin_blues, pout_values, pout_reds,
                                     pout_greens, pout_blues,
                                     bounds, bin_widths)

    tid = @index(Global,Cartesian)
    lid = @index(Local,Linear)

    @uniform FT = eltype(pixel_reds)

    @uniform gs = @groupsize()[1]
    shared_tile = @localmem FT (gs,2)
    find_point!(shared_tile, tid, size(pin_values), bounds, lid)

    @inbounds H(shared_tile, lid, symbols, 1)

    on_img_flag = on_image(shared_tile[lid,1], shared_tile[lid,2],
                           bounds, dims)
    if on_img_flag
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
        end
    end
end
