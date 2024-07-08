= Introduction and Motivation

While more and more compute-intensive applications have been moved to massively parallel processors such as graphics processors or using vector processing extensions in normal processors, some applications are inherently single-threaded for large computations.

Even with fundamentally single-threaded applications, there is likely to be a lot of work that can be performed in parallel, but with a granularity that is too small to split across multiple processors without peformance decimating overhead.
For these applications, i

This is especially important with parallelism in regards to memory instructions.
Instructions that access memory commonly have substantially higher latencies than other instruction types.
This can be mitigated by 

At the time of writing, speculative execution vulnerabilities have been a fact for over half a decade.
This has necessitated new approaches to designing hardware and software.
Various mitigations have been employed, but instead of being one simple, easy-to-fix issue, speculative execution presents a whole class of vulnerabilities.

== Motivation

== Structure of This Document

=== Background Chapters

=== Content Chapters

=== Accessibility and Navigation
