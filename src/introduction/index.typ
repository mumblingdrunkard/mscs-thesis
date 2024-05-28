= Introduction and Motivation

#text(fill: red, [This is all rambling.  Rewrite.])

The advent of speculative execution vulnerabilities has left us [computer architects] scrambling.
Very fundamental techniques---used in all modern high-performance processors---leave programs vulnerable to attacks that are difficult to mitigate @bib:spectre @bib:meltdown.

A program is a series of instructions.
Instructions have dependencies; i.e.: instructions can depend on the result of previously executed instructions.
However, it is unusual that an instruction depends on all previous instructions, either directly or transitively.
Because of this, a processor can execute multiple instructions at the same time, provided they all have their dependencies fulfilled.

A normal program also contains a high number of _branches_ where the flow of execution can change.
A branch instruction has a condition and a target instruction in the program.
If the condition is fulfilled, the processor jumps to the target instruction.
Otherwise, the branch instruction has no effect and is ignored.

The nature of a branch is such that all later instructions depend on it.
Some instructions are slow to perform.
If a branch depends on the result of a slow instruction, the processor is likely to stall.

This is why processors _speculate_; they do so often, and with great accuracy.
Speculation improves performance by predicting which work needs to be done, and doing it ahead of time when there is available capacity.
The most well-known form of speculation is branch-prediction.
Branch-prediction bases itself on the observation that branches in programs are predictable.
A prediction from a branch predictor is a guess for what the result of the branch will be: taken or not taken.
The processor continues on the path of execution as if the branch had the predicted result.
The _effects_ of the work are delayed until the prediction is confirmed to be correct.
If the prediction was incorrect, the work is discarded, and the processor continues doing the correct work.

Effects here refers to changes of architecturally visible state that cannot be reverted.
I.e.: instructions that update values in memory.
Most other instructions are up for grabs during speculation.
This is enabled, in part, by _register renaming_ which breaks false dependencies, and also enables undoing many instructions.

Processors use _caches_ to provide fast responses to memory requests.
Caches exploit the fact that most programs exhibit _locality_.
Locality is the tendency for things to clump together in time and space.
The address of a memory request is 1) likely to lie close to previously requested addresses (_spatial_ locality), and 2) an address is more likely to be requested if it was recently requested (_temporal_ locality).

Caches are arranged in hierarchies of memories, with small, fast memories closer to the processor, and larger, slow memories placed further from the processor.
Caches are necessary for modern processors to perform well, as requests to main memory can take hundreds of cycles.
The fastest caches respond to requests in a few cycles, while the slowest caches can take upwards of fifty cycles or more.

Cache is a sort of _non-architectural_ state.
This means that a normal program cannot discern whether some data came from cache or if it had to go all the way to main memory.
There are no instructions that specifically affect the cache, and the caching implementation is not regulated by the instruction set architecture of the platform besides having to ensure correct operation.
Caching is purely an optimisation.

However, programs can determine---or at least guess---the state of caches.
A process can quite freely determine how long a specific memory request takes and can do so accurately.

== Motivation

== Structure of This Document

=== Background Chapters

Chapters @ch:comp.arch.-fundamentals

=== Content Chapters

=== Accessibility and Navigation

#{
}

Notes:

- !Pedagogisk stemme - fy fy
  - Presis ordbruk og konseptforklaring
  - Bruker nøyaktig terminologi
- !Lite skrevet
  - Mye tid på ting som ikke er viktig for selve oppgaven
- Generell akademisk tekst
  - Abstract - brief
  - Introduction - summary
  - Background - problemet
    - Speculative Execution Attacks
    - Prevention
    - Regaining MLP
  - Background+ - motivasjon
  - Framework
  - Methodology
  - Results
  - Discussion
  - Future Work
  - Conclusion
