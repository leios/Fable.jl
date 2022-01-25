function cpu_affine!(p::Array{Float64,2}, A)
    for i = 1:size(p)[1]
        p[i,:] .= cpu_affine(p[i,:], A)
    end
end

function cpu_affine(p::Array{Float64}, A)
    return A[1:end-1,1:end-1]*p[:] + 
           A[1:length(p),end]
end

@testset "affine transformation tests" begin

    # 2D tests
    halfs = [0.5 0.5 0.5;
             0.5 0.5 0.5;
             0   0   1  ]

    one_input = ones(100,2)

    affine_baseline_2d = copy(one_input)
    affine_test = copy(one_input)

    cpu_affine!(affine_baseline_2d, halfs)
    wait(Fae.affine!(affine_test, halfs))

    @test isapprox(affine_test, affine_baseline_2d)

    flag = true
    for i = 1:length(affine_test)
        if affine_test[i] != 1.5
            flag = false
        end
    end
    @test flag

    # 3D tests
    rand_input_3d = rand(1024,3)
    affine_baseline_3d = copy(rand_input_3d)
    affine_test = copy(rand_input_3d)

    A_3d = zeros(4,4)
    A_3d[1:3,:] = rand(3,4)*2 .- 1

    cpu_affine!(affine_baseline_3d, A_3d)
    wait(Fae.affine!(affine_test, A_3d))

    @test isapprox(affine_test, affine_baseline_3d)

    # 4D
    rand_input_4d = rand(1000000,4)
    affine_baseline_4d = copy(rand_input_4d)
    affine_test = copy(rand_input_4d)

    A_4d = zeros(5,5)
    A_4d[1:4,:] = rand(4,5)*2 .- 1

    cpu_affine!(affine_baseline_4d, A_4d)
    wait(Fae.affine!(affine_test, A_4d))

    @test isapprox(affine_test, affine_baseline_4d)

    if has_cuda_gpu()
        # 2D tests
        GPU_halfs = CuArray(halfs)
        GPU_3d = CuArray(A_3d)
        GPU_4d = CuArray(A_4d)

        GPU_ones = CuArray(ones(100,2))

        wait(Fae.affine!(GPU_ones, GPU_halfs))

        GPU_output = Array(GPU_ones)
        @test GPU_output == affine_baseline_2d

        flag = true
        for i = 1:length(GPU_output)
            if GPU_output[i] != 1.5
                flag = false
            end
        end
        @test flag

        # 3D tests
        GPU_rand_3d = CuArray(rand_input_3d)

        wait(Fae.affine!(GPU_rand_3d, GPU_3d))

        @test isapprox(Array(GPU_rand_3d), affine_baseline_3d)

        # 4D
        GPU_rand_4d = CuArray(rand_input_4d)

        wait(Fae.affine!(GPU_rand_4d, GPU_4d))

        @test isapprox(Array(GPU_rand_4d), affine_baseline_4d)

    end


end
