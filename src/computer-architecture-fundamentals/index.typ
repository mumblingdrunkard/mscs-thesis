= Computer Architecture Fundamentals <ch:comp.arch.-fundamentals>

By the nature of the genre (master's theses), this text is targeted at those graduating from a programme in computer science or similar.
Let $A$ be the set of all computer science students, and $B$ be the set of all computer science students that specialise in computer architecture.
Supposedly, $A != B$.
That is to say: there are computer science students that do not study computer architecture; or in mathematical terms: $B #math.subset.neq A$ ($B$ is a proper subset of $A$).

The goal of this chapter is to equip the reader with foundational knowledge required to understand the discussions within this thesis and to establish common terminology.

This thesis revolves around _reduced instruction set computers_ (RISC).
Though the history and debate around _complex instruction set computers_ (CISC) vs. RISC is interesting and could contribute to understanding the evolution of processing, we have decided to omit it for brevity. 

#{
  include "./abstractions-and-implementations.typ"
  include "./anatomy-of-an-in-order-pipelined-processor.typ"
  include "./scaling-up.typ"
  include "./memory-and-caching.typ"
  include "./high-performance-processor-architecture.typ"
}


