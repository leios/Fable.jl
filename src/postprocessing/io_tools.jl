export write_image, write_video!

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

function to_rgb(r,g,b)
    return RGB(r,g,b)
end

function to_logscale!(img, pix)
    for i = 1:length(img)
        if pix.values[i] != 0
            if pix.logscale
                alpha = log10((9*pix.values[i]/pix.max_value)+1)
            else
                alpha = pix.values[i]/pix.max_value
            end

            new_color = RGB(pix.reds[i]^(1/pix.gamma),
                            pix.greens[i]^(1/pix.gamma),
                            pix.blues[i]^(1/pix.gamma)) * alpha^(1/pix.gamma)

            img[i] = img[i]*(1-alpha^(1/pix.gamma)) + new_color
        end
    end
end

function write_image(pixels::Vector{Pixels}, filename;
                     img = fill(RGB(0,0,0), size(pixels[1].values)),
                     diagnostic = false)
    for i = 1:length(pixels)
        add_layer!(img, pixels[i]; diagnostic = diagnostic)
    end

    save(filename, img)
    println(filename)
end

function write_video!(v::VideoParams, pixels::Vector{Pixels};
                      diagnostic = false)
    for i = 1:length(pixels)
        add_layer!(v.frame, pixels[i]; diagnostic = diagnostic)
    end

    write(v.writer, v.frame)
    zero!(v.frame)
    println(v.frame_count)
    v.frame_count += 1
end

function add_layer!(img, layer::Pixels; diagnostic = false)

    println("Initialization:")
    @time begin
        pix = layer

        if !isa(layer.values, Array)
            pix = Pixels(Array(layer.values), Array(layer.reds),
                         Array(layer.greens), Array(layer.blues))
        end

        if pix.calc_max_value != 0
            pix.max_value = maximum(pix.values)
        end
        if diagnostic
            println("sum of all pixel values: ", sum(pix.values))
            println("max red is: ", maximum(layer.reds))
            println("max green is: ", maximum(layer.greens))
            println("max blue is: ", maximum(layer.blues))
        end

        # naive normalization
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
    end

    println("writing to layer")
    @time to_logscale!(img, pix)

end
