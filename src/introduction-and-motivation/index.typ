= Introduction and Motivation

While more and more compute-intensive applications have been moved to massively parallel processors such as graphics processors or using vector processing extensions in normal processors, some applications are inherently single-threaded for large computations.

Even with fundamentally single-threaded applications, there is likely a lot of work that can be performed in parallel, but with a granularity that is too fine-grained to split across multiple processors without performance-decimating overhead.
Modern processors handle instructions out of order.
As instructions enter the processor, newer instructions may complete before older ones if their dependencies are ready or they have lower latencies.
This allows for maximally exploiting the available parallelism in a program as the processor is allowed to make progress as soon as the dependencies are ready.
Contrasted with a processor that does all the work in order, out-of-order processors can be multiple times faster for the same applications.

Certain instructions have long latencies such as memory accesses that miss in caches.
When branches depend on these long-latency instructions, the processor is likely to run out of work to do before the branch is fully resolved because it is unknown which instructions to start fetching next.

Because of this, processors _speculate_, making predictions about which way a branch is going to resolve and where execution should be directed.
When the guess is correct, this makes a lot of work available to the processor, increasing the chances of finding work that can be performed in parallel.
If a prediction is wrong, the processor can potentially perform a lot of unnecessary work before the guess is determined to be wrong.
This work has to be _squashed_ and the state of the processor is rolled back and it continues executing along the correct path.

The squashed work is referred to as _transient execution_ and it is not observable from an architectural perspective.
However, transient execution may leave traces in microarchitectural state---state that is not normally visible.
By using knowledge about the microarchitecture and code running on the processor, it is possible to inspect microarchitectural state through various techniques to make inferences about previous execution that has taken place, transient or not.

The mechanisms of microarchitectural state combined with ways to inspect it forms a _side-channel_ that potentially leaks sensitive information during execution which malicious applications can observe.
Exploiting these mechanisms gives rise to a side-channel attack.

On in-order processors, where instructions are executed in order and instructions after a branch are not allowed to change microarchitectural state until the branch is resolved, programmers have some control over what is leaked through a side-channel.
In out-of-order systems, this control is gone and applications are at the mercy of the branch predictor if the program contains leaky paths of execution that should not be entered.
Worse yet, because the state of the branch predictor is shared between multiple applications in the system a malicious application can intentionally train the branch predictor in a way that it causes the processor to enter a leaky path in a victim application.
This is known as a _speculative execution attack_.

At the time of writing, speculative execution vulnerabilities have been a fact for at least half a decade, made widely known by papers on Spectre @bib:spectre and Meltdown @bib:meltdown.
This has necessitated new approaches to designing hardware and software.
Various mitigations have been employed, but instead of being one simple, easy-to-fix issue, speculative execution presents a whole class of vulnerabilities that rely on various speculation mechanisms and side-channels.

The most popular side-channel and the one used in attack demonstrations is the cache side-channel where the cache hierarchy is updated during transient execution.
By timing accesses to memory, a malicious application can determine which addresses were accessed during transient execution and in this way infer information that would not be visible in an in-order processor.

Mitigations focus on blocking various side-channels by delaying the effects of speculative execution on microarchitectural state until the execution is confirmed to be non-speculative.
This is achieved by a few different techniques where the strictest approaches may delay all dependent execution until the data that are used are confirmed to be used in a non-speculative manner.
These approaches only seek to make execution appear similar to in-order execution from the perspective of various side-channels, meaning a program that is leaky on an in-order processor will still be leaky in an out-of-order processor with these mitigations applied.
This is generally regarded as an acceptable solution.

Developing a mitigation starts with analysing the problem space by determining which values are potentially secret and where they are located.
Generally, secrets are considered to reside either in both registers and in memory, or just in memory.
Said in a different way: all values in memory are potentially secret and must be protected.
Some models consider values that are already loaded from memory (and thus are placed in registers) to still be secrets, others do not.

The different mitigations generally lead to a performance loss of 10-20%.
Much of this performance loss is due to the loss of parallelism for memory instructions.
Memory instructions access the memory hierarchy and may thus modify the cache hierarchy, leaking information about the accessed address.

