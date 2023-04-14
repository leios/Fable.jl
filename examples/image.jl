using Fae, Images

function image_example(; input_filename = "check.png",
                         output_filename = "check_copy.png")

    il = ImageLayer(input_filename)

    write_image(il; filename = output_filename)
end

@info("Created Function: image_example(; input_filename = 'check.png',
                                        output_filename = 'check_copy.png')")
