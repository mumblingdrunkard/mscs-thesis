= Introduction and Motivation

#quote(
  block: true,
  attribution: [Someone's uncle; we're sure], 
  quotes: auto, 
)[
  With great speculation, comes great speculative execution security vulnerability.
]

The advent of speculative execution vulnerabilities such as Spectre @bib:spectre and Meltdown @bib:meltdown have left us [computer architects] scrambling.
Very fundamental structures, algorithms, and techniques---used in all modern high-performance processors---leave programs vulnerable to attacks that are difficult to mitigate.

It is no big secret that modern processors _speculate_, that they do so often, and with great accuracy.
Speculation improves performance by predicting which work needs to be done, and doing it ahead of time when there is available capacity, delaying the _effects_ of the work until prediction is confirmed to be correct.
If the prediction was incorrect, the work is discarded, and the processor continues doing the correct work.

Effects here refers to changes of architecturally visible state that cannot be reverted.
I.e.: store-instructions that update values in memory.
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

#{
}
