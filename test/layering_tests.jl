#------------------------------------------------------------------------------#
# Helper Functions
#------------------------------------------------------------------------------#

# shader that is white above 0, and black below 0
test_fum = @fum function test_fum(x,y)
    if y > 0
        r = 1.0
        g = 1.0
        b = 1.0
        a = 1.0
    else
        r = 0.0
        g = 0.0
        b = 0.0
        a = 0.0
    end
end

#------------------------------------------------------------------------------#
# Tests
#------------------------------------------------------------------------------#

function layering_tests(ArrayType::Type{AT}) where AT <: AbstractArray

    res = (11,11)

    cl = ColorLayer(RGBA(1, 0, 1, 1), res; ArrayType = ArrayType)
    sl = ShaderLayer(test_fum, res; ArrayType = ArrayType)
    circle = Fae.define_circle([0.0,0.0], 2.0, [0.0, 0.0, 1.0, 1.0])
    fl = FractalLayer(res; H1 = circle, ArrayType = ArrayType)

    layers = [cl, sl, fl]

    run!(layers)

    img = write_image(layers)

    @test isapprox(img[1,1], RGBA(1.0, 1.0, 1.0, 1.0))
    @test isapprox(img[11,1], RGBA(1.0, 0.0, 1.0, 1.0))
    @test isapprox(img[5,5], RGBA(0.0, 0.0, 1.0, 1.0))
end


#------------------------------------------------------------------------------#
# Testsuite
#------------------------------------------------------------------------------#
function chaos_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    @testset "Chaos game tests for $(string(ArrayType))s" begin
        chaos_tests(ArrayType)
    end

end
