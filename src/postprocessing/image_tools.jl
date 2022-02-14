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
    alpha = 0

    # TODO: check to see if this is an appropriate log implementation
    # TODO: What's meant by "vibrant colors?"
    if val != 0
        alpha = log10((9*val/max_val)+1)
        #alpha = 1 + log10(val/max_val)
    end
    final_color = RGBA(r, g, b, alpha)

    # Applying Gamma
    # TODO: We should be able to broadcast a power operation to clean this up
    final_color = RGBA(final_color.r^(1/gamma),
                       final_color.g^(1/gamma),
                       final_color.b^(1/gamma),
                       alpha^(1/gamma))

    return final_color
end

function write_image(pixels::Vector{Pixels}, filename; gamma = 2.2,
                     img = fill(RGB(0,0,0), size(pixels[1].values)))
    for i = 1:length(pixels)
        add_layer!(img, pixels[i]; gamma = gamma)
    end

    save(filename, img)
end

function add_layer!(img, layer::Pixels; gamma = 2.2, diagnostic = false)

    pix = layer

    if !isa(layer.values, Array)
        pix = Pixels(Array(layer.values), Array(layer.reds),
                     Array(layer.greens), Array(layer.blues))
    end

    max_val = maximum(pix.values)
    if diagnostic
        println("sum of all pixel values: ", sum(pix.values))
        println("max red is: ", maximum(layer.reds))
        println("max green is: ", maximum(layer.greens))
        println("max blue is: ", maximum(layer.blues))
    end

    pix.reds[:] .= pix.reds[:] ./ max.(1, pix.values[:])
    pix.greens[:] .= pix.greens[:] ./ max.(1, pix.values[:])
    pix.blues[:] .= pix.blues[:] ./ max.(1, pix.values[:])

    for i = 1:length(pix.reds)
        if pix.reds[i] > 1
            pix.reds[i] = 1
        end
        if pix.greens[i] > 1
            pix.greens[i] = 1
        end
        if pix.blues[i] > 1
            pix.blues[i] = 1
        end
    end

    for i = 1:length(img)
        new_val = to_logscale(pix.reds[i], pix.greens[i], pix.blues[i],
                              pix.values[i], max_val; gamma = gamma)
        img[i] = img[i]*(1-new_val.alpha) + RGB(new_val.r*new_val.alpha,
                                                new_val.g*new_val.alpha,
                                                new_val.b*new_val.alpha)
        if diagnostic
            if img[i].r >= 1
                println("Red ", i, " has a value greater than 1. "*
                        "Value of: ", img[i].r)
            end
            if img[i].g >= 1
                println("Green ", i, " has a value greater than 1. "*
                        "Value of: ", img[i].g)
            end
            if img[i].b >= 1
                println("Blue ", i, " has a value greater than 1. "*
                        "Value of: ", img[i].b)
            end
        end

    end

end
