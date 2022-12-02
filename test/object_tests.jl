#------------------------------------------------------------------------------#
# Tests
# Note: circle tested in layering test, but maybe should also be tested here?
#------------------------------------------------------------------------------#

function square_tests(ArrayType::Type{AT}) where AT <: AbstractArray
    res = (10,10)
    bounds = [-2 2; -2 2]

    color_array = [[1.0, 0, 0, 1],
                   [0.0, 1, 0, 1],
                   [0.0, 0, 1, 1],
                   [1.0, 0, 1, 1]]

    square = Fae.define_square(; position = [0.0,0.0], scale = 4.0,
                                 color = color_array,
                                 name = "square_test")
    fl = FractalLayer(res; H1 = square, ArrayType = ArrayType)

    run!(fl, bounds)

    img = write_image(fl)

    @test isapprox(img[3,3], RGBA(0.0, 0.0, 1.0, 1.0))
    @test isapprox(img[3,8], RGBA(1.0, 0.0, 1.0, 1.0))
    @test isapprox(img[8,3], RGBA(0.0, 1.0, 0.0, 1.0))
    @test isapprox(img[8,8], RGBA(1.0, 0.0, 0.0, 1.0))

end

function triangle_tests(ArrayType::Type{AT}) where AT <: AbstractArray
    res = (11,11)
    bounds = [-0.5 0.5; -0.5 0.5]

    color_array = [[1.0, 0, 0, 1],
                   [0.0, 1, 0, 1],
                   [0.0, 0, 1, 1],
                   [1.0, 0, 1, 1]]

    triangle = Fae.define_triangle(; color = color_array,
                                     name = "triangle_test")
    fl = FractalLayer(res; H1 = triangle, ArrayType = ArrayType)

    run!(fl, bounds)

    img = write_image(fl)

    @test isapprox(img[3,6], RGBA(0.0, 1.0, 0.0, 1.0))
    @test isapprox(img[7,7], RGBA(1.0, 0.0, 1.0, 1.0))
    @test isapprox(img[8,3], RGBA(1.0, 0.0, 0.0, 1.0))
    @test isapprox(img[9,9], RGBA(0.0, 0.0, 1.0, 1.0))

end

#------------------------------------------------------------------------------#
# Testsuite
#------------------------------------------------------------------------------#
function object_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    @testset "square tests for $(string(ArrayType))s" begin
        square_tests(ArrayType)
    end

    @testset "triangle tests for $(string(ArrayType))s" begin
        triangle_tests(ArrayType)
    end

end
