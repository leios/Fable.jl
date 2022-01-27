@kernel function random_test_kernel!(a)
    tid = @index(Global, Linear)

    a[tid] = Fae.simple_rand(tid)
end


function random_test!(a; numcores = 4, numthreads = 256)

    if isa(a, Array)
        kernel! = random_test_kernel!(CPU(), numcores)
    else
        kernel! = random_test_kernel!(CUDADevice(), numthreads)
    end

    kernel!(a, ndrange = length(a))
end

@testset "affine transformation tests" begin

    #A = zeros(1024,1024)
    A = zeros(10,10)

    threshold = 0.001

    wait(random_test!(A))

    println(A)

    avg = sum(A)/length(A)

    @test abs(avg-0.5) < threshold

    if has_cuda_gpu()

        d_A = CuArray(zeros(1024, 1024))

        wait(random_test!(d_A))

        avg = sum(d_A)/length(d_A)

        @test abs(avg-0.5) < threshold
    end
end
