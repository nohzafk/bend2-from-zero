# Summary

[Introduction](intro.md)

# Before you start

- [What Bend 2 is, and why this book](what-is-bend.md)
- [Getting set up](setup.md)

# The language

- [A first program](basics-hello.md)
- [Numbers and patterns](basics-numbers.md)
- [Lists](basics-lists.md)
- [Strings and characters](basics-strings.md)

# The idea that changes everything

- [Affine values: everything is used at most once](affinity.md)
- [Copies, kinds, and the `+` mark](kinds-and-copies.md)
- [Arrays: a read hands you a pair](arrays.md)

# Making it fast

- [Parallel by default: fork-join](parallel.md)
- [The GPU, and the `!` mark](gpu.md)
- [When the GPU loses: n-queens](gpu-queens.md)
- [When the GPU wins: mandelbrot](gpu-mandelbrot.md)

# Worked example: Conway's Life

- [Life the obvious way, and the trap in it](life-naive.md)
- [Life in O(n), by rows](life-rows.md)
- [Is it actually parallel?](life-parallel.md)
- [Making it move](life-anim.md)

# Effects: the world outside

- [Effects, and the event loop](effects.md)
- [Writing an effect](effects-2.md)

# Laws: turning a belief into a compiler check

- [Your first law and proof](laws-1.md)
- [A second law, and the wall underneath](laws-2.md)
- [The gate, and its edges](laws-3.md)

# Appendices

- [Every deliberately-broken probe, and the error it produces](appendix-probes.md)
- [Every number in this book, and how it was measured](appendix-measurements.md)
- [What Base does not give you](appendix-base-gaps.md)
