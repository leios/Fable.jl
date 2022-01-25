# TODO: Probably shouldn't print anything anymore...
using LinearAlgebra

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

function pixel_sum(signal::Array{Pixel,2})
    rsum = 0
    for i = 1:length(signal)
        rsum += signal[i].val
    end

    return rsum
end

function to_rgb(r,g,b)
    return RGB(r,g,b)
end


function to_logscale(r,g,b,val, max_val; gamma = 2.2)
    alpha = 1

    # TODO: check to see if this is an appropriate log implementation
    # TODO: What's meant by "vibrant colors?"
    if val != 0
        alpha = log10((9*val/max_val)+1)
        #alpha = 1 + log10(val/max_val)
    end
    final_color = RGB(r*alpha, g*alpha, b*alpha)

    # Applying Gamma
    # TODO: We should be able to broadcast a power operation to clean this up
    final_color = RGB(final_color.r^(1/gamma),
                      final_color.g^(1/gamma),
                      final_color.b^(1/gamma))

    return final_color
end

function write_image(pix::Pixels, filename; gamma = 2.2)

    img = Array{RGB,2}(undef, size(pix.values))

    if !isa(pix.values, Array)
        pix = Pixels(Array(pix.values), Array(pix.reds),
                     Array(pix.greens), Array(pix.blues))
    end

    max_val = maximum(pix.values)
    for i = 1:length(img)
        img[i] = to_logscale(pix.reds[i], pix.greens[i], pix.blues[i],
                             pix.values[i], max_val; gamma = gamma)
    end

    save(filename, img)

end

#=
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
=#
