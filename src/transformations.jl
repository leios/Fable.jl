# Note: we needed to implement our own vector / matrix multiply per row
#       because the GPU does not allow for creating an ad-hoc vector for A*v
@kernel function affine_kernel!(positions, A)
    tid = @index(Global, Linear)
    lid = @index(Local, Linear)

    @uniform gs = @groupsize()[1]

    @uniform T = eltype(positions)

    # up to 4 dimensions
    shared_tile = @localmem T (gs,4)

    # Filling shared tile
    for i = 1:size(positions)[2]
        shared_tile[lid,i] = positions[tid,i]
    end

    for i = 1:size(positions)[2]
        temp_sum = T(0)
        for j = 1:size(positions)[2]
            temp_sum += A[i,j]*shared_tile[lid,j]
        end
        temp_sum += A[i,end]
        positions[tid,i] = temp_sum
    end
end

function affine!(positions, A; numcores = 4, numthreads = 256)
     if (size(positions)[2] + 1 != size(A)[1])
         error("Augmented matrix should be 1 dimension higher than points!")
     end

     if isa(positions, Array)
         kernel! = affine_kernel!(CPU(), numcores)
     else
         kernel! = affine_kernel!(CUDADevice(), numthreads)
     end

     kernel!(positions, A, ndrange=size(positions)[1])
end

function affine_rand(;dims = 2, scale = 1)
    rand_set = zeros(dims+1, dims+1)
    rand_set[end, end] = 1
    rand_set[1:dims,:] = rand(dims, dims+1)*scale .- scale*0.5
    return rand_set
end
