#------------------------------------------------------------------------------#
# Test Definitions
#------------------------------------------------------------------------------#

function example_tests(ArrayType::Type{AT}) where AT <: AbstractArray

    include("../examples/barnsley.jl")
    barnsley_example(1000, 1000; ArrayType = ArrayType)
    @test true
    main = nothing

    include("../examples/layering.jl")
    layering_example(1000, 1000; ArrayType = ArrayType)
    @test true
    main = nothing

    include("../examples/shader.jl")
    shader_example(radial; ArrayType = ArrayType)
    @test true
    main = nothing

    include("../examples/sierpinski.jl")
    sierpinski_example(1000, 1000, 10; ArrayType = ArrayType)
    @test true
    main = nothing

    include("../examples/smear.jl")
    smear_example(1000, 1000, 10; ArrayType = ArrayType)
    @test true
    main = nothing
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
