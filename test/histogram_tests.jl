# Function to use as a baseline for CPU metrics
function create_histogram(input)
    histogram_output = zeros(Int, maximum(input))
    for i = 1:length(input)
        histogram_output[input[i]] += 1
    end
    return histogram_output
end

@testset "histogram tests" begin

    rand_input = [rand(1:128) for i = 1:1000]
    linear_input = [i for i = 1:1024]
    all_2 = [2 for i = 1:512]

    histogram_rand_baseline = create_histogram(rand_input)
    histogram_linear_baseline = create_histogram(linear_input)
    histogram_2_baseline = create_histogram(all_2)

    CPU_rand_histogram = zeros(Int, 128)
    CPU_linear_histogram = zeros(Int, 1024)
    CPU_2_histogram = zeros(Int, 2)

    wait(FFlamify.histogram!(CPU_rand_histogram, rand_input))
    wait(FFlamify.histogram!(CPU_linear_histogram, linear_input))
    wait(FFlamify.histogram!(CPU_2_histogram, all_2))

    @test isapprox(CPU_rand_histogram, histogram_rand_baseline)
    @test isapprox(CPU_linear_histogram, histogram_linear_baseline)
    @test isapprox(CPU_2_histogram, histogram_2_baseline)

    if has_cuda_gpu()
        CUDA.allowscalar(false)

        GPU_rand_input = CuArray(rand_input)
        GPU_linear_input = CuArray(linear_input)
        GPU_2_input = CuArray(all_2)

        GPU_rand_histogram = CuArray(zeros(Int, 128))
        GPU_linear_histogram = CuArray(zeros(Int, 1024))
        GPU_2_histogram = CuArray(zeros(Int, 2))

        wait(FFlamify.histogram!(GPU_rand_histogram, GPU_rand_input))
        wait(FFlamify.histogram!(GPU_linear_histogram, GPU_linear_input))
        wait(FFlamify.histogram!(GPU_2_histogram, GPU_2_input))

        @test isapprox(Array(GPU_rand_histogram), histogram_rand_baseline)
        @test isapprox(Array(GPU_linear_histogram), histogram_linear_baseline)
        @test isapprox(Array(GPU_2_histogram), histogram_2_baseline)
    end

end
