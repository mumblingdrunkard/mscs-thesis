= Conclusion <ch:conclusion>

In this project, we have made progress towards implementing doppelganger loads in synthesisable hardware.
We have uncovered multiple challenges that arise and require solving and we have solved some of them while giving approachable starting points for solving others.

We have provided a background that introduces foundational computer architecture and terminology and modern hardware development processes and tools.
We have then described the basis for our implementation---the Berkeley out-of-order machine, before outlining the problems presented by speculative execution and their mitigations and then the optimisation that is doppelganger loads.

We have then detailed our implementation in high-level terms and described how our changes integrate into the processor and which adaptations we have made that are specific to our implementation, such as making predictions on physical addresses instead of virtual ones.

We have then described our process for gathering results and we show those results.
We have then discussed the results and provided some interpretation for how they may come to be.
Especially interesting are the accuracy results for tight-loop programs.

We have then provided discussion of various problems that arose with our implementation and we have outlined the future work that should be done to implement, test, verify, and improve the design.

Despite challenges with implementation, few of these are inherently with the technique of doppelganger loads and more with lacking familiarity with the BOOM project, the Chisel library, and the Scala language.
A higher degree of proficiency in all of these would likely have allowed us to implement doppelganger loads more accurately and faster without as many problems.

The arguably half-baked implementation has still yielded results that show some promise for further implementation in combination with secure speculation schemes, though the technique is a likely dead-end for improving performance over a baseline when compared to something like speculative load wakeups.
This seems mostly to be caused by the fact that doppelganger loads are unable to wake up dependents any faster after the address has been confirmed as opposed to using speculative load wakeups.
Still, with doppelgangers that are allowed to miss and deeper cache access pipelines, this picture might shift significantly, but the implementation became too tedious for us to test these.

We conclude that doppelganger loads is a feasible generalised technique in terms of hardware implementation and the proposed design has few or no obvious oversights that are not simple to adapt to the specific solution.
It is only a matter of trade-offs at the hardware level.
