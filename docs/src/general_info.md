# General Information

The current Fae.jl API is designed such that the use can write down any set of equations to be dispatched onto either their GPU or CPU depending on available hardware.
Note that the API is still unstable and subject to change, but there are several general guiding principles we follow that should not be changing in the near future.
There are (of course) a few caveats:

#### Restricted IFSs are not supported

The goal of Fae.jl is to allow any user to express whatever IFS they want to solve and then dispatch those equations to the GPU / CPU for solving.
There is one caveat here in that we currently do not have a way to express restricted chaos games or restricted IFSs.
That is to say we do not have a way to syntactically express equation dependencies.
For example, we cannot allow one function will act differently depending on the last function chosen.

#### Limited AMD GPU support

In principle, Fae can somewhat easily support AMD GPUs.
It should be as simple as providing support for ROCMArrays like we do for CuArrays, but I have not been able to test this.

Ok, with that out of the way, let's talk about the general structure of Fae.jl

## General Fae.jl workflow

Fae.jl is generally structured around building a Fractal Executable, called either a `Hutchinson` operator or (more simply) `fee`.
In general, this is a function system, so for a Sierpinski Triangle, your fee will be something like

```math
\begin{aligned}
f_1(P,A) &= \frac{P+A}{2} \\
f_2(P,B) &= \frac{P+B}{2} \\
f_3(P,C) &= \frac{P+C}{2}.
\end{aligned}
```

Here, $P$ is some point location and $A$, $B$, and $C$ are all vertices of the triangle.
For Fae.jl, each function is called a Fractal Operator (`fo`) and the input variables are Fractal Inputs (`fi`s).
Finally, each function should have some sort of color (or shader) associated with it.
For this reason, we abstracted out the function interface into another operator called a Fractal User Method (`fum`).
So, how do you use Fae.jl?

Well...

* Fee, the fractal executable is the thing you are building
* Fi, the fractal input(s) are the variables needed for your executable
* Fo, the fractal operator is the function you are using in your executable, complete with probability and color or shader information
* Fum, the fractal user method is how users actually create colors and fractal operators.

It's a bit confusing because we had to really rework a lot of the symbolic utilities in Julia so we could do the computation on the GPU.
