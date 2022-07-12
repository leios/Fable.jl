export write_image, write_video!

function to_rgb(r,g,b)
    return RGB(r,g,b)
end

function to_rgb(r,g,b,a)
    return RGBA(r,g,b,a)
end

function to_rgb(pix::Pixels)
    if typeof(pix.reds) != Array
        pix = to_cpu(pix)
    end
    a = [RGBA(pix.reds[i], pix.greens[i], pix.blues[i], pix.alphas[i])
         for i = 1:length(pix)]
    return a
end

function to_cpu(pix::Pixels)
    return Pixels(Array(pix.values), Array(pix.reds), Array(pix.greens),
                  Array(pix.blues), Array(pix.alphas), pix.gamma,
                  pix.logscale, pix.calc_max_value, pix.max_value)
end

function to_cpu!(cpu_pix, pix)
    cpu_pix.reds = Array(pix.reds)
    cpu_pix.greens = Array(pix.greens)
    cpu_pix.blues = Array(pix.blues)
    cpu_pix.alphas = Array(pix.alphas)
end

function to_rgb!(canvas, pix)
    if !isa(pix.reds, Array)
        pix = to_cpu(pix)
    end
    canvas .= to_rgb.(pix.reds, pix.greens, pix.blues, pix.alphas)
end

function coalesce!(pix, layer)
    pix.reds .= (1 .- layer.alphas) .* pix.reds .+ layer.alphas .* layer.reds
    pix.greens .= (1 .- layer.alphas) .* pix.greens .+ layer.alphas .* layer.greens
    pix.blues .= (1 .- layer.alphas) .* pix.blues .+ layer.alphas .* layer.blues
    pix.alphas .= max.(pix.alphas, layer.alphas)
end

function logscale_coalesce!(pix, layer; numcores = 4, numthreads = 256)
    if isa(pix.reds, Array)
        kernel! = logscale_coalesce_kernel!(CPU(), numcores)
    else
        kernel! = logscale_coalesce_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(pix.reds, ROCArray)
        kernel! = logscale_coalesce_kernel!(AMDGPU.default_device(), numthreads)
    end

    kernel!(pix.reds, pix.greens, pix.blues, pix.alphas, pix.values,
            layer.reds, layer.greens, layer.blues, layer.alphas, layer.values,
            layer.gamma, layer.max_value, ndrange=length(pix.reds))

end

@kernel function logscale_coalesce_kernel!(
    pix_reds, pix_greens, pix_blues, pix_alphas,
    pix_values, layer_reds, layer_greens,
    layer_blues, layer_alphas, layer_values,
    layer_gamma, layer_max_value)

    tid = @index(Global, Linear)

    alpha = log10((9*layer_values[tid]/layer_max_value)+1)

    new_red = layer_reds[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
    new_green = layer_greens[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
    new_blue = layer_blues[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)
    new_alpha = layer_alphas[tid]^(1/layer_gamma) * alpha^(1/layer_gamma)

    pix_reds[tid] = pix_reds[tid]*(1-alpha^(1/layer_gamma)) + new_red
    pix_greens[tid] = pix_greens[tid]*(1-alpha^(1/layer_gamma)) + new_green
    pix_blues[tid] = pix_blues[tid]*(1-alpha^(1/layer_gamma)) + new_blue
    pix_alphas[tid] = pix_alphas[tid]*(1-alpha^(1/layer_gamma)) + new_alpha
    
end

function norm_pixel(color, value)
    if value == 0 || isnan(value)
        return color
    else
        return color / value
    end
end

function add_layer!(pix::Pixels, layer::Pixels; numcores = 4, numthreads = 256)

    # naive normalization
    layer.reds .= norm_pixel.(layer.reds, layer.values)
    layer.greens .= norm_pixel.(layer.greens, layer.values)
    layer.blues .= norm_pixel.(layer.blues, layer.values)
    layer.alphas .= norm_pixel.(layer.alphas, layer.values)

    if pix.logscale
        # This means the max_value is manually set
        if pix.calc_max_value != 0
            pix.max_value = maximum(pix.values)
        end
        logscale_coalesce!(pix, layer,
                           numcores = numcores, numthreads = numthreads)
    else
        coalesce!(pix, layer)
    end

end

function write_image(pixels::Vector{Pixels}, filename;
                     img = fill(RGB(0,0,0), size(pixels[1].values)),
                     numcores = 4, numthreads = 256)

    for i = 1:length(pixels)
        add_layer!(pixels[1], pixels[i])
    end

    to_rgb!(img, pixels[1])

    save(filename, img)
    println(filename)
end

function write_video!(v::VideoParams, pixels::Vector{Pixels};
                      numcores = 4, numthreads = 256)
    for i = 1:length(pixels)
        add_layer!(pixels[1], pixels[i])
    end

    to_rgb!(v.frame, pixels[1])
    write(v.writer, v.frame)
    zero!(v.frame)
    println(v.frame_count)
    v.frame_count += 1
end

