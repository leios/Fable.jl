function mix_color(a::RGB, b::RGB)
    return RGB(0.5*(a.r+b.r), 0.5*(a.g+b.g), 0.5*(a.b + b.b))
end

function mix_color!(pix::Pixel, p::Point)
    pix.c = (pix.c*pix.val + p.c)/(pix.val + 1)
    pix.val += 1
end

function to_rgb(pix::Pixel, max_val; gamma = 2.2)
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

    return final_color
end

function write_image(points::Vector{Point}, ranges, res, filename;
                     point_offset = 10, gamma = 2.2)

    # reversing resolution and ranges because Julia expects y-axis first
    res = reverse(res)
    ranges = reverse(ranges)
    pixels = [Pixel(0) for i=1:res[1], j=1:res[2]]

    max_val = 0

    # bin the pixels
    for i = point_offset:length(points)

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

    println(max_val)

    img = [to_rgb(pixels[i,j], max_val; gamma=gamma)
           for i = 1:res[1], j = 1:res[2]]

    save(filename, img)

end
