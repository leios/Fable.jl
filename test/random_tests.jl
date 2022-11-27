#------------------------------------------------------------------------------#
# Test Definitions
#------------------------------------------------------------------------------#

@kernel function random_test_kernel!(a)
    tid = @index(Global, Linear)

    a[tid] = Fae.simple_rand(tid)
end

function random_test!(a; numcores = 4, numthreads = 256)

    if isa(a, Array)
        kernel! = random_test_kernel!(CPU(), numcores)
    elseif isa(a, CuArray)
        kernel! = random_test_kernel!(CUDADevice(), numthreads)
    elseif isa(a, ROCArray)
        kernel! = random_test_kernel!(ROCDevice(), numthreads)
    end

    kernel!(a, ndrange = length(a))
end

function LCG_tests(ArrayType::Type{AT}) where AT <: AbstractArray

    a = ArrayType(zeros(1024,1024))

    threshold = 0.00001

    wait(random_test!(a))

    a ./= typemax(UInt)

    avg = sum(a)/length(a)

    @test abs(avg-0.5) < threshold

end

function fid_tests()
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

#------------------------------------------------------------------------------#
# Testsuite Definition
#------------------------------------------------------------------------------#

function random_testsuite(ArrayType::Type{AT}) where AT <: AbstractArray

    if ArrayType <: Array
        @testset "fid tests" begin
            fid_tests()
        end
    end

    @testset "LCG tests for $(string(ArrayType))s" begin
        LCG_tests(ArrayType)
    end
end
