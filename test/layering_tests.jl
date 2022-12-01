#------------------------------------------------------------------------------#
# Helper Functions
#------------------------------------------------------------------------------#

# shader that is white above 0, and black below 0
test_fum = @fum function test_fum(x,y)
    if y > 0
        red = 1.0
        green = 1.0
        blue = 1.0
        alpha = 1.0
    else
        red = 0.0
        green = 0.0
        blue = 0.0
        alpha = 0.0
    end
end

#------------------------------------------------------------------------------#
# Tests
#------------------------------------------------------------------------------#

function layering_tests(ArrayType::Type{AT}) where AT <: AbstractArray

    res = (11,11)
    bounds = [-2 2; -2 2]

    cl = ColorLayer(RGBA(1, 0, 1, 1), res; ArrayType = ArrayType)
    sl = ShaderLayer(test_fum, res; ArrayType = ArrayType)
    circle = Fae.define_circle(; position = [0.0,0.0], radius = 2.0, 
                                 color = [0.0, 0.0, 1.0, 1.0],
                                 name = "layering_circle_test")
    fl = FractalLayer(res; H1 = circle, ArrayType = ArrayType)

    layers = [cl, sl, fl]

    run!(layers, bounds)

    img = write_image(layers)

    @test isapprox(img[1,1], RGBA(1.0, 0.0, 1.0, 1.0))
    @test isapprox(img[11,1], RGBA(1.0, 1.0, 1.0, 1.0))
    @test isapprox(img[5,5], RGBA(0.0, 0.0, 1.0, 1.0))
end


#------------------------------------------------------------------------------#
# Testsuite
#------------------------------------------------------------------------------#
function layering_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    @testset "Layering tests for $(string(ArrayType))s" begin
        layering_tests(ArrayType)
    end

end
