# FFlamify.jl
Fractal Flame implementation in Julia (https://flam3.com/flame_draves.pdf)

## Notes on what to do:
1. Transitions between objects
2. How to fractalize an existing object

### Notes on fractal operators
1. Create an addition function to add operators to existing Hutchinson ops
2. Create a simple method to add fis
3. allow for arrays when configuring fos
4. Add better defaults for creating custom hutchinson ops

### Notes on Audio visualization
1. We can plot frequencies with FFT
    a. what window function should we use: https://en.wikipedia.org/wiki/Window_function#Hann_and_Hamming_windows
    b. Should we use Goertzel: https://en.wikipedia.org/wiki/Goertzel_algorithm
2. In visualization of frequencies, resonance is structural and can be found by sweeping through all notes: https://boomspeaker.com/speaker-resonant-frequency/#Free_Air_Resonance
3. pitch analysis -> visual
