function mix_color!(pix::Pixel, p::Point)
    pix.c = (pix.c*pix.val + p.c)/(pix.val + 1)
    pix.val += 1
end

function to_rgb(pix::Pixel)
    return pix.c
end

function write_image(points::Vector{Point}, ranges, res, filename;
                     point_offset = 10)

    # reversing resolution and ranges because Julia expects y-axis first
    res = reverse(res)
    ranges = reverse(ranges)
    pixels = [Pixel(0) for i=1:res[1], j=1:res[2]]

    println(size(pixels))

    # bin the pixels
    for i = point_offset:length(points)

        # Notes: - Points are in (x, y), while visualization is in (y, x)
        #        - y value needs to be flipped because drawing should be from
        #          lower left
        yval = floor(Int, (ranges[1]*0.5-points[i].y) / (ranges[1] / res[1]))
        xval = floor(Int, (points[i].x+ranges[2]*0.5) / (ranges[2] / res[2]))

        if (yval < res[1] && xval < res[2] && xval > 0 && yval > 0)
            mix_color!(pixels[yval, xval], points[i])
        end 
    end

    img = [to_rgb(pixels[i,j]) for i = 1:res[1], j = 1:res[2]]

    save(filename, img)

end
