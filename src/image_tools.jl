# TODO: Probably shouldn't print anything anymore...
using LinearAlgebra

#TODO: figure out how to select the best deviation factor
function create_gaussian_kernel(kernel_size; deviation_factor = 1)
    if !isodd(kernel_size)
        println("Even kernel sizes are not allowed. New kernel size is: ",
                kernel_size-1)
        kernel_size -= 1
    end

    kernel = zeros(kernel_size, kernel_size)
    center = floor(Int, kernel_size / 2) + 1

    for i = 1:kernel_size
        for j = 1:kernel_size
            kernel[i,j] = exp(-((i-center)^2 + (j-center)^2)/
                              (kernel_size/deviation_factor))
        end
    end

    return normalize(kernel)
    
end

#TODO: maybe normalize channels altogether, not separate?
function normalize!(img::Array{C,2}) where {C <: Union{RGB, RGBA}}

    # finding the max of each color channel
    max_red = 0
    max_green = 0
    max_blue = 0

    for i = 1:length(img)
        if img[i].r > max_red
            max_red = img[i].r
        end

        if img[i].g > max_green
            max_green = img[i].g
        end

        if img[i].b > max_blue
            max_blue = img[i].b
        end
    end

    for i = 1:length(img)
        color = RGB(img[i].r / max_red,
                    img[i].g / max_green,
                    img[i].b / max_blue)
        img[i] = color
    end
    
end

function bounds_check(signal, index, filter_width, dir)
    if index < 1
        filter_width - (1-index)
    elseif index > size(signal)[dir]
        return filter_width - (index - size(signal)[dir])
    else
        return filter_width
    end
end

function pixel_sum(signal::Array{Pixel,2})
    rsum = 0
    for i = 1:length(signal)
        rsum += signal[i].val
    end

    return rsum
end

# TODO: the normalization of the colors seems off, creating a spotty output
function filter_color(filter, signal)
    if (size(signal) != size(filter))
        error("filter and image views are not consistent!")
    end

    rsum = RGB(0)
    for i = 1:length(signal)
        rsum += filter[i]*signal[i].c
    end

    return rsum / sum(filter)
    
end

# TODO: this is computationally complex. Kinda sucks for that reason.
function find_filter_width(signal, threshold, index::CartesianIndex;
                           max_width = 15)

    num_points = signal[index].val

    filter_width = 1

    while (num_points < threshold) && (filter_width < max_width)
        filter_width += 2

        num_points = pixel_sum(signal, filter_width, index)

    end

    return filter_width
end


# TODO: too many pixel sum functions
function pixel_sum(signal::Array{Pixel,2}, filter_width::Int,
                   index::CartesianIndex)

    center = filter_width + 1

    j,i = index[1], index[2]

    # This can create a signal view that is not the size of the filter
    left_bound = bounds_check(signal, i-filter_width, filter_width, 2)
    right_bound = bounds_check(signal, i+filter_width, filter_width, 2)
    top_bound = bounds_check(signal, j+filter_width, filter_width, 1)
    bottom_bound = bounds_check(signal, j-filter_width, filter_width, 1)

    # TODO: zero-pad view or slize filter
    #println(filter[1])
    rsum = pixel_sum(signal[j-bottom_bound:j+top_bound,
                            i-left_bound:i+right_bound])

    return rsum

end


function pixel_sum(signal::Array{Pixel,2}, filter::Array{Float64,2},
                   index::CartesianIndex)

    filter_width = floor(Int, size(filter)[1]/2)
    center = filter_width + 1

    j,i = index[1], index[2]

    # This can create a signal view that is not the size of the filter
    left_bound = bounds_check(signal, i-filter_width, filter_width, 2)
    right_bound = bounds_check(signal, i+filter_width, filter_width, 2)
    top_bound = bounds_check(signal, j+filter_width, filter_width, 1)
    bottom_bound = bounds_check(signal, j-filter_width, filter_width, 1)

    # TODO: zero-pad view or slize filter
    #println(filter[1])
    rsum = Pixel(signal[i,j].val,
                 filter_color(filter[center-bottom_bound:center+top_bound,
                                     center-left_bound:center+right_bound],
                              signal[j-bottom_bound:j+top_bound,
                                     i-left_bound:i+right_bound]))

    return rsum

end

#TODO: figure out what how to make a variable sized filter
#      We need to read in the point data to figure out filter size
#TODO: I believe this is actually a correlation, not convolution ^^
function fractal_conv(signal::Array{Pixel,2}; threshold = 1)

    n = size(signal)
    out = Array{Pixel,2}(undef,n)

    # time domain
    for j = 1:n[1]
        for i = 1:n[2]
            filter_width = find_filter_width(signal, threshold,
                                             CartesianIndex(j,i))
            filter = create_gaussian_kernel(filter_width)
            rsum = pixel_sum(signal, filter, CartesianIndex(j,i))
            out[j, i] = rsum
            rsum = RGB(0)
        end
    end

    return out
end

function mix_color(a::RGB, b::RGB)
    return RGB(0.5*(a.r+b.r), 0.5*(a.g+b.g), 0.5*(a.b + b.b))
end

function mix_color!(pix::Pixel, p::Point)
    pix.c = (pix.c*pix.val + p.c)/(pix.val + 1)
    pix.val += 1
end

function to_rgb(pix::Pixel)
    return pix.c
end


function to_logscale(pix::Pixel, max_val; gamma = 2.2)
    alpha = 1

    # TODO: check to see if this is an appropriate log implementation
    # TODO: What's meant by "vibrant colors?"
    if pix.val != 0
        alpha = log10((9*pix.val/max_val)+1)
        #alpha = 1 + log10(pix.val/max_val)
    end
    final_color = RGB(pix.c.r*alpha, pix.c.g*alpha, pix.c.b*alpha)

    # Applying Gamma
    # TODO: We should be able to broadcast a power operation to clean this up
    final_color = RGB(final_color.r^(1/gamma),
                      final_color.g^(1/gamma),
                      final_color.b^(1/gamma))

    return Pixel(pix.val, final_color)
end

function write_image(points::Vector{Point}, ranges, res, filename;
                     point_offset = 10, gamma = 2.2)

    # reversing resolution and ranges because Julia expects y-axis first
    res = reverse(res)
    ranges = reverse(ranges)
    pixels = [Pixel(0) for i=1:res[1], j=1:res[2]]

    max_val = 0

    # bin the pixels
    println("time for binning:")
    @time for i = point_offset:length(points)

        # Notes: - Points are in (x, y), while visualization is in (y, x)
        #        - y value needs to be flipped because drawing should be from
        #          lower left
        yval = floor(Int, (ranges[1]*0.5-points[i].y) / (ranges[1] / res[1]))
        xval = floor(Int, (points[i].x+ranges[2]*0.5) / (ranges[2] / res[2]))

        if (yval < res[1] && xval < res[2] && xval > 0 && yval > 0)
            mix_color!(pixels[yval, xval], points[i])
            if pixels[yval, xval].val > max_val
                max_val = pixels[yval, xval].val
            end
        end 
    end

    #println(max_val)

    println("time to logscale:")
    @time pixels = [to_logscale(pixels[i,j], max_val; gamma=gamma)
              for i = 1:res[1], j = 1:res[2]]

    println("time to pixel blur:")
    @time blurred_pixels = fractal_conv(pixels; threshold = max_val)

    img = [to_rgb(blurred_pixels[i,j])
           for i = 1:res[1], j = 1:res[2]]

    println("time to normalize:")
    @time normalize!(img)

    save(filename, img)

end
