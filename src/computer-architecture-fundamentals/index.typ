= Computer Architecture Fundamentals <ch:comp.arch.-fundamentals>

By the nature of the genre (master's theses), this text is targeted at those graduating from a programme in computer science or similar.
Let $A$ be the set of all computer science students, and $B$ be the set of all computer science students that specialise in computer architecture.
Supposedly, $A != B$.
That is to say: there are computer science students that do not study computer architecture; or in mathematical terms: $B #math.subset.neq A$ ($B$ is a proper subset of $A$).

The goal of this chapter is to equip the reader with foundational knowledge required to understand the discussions within this thesis and to establish common terminology.
In the first section, we bridge the gap between abstractions and implementations and cover how a processor is created using constructions of transistors.
The next section covers a different, more optimised implementation of a processor that doesn't change the interface of the processor, but achieves greater performance by using a different philosophy for execution, called _pipelining_.
@sec:scaling-up shows how processor performance can be increased and how a processor might break the barrier of completing more than one instruction at a time.
Next follows a short coverage of memory and related terminology.
Lastly, we cover how a modern, high-performance processor tackles this complexity by using a different philosophy entirely.

#{
  include "./abstractions-and-implementations.typ"
  include "./anatomy-of-an-in-order-pipelined-processor.typ"
  include "./scaling-up.typ"
  include "./memory-and-caching.typ"
  include "./high-performance-processor-architecture.typ"
}
