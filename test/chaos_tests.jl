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
    H = Fable.define_circle(; position = [0.0,0.0], radius = 2.0, 
                            color = [1.0, 1.0, 1.0, 1.0],
                            chosen_fx = :naive_disk)

    fl = FractalLayer(; ArrayType = ArrayType, config = :fractal_flame,
                      world_size = (4,4), ppu = 11/4, H1 = H)

    run!(fl)
    img = write_image(fl)

    @test color_gt(img[5,5], img[1,1])
    @test isapprox(img[5,5].r, img[4,4].r)
    @test isapprox(img[5,5].g, img[4,4].g)
    @test isapprox(img[5,5].b, img[4,4].b)

    GC.gc()

    H2 = Fable.define_circle(; position = [0.0,0.0], radius = 2.0,
                             color = [1.0, 1.0, 1.0, 1.0],
                           chosen_fx = :constant_disk)
    fl = FractalLayer(; ArrayType = ArrayType, config = :simple, H1 = H2,
                      world_size = (4,4), ppu = 11/4)
    run!(fl)
    img = write_image(fl)
    @test isapprox(img[5,5], img[4,4])
    @test !isapprox(img[5,5], img[1,1])
end


#------------------------------------------------------------------------------#
# Testsuite
#------------------------------------------------------------------------------#
function chaos_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    @testset "Chaos game tests for $(string(ArrayType))s" begin
        chaos_tests(ArrayType)
    end

end