Kvalsvik et al. observed that a considerable amount of this parallelism can be regained by making predictions for accessed addresses and performing the loads ahead of time @bib:doppelganger.
To ensure this is safe, the predictions are only made based on committed load instructions such that the predictor can only reveal previously known non-speculative execution.
When load instructions depend on values that are determined to be secrets, the predicted address can be safely used instead as it only reveals past execution.
If the prediction is correct, the access does not need to be performed again and the apparent access latency is reduced.
If the prediction is incorrect, the stand-in load is ignored.
These stand-in loads are dubbed "doppelganger loads" or just "doppelgangers".

Doppelganger loads are shown to be a cheap and safe optimisation on top of these mitigations.
A doppelganger can re-use many of the resources of a normal out-of-order architecture used by traditional loads, its needs never overlapping with those of the real load.
In fact, the only considerable hardware cost of doppelgangers presented in the original paper is that of the predictor itself.

== Motivation

Doppelganger loads have been implemented in a cycle-accurate simulator.
Simulators are useful tools for computer architecture researchers as they allow for rapid prototyping and testing of high-level concepts without worrying about low-level implementation details such as port counts, wiring contenion, and other problems that pop up during physical design besides the arduous process of implementing and debugging real hardware itself.
Simulations showed promising results.

Once simulation is complete and the concept shows promise, however, it is useful to implement it as a real circuit to uncover and tackle the specific challenges that arise.

This is the goal of this project, to implement doppelganger loads in hardware, basing our implementation on an open source out-of-order processor design.

== Contribution

In this report, we describe our implementation process for doppelganger loads and various challenges that arise during implementation in the specific design.
We describe challenges specific to superscalar architectures and the techniques we have applied to alleviate these issues.

We have collected performance statistics for the final implementation for both the processor itself and statistics specific to only the predictor.
We also show that there is room for a more complex predictor than the one implemented here as very few predictions are compared to their real address counterpart before many cycles later.

Because of the low access latency of the first-level cache in the base processor implementation, doppelganger loads struggle to compete with techniques such as speculative waking of dependents when a load result is expected.
We collected statistics for various configurations of the processor with and without doppelganger loads enabled and we show that doppelganger loads were able to achieve fair performance improvements when compared to a baseline that did not perform speculative wakeups, although not as good as simply performing the speculative wakeups.

As we have implemented doppelganger loads without any of the mitigations applied, our results are in line with the observations made in @bib:doppelganger where doppelganger loads at most increased performance by around .5%.

Finally, we present various discussion around the results and implementation.
We present known flaws of our implementation and recommendations for how to fix them.
We also present future work that should be done for a complete implementation and various tests that should be run once implementation is done.

== Structure of This Report

This report is filled with a considerable amount of background information that is required to understand the work performed.

=== Background Chapters

@ch:computer-architecture-fundamentals presents foundational knowledge for computer architecture and serves to build up a shared understanding of the concepts and terminology.
Readers already familiar with the field will likely already be familiar with most of the terminology presented in this chapter.

@ch:modern-hardware-design describes the process of designing hardware with modern techniques and some of the challenges faced when going from the high-level descriptions of circuits to actual physical implementation.

In @ch:boom we present the open source out-of-order processor design that we implement our predictor in as well as various tools we have used during development.

@ch:processor-security gives a more detailed description of the problem of speculative execution vulnerabilities and the possible mitigations.

@ch:doppelganger is a similarly detailed description of doppelganger loads and special considerations that have to be made for the technique to remain safe under the assumptions of security models that form the bases of the aforementioned mitigations.

=== Content Chapters

@ch:architecture-and-implementation describes our process with implementing doppelganger loads and various challenges associated with it.

In @ch:methodology-and-results we describe how we have gathered results for the final implementation, which statistics we recovered, and present various tables that show the impact of the implemented technique.

@ch:discussion contains involved discussion and reflection on the results, implementation, and lays out future work that should be done.

Finally, @ch:conclusion concludes the report.

=== Accessibility and Navigation

This document contains a considerable number of links.
The glossary contains a list of acronyms with references to each page where they are used.
Acronyms where they appear in the text also link back to their entry in the glossary.

Besides the glossary, there are lists for figures, tables, and listings (code blocks).
Entries in these lists link to their position in the text.
In-text references to figures, tables, and listings are made in *bold* text.
