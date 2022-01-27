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

    a = zeros(1024,1024)
    #a = zeros(10,10)

    threshold = 0.00001

    wait(random_test!(a))

    a ./= typemax(UInt)

    avg = sum(a)/length(a)

    @test abs(avg-0.5) < threshold

    if has_cuda_gpu()

        d_a = CuArray(zeros(1024, 1024))

        wait(random_test!(d_a))
        d_a ./= typemax(UInt)

        avg = sum(d_a)/length(d_a)

        @test abs(avg-0.5) < threshold
    end
end
