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

@testset "fid tests" begin
    fnums = Tuple([UInt16(i) for i = 1:7])
    rng = typemax(UInt16)
    fid = Fae.create_fid(fnums, rng)

    @test bitstring(UInt16(fid)) == "0000101100011001"

    probs = (1,
             1/2, 1/2,
             1/3, 1/3, 1/3, 
             1/4, 1/4, 1/4, 1/4,
             1/5, 1/5, 1/5, 1/5, 1/5, 
             1/6, 1/6, 1/6, 1/6, 1/6, 1/6,
             1/7, 1/7, 1/7, 1/7, 1/7, 1/7, 1/7)

    fid_2 = Fae.create_fid(probs, fnums, rng)

    offset = 0
    for i = 1:length(fnums)
        choice = Fae.decode_fid(fid, offset, fnums[i])
        if i in (1,2,4)
            @test choice == i
        else
            @test choice != i
        end

        choice_2 = Fae.decode_fid(rng, offset, fnums[i])

        @test choice_2 == 2^(ceil(log2(fnums[i])))

        choice_3 = Fae.decode_fid(fid_2, offset, fnums[i])
        @test choice_3 <= i

        offset += ceil(Int, log2(fnums[i]))
    end


end
