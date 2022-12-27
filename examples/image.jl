using Fae, Images

function image_example()

    il = ImageLayer("check.png")

    write_image(il; filename = "check_copy.png")
end
