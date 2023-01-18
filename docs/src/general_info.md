# General Information

The current Fae.jl API is still in active development, but for those wanting to learn about how to use it, there are several [examples available to learn from](https://github.com/leios/Fae.jl/tree/main/examples).
Though Fae.jl focuses on creating general-purpose animations with *fractals*, other rendering modes are either supported or planned to be implemented in the future.
For now, the only available rendering modes are:
* **Hutchinson operators:** These are used to describe Iterated Function Systems and are the primary focus of Fae.jl
* **Colors:** This mode is somewhat trivial and will just create a layer of a specified color
* **Shaders:** This mode leverages the framework used to describe IFSs to color an image with some user-provided equation.

We would like to support rendering via raytracing, raymarching, and rasterization in the future for those who wish to use such features.
If you would like to learn how to use any of the existing rendering modes, please look at [the layering section of our documentation](layering.md).

## What are Iterated Function Systems?

We plan to put more information in the docs, but there is a great article already describing them in the [Algorithm Archive](https://www.algorithm-archive.org/contents/IFS/IFS.html).
For now, please go there for more information

## General Fae.jl workflow

Fae.jl is generally structured around building a Fractal Executable (`fee`).
In the case you want to use the fractal rendering mode, this `fee` will be a function system, so for a Sierpinski Triangle, it would look like this:

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

I am intending to write more docs here, but check out the examples for more information on specifically how to use these.
