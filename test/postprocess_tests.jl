#------------------------------------------------------------------------------#
# Helper Functions
#------------------------------------------------------------------------------#

# Shader to create some field to clip

#------------------------------------------------------------------------------#
# Tests
#------------------------------------------------------------------------------#

# This will clip all values above a certain threshold value to be at a
# designated color
function clip_tests(ArrayType::Type{AT}) where AT <: AbstractArray
end

# This will test the Sobel, Gauss, and generic filters
function filter_tests(ArrayType::Type{AT}) where AT <: AbstractArray
end

# This will make sure we can make outlines of variable linewidth
function outline_tests(ArrayType::Type{AT}) where AT <: AbstractArray
end

#------------------------------------------------------------------------------#
# Testsuite
#------------------------------------------------------------------------------#
function postprocess_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    @testset "Postprocess tests for $(string(ArrayType))s" begin
        clip_tests(ArrayType)
        filter_tests(ArrayType)
        outline_tests(ArrayType)
    end

end
