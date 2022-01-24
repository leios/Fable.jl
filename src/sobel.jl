# TODO: make kernel, use max(0, filter_corner) for bounds and summing
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

function bounds_check(signal, index, filter_width, dir)
    if index < 1
        filter_width - (1-index)
    elseif index > size(signal)[dir]
        return filter_width - (index - size(signal)[dir])
    else
        return filter_width
    end
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
