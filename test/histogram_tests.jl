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
        bin = FFlamify.find_bin(histogram_output,
                                input, i, dims,
                                bounds, bin_widths)
        histogram_output[bin] += 1
    end

end

@testset "find bin test" begin

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

@testset "histogram kernel tests" begin

    rand_input = rand(Float32, 128)*128
    linear_input = [i for i = 1:1024]
    linear_input_2d = zeros(16384,2)
    for i = 1:128
        linear_input_2d[(i-1)*128+1:i*128,1] .= i
        linear_input_2d[(i-1)*128+1:i*128,2] = 1:128
    end
    offset_input_2d = zeros(16384,2)
    offset_input_2d[:] .= linear_input_2d[:] .- 0.5
    all_2 = [2 for i = 1:512]
    rand_input_2d = rand(Float32, 128, 2)*128
    rand_input_3d = rand(Float32, 32, 3)*32

    histogram_rand_baseline = zeros(Int, 128)
    histogram_linear_baseline = zeros(Int, 1024)
    histogram_linear_2d_baseline = zeros(Int, 128, 128)
    histogram_offset_2d_baseline = zeros(Int, 128, 128)
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

    CPU_rand_histogram = zeros(Int, 128)
    CPU_linear_histogram = zeros(Int, 1024)
    CPU_linear_2d_histogram = zeros(Int, 128, 128)
    CPU_offset_2d_histogram = zeros(Int, 128, 128)
    CPU_2_histogram = zeros(Int, 2)
    CPU_rand_histogram_2d = zeros(Int, 128, 128)
    CPU_rand_histogram_3d = zeros(Int, 32, 32, 32)

    wait(FFlamify.histogram!(CPU_rand_histogram, rand_input))
    wait(FFlamify.histogram!(CPU_linear_histogram, linear_input))
    wait(FFlamify.histogram!(CPU_linear_2d_histogram, linear_input_2d))
    wait(FFlamify.histogram!(CPU_offset_2d_histogram, linear_input_2d))
    wait(FFlamify.histogram!(CPU_2_histogram, all_2))
    wait(FFlamify.histogram!(CPU_rand_histogram_2d, rand_input_2d))
    wait(FFlamify.histogram!(CPU_rand_histogram_3d, rand_input_3d))

    @test isapprox(CPU_rand_histogram, histogram_rand_baseline)
    @test isapprox(CPU_linear_histogram, histogram_linear_baseline)
    @test isapprox(CPU_linear_2d_histogram, histogram_linear_2d_baseline)
    @test isapprox(CPU_offset_2d_histogram, histogram_offset_2d_baseline)
    @test isapprox(CPU_2_histogram, histogram_2_baseline)
    @test isapprox(CPU_rand_histogram_2d, histogram_rand_baseline_2d)
    @test isapprox(CPU_rand_histogram_3d, histogram_rand_baseline_3d)

    if has_cuda_gpu()
        CUDA.allowscalar(false)

        GPU_rand_input = CuArray(rand_input)
        GPU_linear_input = CuArray(linear_input)
        GPU_linear_2d_input = CuArray(linear_input_2d)
        GPU_offset_2d_input = CuArray(offset_input_2d)
        GPU_2_input = CuArray(all_2)
        GPU_rand_input_2d = CuArray(rand_input_2d)
        GPU_rand_input_3d = CuArray(rand_input_3d)

        GPU_rand_histogram = CuArray(zeros(Int, 128))
        GPU_linear_histogram = CuArray(zeros(Int, 1024))
        GPU_linear_2d_histogram = CuArray(zeros(Int, 128, 128))
        GPU_offset_2d_histogram = CuArray(zeros(Int, 128, 128))
        GPU_2_histogram = CuArray(zeros(Int, 2))
        GPU_rand_histogram_2d = CuArray(zeros(Int, 128, 128))
        GPU_rand_histogram_3d = CuArray(zeros(Int, 32, 32, 32))

        wait(FFlamify.histogram!(GPU_rand_histogram, GPU_rand_input))
        wait(FFlamify.histogram!(GPU_linear_histogram, GPU_linear_input))
        wait(FFlamify.histogram!(GPU_linear_2d_histogram, GPU_linear_2d_input))
        wait(FFlamify.histogram!(GPU_offset_2d_histogram, GPU_offset_2d_input))
        wait(FFlamify.histogram!(GPU_2_histogram, GPU_2_input))
        wait(FFlamify.histogram!(GPU_rand_histogram_2d, GPU_rand_input_2d;numthreads = 32))
        wait(FFlamify.histogram!(GPU_rand_histogram_3d, GPU_rand_input_3d;numthreads = 64))

#=
        return (Array(GPU_linear_2d_histogram), histogram_linear_2d_baseline)
        #return (Array(GPU_rand_histogram_2d), histogram_rand_baseline_2d)
        println(sum(Array(GPU_rand_histogram_2d)))
        println(sum(CPU_rand_histogram_2d))
        println(sum(histogram_rand_baseline_2d))
        println(sum(Array(GPU_rand_histogram_3d)))
        println(sum(CPU_rand_histogram_3d))
        println(sum(histogram_rand_baseline_3d))
=#

        @test isapprox(Array(GPU_rand_histogram), histogram_rand_baseline)
        @test isapprox(Array(GPU_linear_histogram), histogram_linear_baseline)
        @test isapprox(Array(GPU_linear_2d_histogram),
                       histogram_linear_2d_baseline)
        @test isapprox(Array(GPU_offset_2d_histogram),
                       histogram_offset_2d_baseline)
        @test isapprox(Array(GPU_2_histogram), histogram_2_baseline)
        @test isapprox(Array(GPU_rand_histogram_2d), histogram_rand_baseline_2d)
        @test isapprox(Array(GPU_rand_histogram_3d), histogram_rand_baseline_3d)
    end

end
