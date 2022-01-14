function find_dims(a)
    if ndims(a) == 1
        return 1
    else
        return(size(a))[2]
    end 
end

# Function to use as a baseline for CPU metrics
function create_histogram(input; dims = find_dims(input),
                          bounds = zeros(dims, 2),
                          bin_width = ones(dims))
    maxes = ceil.(Int, maximum(input; dims = 1))
    h_dims = Tuple(Int(x) for x in maxes)
    histogram_output = zeros(Int, h_dims)

    for i = 1:length(input)
        bin = ceil(Int, (input[i,1] - bounds[1,1]) / bin_width[1])
        for j = 2:dims
            bin = ceil(Int, (input[i,j] - bounds[j,1]) / bin_width[j]) +
                  size(histogram_output)[j]*(bin-1)
        end
        println(bin)
        histogram_output[bin] += 1
    end
    return histogram_output
end

@testset "find bin test" begin

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

    for i = 1:10
        for j = 1:10
            index = j + (i-1)*10
            bin = FFlamify.find_bin(histogram_output, a, index, dims, bounds, bin_widths)
            histogram_output[bin] += 1
        end
    end

    flag = true

    for i = 1:100
        if histogram_output[i] != 1
            flag = false
        end
    end
    
    @test flag

end

#=
@testset "histogram kernel tests" begin

    rand_input = rand(128)*128
    rand_input_3d = rand(128, 3)*128
    linear_input = [i for i = 1:1024]
    #linear_input_2d = a = [i+(j-1)*10 for i = 1:10, j=1:10]
    all_2 = [2 for i = 1:512]

    histogram_rand_baseline = create_histogram(rand_input)
    histogram_rand_baseline_3d = create_histogram(rand_input_3d)
    histogram_linear_baseline = create_histogram(linear_input)
    histogram_2_baseline = create_histogram(all_2)

    CPU_rand_histogram = zeros(Int, 128)
    CPU_rand_histogram_3d = zeros(Int, 128, 128, 128)
    CPU_linear_histogram = zeros(Int, 1024)
    CPU_2_histogram = zeros(Int, 2)

    wait(FFlamify.histogram!(CPU_rand_histogram, rand_input))
    wait(FFlamify.histogram!(CPU_rand_histogram_3d, rand_input_3d))
    wait(FFlamify.histogram!(CPU_linear_histogram, linear_input))
    wait(FFlamify.histogram!(CPU_2_histogram, all_2))

    @test isapprox(CPU_rand_histogram, histogram_rand_baseline)
    @test isapprox(CPU_rand_histogram_3d, histogram_rand_baseline_3d)
    @test isapprox(CPU_linear_histogram, histogram_linear_baseline)
    @test isapprox(CPU_2_histogram, histogram_2_baseline)

    if has_cuda_gpu()
        CUDA.allowscalar(false)

        GPU_rand_input = CuArray(rand_input)
        GPU_rand_input_3d = CuArray(rand_input_3d)
        GPU_linear_input = CuArray(linear_input)
        GPU_2_input = CuArray(all_2)

        GPU_rand_histogram = CuArray(zeros(Int, 128))
        GPU_rand_histogram_3d = CuArray(zeros(Int, 128, 128, 128))
        GPU_linear_histogram = CuArray(zeros(Int, 1024))
        GPU_2_histogram = CuArray(zeros(Int, 2))

        wait(FFlamify.histogram!(GPU_rand_histogram, GPU_rand_input))
        wait(FFlamify.histogram!(GPU_rand_histogram_3d, GPU_rand_input_3d))
        wait(FFlamify.histogram!(GPU_linear_histogram, GPU_linear_input))
        wait(FFlamify.histogram!(GPU_2_histogram, GPU_2_input))

        @test isapprox(Array(GPU_rand_histogram), histogram_rand_baseline)
        @test isapprox(Array(GPU_rand_histogram_3d), histogram_rand_baseline_3d)
        @test isapprox(Array(GPU_linear_histogram), histogram_linear_baseline)
        @test isapprox(Array(GPU_2_histogram), histogram_2_baseline)
    end

end
=#
