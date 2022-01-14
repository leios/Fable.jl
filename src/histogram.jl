# This a 1D histogram kernel where the histogramming happens on shmem
@kernel function histogram_kernel!(histogram_output, input,
                                   bounds, bin_width)
    tid = @index(Global, Linear)
    lid = @index(Local, Linear)

    @uniform element_type = eltype(input)

    @uniform warpsize = Int(32)

    @uniform gs = @groupsize()[1]
    @uniform N = length(histogram_output)

    shared_histogram = @localmem Int (gs)

    # This will go through all input elements and assign them to a location in
    # shmem. Note that if there is not enough shem, we create different shmem
    # blocks to write to. For example, if shmem is of size 256, but it's
    # possible to get a value of 312, then we will have 2 separate shmem blocks,
    # one from 1->256, and another from 256->512
    @uniform max_element = 1
    for min_element = 1:gs:N

        # Setting shared_histogram to 0
        @inbounds shared_histogram[lid] = 0
        @synchronize()

        bin = input[tid]
        if element_type <: AbstractFloat
            bin = Int(ceil((input[tid] - bounds[1]) / bin_width) *
                  bin_width + bounds[1])
        end

        max_element = min_element + gs
        if max_element > N
            max_element = N+1
        end

        # Defining bin on shared memory and writing to it if possible
        if bin >= min_element && bin < max_element
            bin -= min_element-1
            atomic_add!(pointer(shared_histogram, bin), Int(1))
        end

        @synchronize()

        if ((lid+min_element-1) <= N)
            atomic_add!(pointer(histogram_output, lid+min_element-1),
                        shared_histogram[lid])
        end

    end

end

function histogram!(histogram_output, input;
                    bounds = [0,length(histogram_output)],
                    bin_width = 1,
                    numcores = 4, numthreads = 256)

    AT = typeof(input)
    if isa(input, Array)
        kernel! = histogram_kernel!(CPU(), numcores)
    else
        kernel! = histogram_kernel!(CUDADevice(), numthreads)
    end

    kernel!(histogram_output, input, AT(bounds), bin_width, ndrange=size(input))
end
