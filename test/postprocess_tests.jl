# Note: Not sure how to test the filters (Sobel, Gauss, Outline), so I have 
#       examples instead
#------------------------------------------------------------------------------#
# Tests
#------------------------------------------------------------------------------#

# This will clip all values above a certain threshold value to be at a
# designated color
function clip_tests(ArrayType::Type{AT}) where AT <: AbstractArray

    clip = Clip(; threshold = 0.25, color = RGB(1.0, 0, 1))
    cl = ColorLayer(RGB(0.5, 0.5, 0.5); world_size = (1, 1), ppu = 1,
                    postprocessing_steps = [clip])

    img = write_image(cl)

    @test img[1,1] == RGBA(1.0, 0.0, 1.0, 1.0)

    cl = ColorLayer(RGB(0.2, 0.2, 0.2); world_size = (1, 1), ppu = 1,
                    postprocessing_steps = [clip])

    img = write_image(cl)
    @test img[1,1] == RGBA{Float32}(0.2, 0.2, 0.2, 1.0)

    clip = Clip(; threshold = 0.25, color = RGB(1.0, 0, 1), clip_op = <)
    cl = ColorLayer(RGB(0.5, 0.5, 0.5); world_size = (1, 1), ppu = 1,
                    postprocessing_steps = [clip])

    img = write_image(cl)

    @test img[1,1] == RGBA{Float32}(0.5, 0.5, 0.5, 1.0)

    cl = ColorLayer(RGB(0.2, 0.2, 0.2); world_size = (1, 1), ppu = 1,
                    postprocessing_steps = [clip])

    img = write_image(cl)
    @test img[1,1] == RGBA(1.0, 0.0, 1.0, 1.0)

end

function filter_tests(ArrayType::Type{AT}) where AT <: AbstractArray
    identity = Identity()
    cl = ColorLayer(RGB(0.2, 0.2, 0.2); world_size = (4, 4), ppu = 1,
                    postprocessing_steps = [identity])

    img = write_image(cl)
    for i = 1:length(img)
        @test img[i] == RGBA{Float32}(0.2, 0.2, 0.2, 1.0)
    end
end

#------------------------------------------------------------------------------#
# Testsuite
#------------------------------------------------------------------------------#
function postprocess_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    @testset "Postprocess tests for $(string(ArrayType))s" begin
        clip_tests(ArrayType)
        filter_tests(ArrayType)
    end

end
