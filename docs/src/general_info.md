# General Information

The current Fae.jl API is designed such that the use can write down any set of equations to be dispatched onto either their GPU or CPU depending on available hardware.
Note that the API is still unstable and subject to change, but there are several general guiding principles we follow that should not be changing in the near future.
There are (of course) a few caveats:

### Limited Support for AMD GPUs
The naive chaos game kernel used for rendering is currently not working on AMD GPUs.
This is because it heavily relies on histogram calculations that require atomic operations.
These operations are available in KernelAbstractions through the Atomix.jl package; however, that package has some smallscale issues with GPU computation.
As such, I am currently using another branch for atomic operations slightly independent of KernelAbstractions.
Relevant information:
    * [Current working branch](https://github.com/leios/KernelAbstractions.jl/tree/atomic_attempts_3) and it's [PR in KernelAbstractions](https://github.com/JuliaGPU/KernelAbstractions.jl/pull/306)
    * [Duscussion of Atomix support in KA](https://github.com/JuliaGPU/KernelAbstractions.jl/pull/308)
For the short-term, this means that to get Fae.jl to run, you might need to use the following commands:
```
] add https://github.com/leios/KernelAbstractions.jl#atomic_attempts_3
] add https://github.com/leios/KernelAbstractions.jl:lib/CUDAKernels#atomic_attempts_3
```
or check out the package locally and use the `] dev` command on it's new location.

If you would like to work on this, please go to the discussion of Atomix support in KernelAbstractions and help out!

### Restricted IFSs are not supported

The goal of Fae.jl is to allow any user to express whatever IFS they want to solve and then dispatch those equations to the GPU / CPU for solving.
There is one caveat here in that we currently do not have a way to express restricted chaos games or restricted IFSs.
That is to say we do not have a way to syntactically express equation dependencies.
For example, we cannot allow one function will act differently depending on the last function chosen.
