#------------------------------------------------------------------------------#
# Helper Functions
#------------------------------------------------------------------------------#

function find_dims(a)
    if ndims(a) == 1
        return 1
    else
        return(size(a))[2]
    end 
end

# Function to use as a baseline for CPU metrics
function create_histogram!(histogram_output, input;
                          dims = find_dims(input),
                          bounds = zeros(dims, 2),
                          bin_widths = ones(dims))
 
    for i = 1:size(input)[1]
        bin = Fable.find_bin(histogram_output, input, i,
                             dims, bounds, bin_widths)
        histogram_output[bin] += 1
    end

end

#------------------------------------------------------------------------------#
# Test Definitions
#------------------------------------------------------------------------------#

function find_bin_tests()

    # Integer test
    # defining a to be 1's everywhere
    a = zeros(100,2)
    for i = 1:10
        a[(i-1)*10+1:i*10,1] .= i
        a[(i-1)*10+1:i*10,2] = 1:10
    end

    dims = 2
    bin_widths = [1,1]
    bounds = [0 0; 0 0]

    histogram_output = zeros(10,10)

    create_histogram!(histogram_output, a;
                      dims = dims, bounds = bounds, bin_widths = bin_widths)

    @test histogram_output == ones(10,10)

    # Floating point test
    # Subtracting 0.5 from A so it rounds up to the correct bins
    a[:] .-= 0.5

    histogram_output[:] .= 0

    create_histogram!(histogram_output, a;
                      dims = dims, bounds = bounds, bin_widths = bin_widths)

    @test histogram_output == ones(10,10)

end

function histogram_kernel_tests(ArrayType::Type{AT}) where AT <: AbstractArray

    rand_input = rand(Float32, 128)*128
    linear_input = [i for i = 1:1024]
    linear_input_2d = zeros(10000,2)
    for i = 1:100
        linear_input_2d[(i-1)*100+1:i*100,1] .= i
        linear_input_2d[(i-1)*100+1:i*100,2] = 1:100
    end
    offset_input_2d = zeros(10000,2)
    offset_input_2d[:] .= linear_input_2d[:] .- 0.5
    all_2 = [2 for i = 1:512]
    rand_input_2d = rand(Float32, 128, 2)*128
    rand_input_3d = rand(Float32, 32, 3)*32

    histogram_rand_baseline = zeros(Int, 128)
    histogram_linear_baseline = zeros(Int, 1024)
    histogram_linear_2d_baseline = zeros(Int, 100, 100)
    histogram_offset_2d_baseline = zeros(Int, 100, 100)
    histogram_2_baseline = zeros(Int, 2)
    histogram_rand_baseline_2d = zeros(Int, 128, 128)
    histogram_rand_baseline_3d = zeros(Int, 32, 32, 32)

    create_histogram!(histogram_rand_baseline, rand_input)
    create_histogram!(histogram_linear_baseline, linear_input)
    create_histogram!(histogram_linear_2d_baseline, linear_input_2d)
    create_histogram!(histogram_offset_2d_baseline, offset_input_2d)
    create_histogram!(histogram_2_baseline, all_2)
    create_histogram!(histogram_rand_baseline_2d, rand_input_2d)
    create_histogram!(histogram_rand_baseline_3d, rand_input_3d)

    rand_histogram = ArrayType(zeros(Int, 128))
    linear_histogram = ArrayType(zeros(Int, 1024))
    linear_2d_histogram = ArrayType(zeros(Int, 100, 100))
    offset_2d_histogram = ArrayType(zeros(Int, 100, 100))
    histogram_2s = ArrayType(zeros(Int, 2))
    rand_histogram_2d = ArrayType(zeros(Int, 128, 128))
    rand_histogram_3d = ArrayType(zeros(Int, 32, 32, 32))

    @time Fable.histogram!(rand_histogram, ArrayType(rand_input);
                           ArrayType = ArrayType)
    @time Fable.histogram!(linear_histogram, ArrayType(linear_input);
                           ArrayType = ArrayType)
    @time Fable.histogram!(linear_2d_histogram, ArrayType(linear_input_2d);
                           ArrayType = ArrayType)
    @time Fable.histogram!(offset_2d_histogram, ArrayType(linear_input_2d);
                           ArrayType = ArrayType)
    @time Fable.histogram!(histogram_2s, ArrayType(all_2);
                           ArrayType = ArrayType)
    @time Fable.histogram!(rand_histogram_2d, ArrayType(rand_input_2d);
                           ArrayType = ArrayType)
    @time Fable.histogram!(rand_histogram_3d, ArrayType(rand_input_3d);
                           ArrayType = ArrayType)

    @test isapprox(Array(rand_histogram), histogram_rand_baseline)
    @test isapprox(Array(linear_histogram), histogram_linear_baseline)
    @test isapprox(Array(linear_2d_histogram), histogram_linear_2d_baseline)
    @test isapprox(Array(offset_2d_histogram), histogram_offset_2d_baseline)
    @test isapprox(Array(histogram_2s), histogram_2_baseline)
    @test isapprox(Array(rand_histogram_2d), histogram_rand_baseline_2d)
    @test isapprox(Array(rand_histogram_3d), histogram_rand_baseline_3d)

end

#------------------------------------------------------------------------------#
# Testsuit Definition
#------------------------------------------------------------------------------#

function histogram_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray
    if ArrayType <: Array
        @testset "find bin tests" begin
            find_bin_tests()
        end
    end

    @testset "Histogram kernel tests for $(string(ArrayType))s" begin
        histogram_kernel_tests(ArrayType)
    end
end
