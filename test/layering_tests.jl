# TODO: Layering at different positions (need to fix io functions first)
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

# TODO: Figure out appropriate indices for this test
function overlap_tests()

    # Perfectly aligned
    cl1 = ColorLayer(RGB(0,0,0); ppu = 1)
    cl2 = ColorLayer(RGB(0,0,0); ppu = 1)

    overlap = find_overlap(cl1, cl2)

    @test overlap.range == size(cl1.canvas)
    @test overlap.start_index_1 == (1,1)
    @test overlap.start_index_2 == (1,1)

    # inbedded test
    cl1 = ColorLayer(RGB(0,0,0); ppu = 1, size = (15, 15))
    cl2 = ColorLayer(RGB(0,0,0); ppu = 1, size = (10, 10))

    overlap = find_overlap(cl1, cl2)

    @test overlap.range == size(cl2.canvas)
    @test overlap.start_index_1 == (3, 3)
    @test overlap.start_index_2 == (1, 1)

    # different ppus
    cl1 = ColorLayer(RGB(0,0,0); ppu = 2, size = (10, 10))
    cl2 = ColorLayer(RGB(0,0,0); ppu = 3, size = (15, 15))

    overlap = find_overlap(cl1, cl2)

    @test overlap.range == size(cl1.canvas)
    @test overlap.start_index_1 == (1, 1)
    @test overlap.start_index_2 == (8, 8)

    # bounding tests
    # TODO: Implement tests for small shifts (such as 0.5)
    #       I have not quite decided the best way to deal with offset grids
    shifts = (0)

    default_size = (10, 10)
    default_position = (0,0)
    default_ppu = 1

    position_offsets = ((5, 5), (5, -5), (-5, -5), (-5, 5),
                        (0, 5), (0, -5), (5, 0), (-5, 0))

    expected_ranges = ((5, 5), (5, 5), (5, 5), (5, 5),
                       (10, 5), (10, 5), (5, 10), (5, 10))

    expected_start_indices_1 = ((6, 6), (6, 1), (1, 1), (1, 6),
                                (1, 6), (1, 1), (6, 1), (1, 1))

    expected_start_indices_2 = ((1, 1), (1, 6), (6, 6), (6, 1),
                                (1, 1), (1, 6), (1, 1), (6, 1))

    # Offset grid with centered 1 and 2 at LR, LL, UL, UR, D, U, L, R
    cl1 = ColorLayer(RGB(0,0,0);
                     ppu = default_ppu,
                     position = default_position,
                     size = default_size)

    for shift in shifts
        for i = 1:length(position_offsets)
            new_position = (position_offsets[i][1] + shift,
                            position_offsets[i][2] + shift)
            cl2 = ColorLayer(RGB(0,0,0);
                             ppu = default_ppu,
                             position = new_position,
                             size = default_size)
            overlap = find_overlap(cl1, cl2)

            @test overlap.range == expected_ranges[i]
            @test overlap.start_index_1 == expected_start_indices_1[i]
            @test overlap.start_index_2 == expected_start_indices_2[i]

            # testing opposite
            overlap = find_overlap(cl2, cl1)

            @test overlap.range == expected_ranges[i]
            @test overlap.start_index_1 == expected_start_indices_2[i]
            @test overlap.start_index_2 == expected_start_indices_1[i]
        end
    end

end

function bounds_tests()

    # default tests
    cl = ColorLayer(RGB(0,0,0))
    bounds = find_bounds(cl)
    @test   Bool(floor(sum(values(bounds) .== (-0.45, 0.45, -0.8, 0.8))/4))

    # random tests
    for i = 1:10
        position = Tuple(rand(2) * 10 .- 5)
        size = Tuple(rand(2)*100)
        cl = ColorLayer(RGB(0,0,0); position = position, size = size, ppu = 1)
        bounds = find_bounds(cl)
        expected_bounds = (position[1] - size[1]*0.5,
                           position[1] + size[1]*0.5,
                           position[2] - size[2]*0.5,
                           position[2] + size[2]*0.5)
        @test Bool(floor(sum(values(bounds) .== expected_bounds)/4))
    end
end

#------------------------------------------------------------------------------#
# Testsuite
#------------------------------------------------------------------------------#
function layering_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    if ArrayType <: Array
        @testset "overlap / bounding tests" begin
            overlap_tests()
            bounds_tests()
        end
    end

    @testset "Layering tests for $(string(ArrayType))s" begin
        layering_tests(ArrayType)
    end

end
