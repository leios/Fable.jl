#------------------------------------------------------------------------------#
# Helper Functions
#------------------------------------------------------------------------------#

# Consider also testing RGB
function color_lt(a::CT1, b::CT2) where {CT1 <: RGBA, CT2 <: RGBA}
    return (a.r <= b.r) &
           (a.g <= b.g) &
           (a.b <= b.b) &
           (a.alpha <= b.alpha)
end

function color_gt(a::CT1, b::CT2) where {CT1 <: RGBA, CT2 <: RGBA}
    return color_lt(b, a)
end

#------------------------------------------------------------------------------#
# Tests
#------------------------------------------------------------------------------#

function chaos_tests(ArrayType::Type{AT}) where AT <: AbstractArray
    bounds = [-2 2;-2 2]

    H = Fae.define_circle([0.0,0.0], 2.0, [1.0, 1.0, 1.0];
                          chosen_fx = :naive_disk)

    fl = FractalLayer((11,11); ArrayType = ArrayType, config = :fractal_flame,
                      H_1 = H)
    run!(fl, bounds)
    img = write_image(fl)

    @test color_gt(img[5,5], img[1,1])
    @test isapprox(img[5,5].r, img[1,1].r) &
          isapprox(img[5,5].g, img[1,1].g) &
          isapprox(img[5,5].b, img[1,1].b)

    fl = FractalLayer((11,11); ArrayType = ArrayType, config = :simple, H_1 = H)
    run!(fl, bounds)
    img = write_image(fl)
    @test isapprox(img[5,5], img[1,1])
end


#------------------------------------------------------------------------------#
# Testsuite
#------------------------------------------------------------------------------#
function chaos_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    @testset "Chaos game tests for $(string(ArrayType))s" begin
        chaos_tests(ArrayType)
    end

end
