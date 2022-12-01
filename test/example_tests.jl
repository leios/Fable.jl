#------------------------------------------------------------------------------#
# Test Definitions
#------------------------------------------------------------------------------#

function example_tests(ArrayType::Type{AT}) where AT <: AbstractArray

    include("examples/barnsley.jl")
    main(1000, 1000; ArrayType = ArrayType)
    @test true

    include("examples/layering.jl")
    main(1000, 1000; ArrayType = ArrayType)
    @test true

    include("examples/shader.jl")
    main(radial; ArrayType = ArrayType)
    @test true

    include("examples/sierpinski.jl")
    main(1000, 1000, 10; ArrayType = ArrayType)
    @test true

    include("examples/smear.jl")
    main(1000, 1000, 10; ArrayType = ArrayType)
    @test true
end

#------------------------------------------------------------------------------#
# Testsuite Definition
#------------------------------------------------------------------------------#

function example_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray
    Fae.set_output(false)
    @testset "running all examples on $(string(ArrayType))s" begin
        example_tests(ArrayType)
    end
    Fae.set_output(true)
end
