= Computer Architecture Fundamentals <ch:computer-architecture-fundamentals>

By the nature of the genre (master's theses), this text is targeted at those graduating from a programme in computer science or similar.
// Let $A$ be the set of all computer science students, and $B$ be the set of all computer science students that specialise in computer architecture.
// Supposedly, $A != B$.
// That is to say: there are computer science students that do not study computer architecture; or in mathematical terms: $B #math.subset.neq A$ ($B$ is a proper subset of $A$).

The goal of this chapter is to equip the reader with foundational knowledge required to understand the discussions within this thesis and to establish common terminology.
In the first section, we bridge the gap between abstractions and implementations and cover how a processor is created using constructions of transistors.
The next section covers _pipelining_, a design approach that increases the performance of processors by passing work down a pipeline almost like an assembly line where each stage adds a new part.
@sec:scaling-up shows how processor performance can be increased and how a processor can be modified to break the barrier of completing more than one instruction at a time.
Next follows a short coverage of memory and related terminology.
Lastly, we cover how a modern, high-performance processor tackles this complexity by using a different philosophy entirely.

#include "./abstractions-and-implementations.typ"
#include "./anatomy-of-an-in-order-pipelined-processor.typ"
#include "./scaling-up.typ"
#include "./memory-and-caching.typ"
#include "./high-performance-processor-architecture.typ"
#include "./reduced-vs-complex-instruction-set-computers.typ"
