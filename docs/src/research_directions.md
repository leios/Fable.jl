# Research Directions

Fae.jl is an open research project with the goal of creating a new, general purpose rendering engine based on [Iterated Function Systems](https://www.algorithm-archive.org/contents/IFS/IFS.html) (IFS).

Here is a quick list of various research directions for the project:

## Performance
Right now, Fae is using a naive chaos game kernel for all visualizations.
It would be interesting to explore higher-performance methods for this.
In addition, object rendering is currently done layer-by-layer and it would be interesting to be able to render multiple objects with the same IFS.
[Relevant issue](https://github.com/leios/Fae.jl/issues/2).

## Generalizations
Right now, all fractals are made by first starting with a set of equations and then drawing those equations, but it would be interesting to explore the other direction.
If the kernels are performant enough, we can do multiple IFS iterations and use some form of optimal control to dynamically learn equations from an input image.
This would mean we could essentially turn any image into a fractal, similar to fractal compression.
[Relevant Issue](https://github.com/leios/Fae.jl/issues/4).

## Synergy with other rendering methods
There are still advantages to using raytracing, raymarching, or rasterization, but performing clear analyses between the methods and using them together to create a general-purpose rendering library would be an interesting direction.

If you are at all interested in helping with this project, please start discussions on the relevant issues or otherwise create a new one!
