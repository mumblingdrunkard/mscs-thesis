#import "../utils/utils.typ": *

== High-Performance Processor Architecture <sec:high-performance-processor-architecture>

With the basics covered, we can move on to the state of the art of processing:
out-of-order (OoO) processors.
In-order (InO) processors execute instructions in program order and later instructions cannot start until earlier instructions have progressed past some point, even if their dependencies are ready.
OoO processors attempt to exploit all available ILP by executing multiple instructions in parallel, allowing instructions to execute as soon as their dependencies are resolved.

Later instructions can complete before earlier ones.
For example, a load instruction that misses in the L1d may not finish for several tens of cycles.
Instructions that are not dependent on that load instruction can progress as normal and finish before it; i.e.: out-of-order.

=== Available Instruction-Level Parallelism

We should specify what we mean when we say that there is available ILP even when the parallelisation of a program across many cores is difficult or impossible.
Any program, can be represented as a graph where later instructions can depend on earlier instructions, but they do not depend on all of them.
There are different types of dependencies, of which only one kind is really important in modern OoO processors.

==== Read-After-Write Dependencies

_Read-after-write_ (RAW) dependencies arise when an instruction depends on the result of a previous instruction.
I.e.: when an earlier instruction writes to a register and a later instruction uses the result as one of its operands.
These are termed _true dependencies_.

==== Write-After-Write and Write-After-Read Dependencies

The two other types of dependencies are _write-after-write_ (WAW) and _write-after-read_ (WAR).
These are termed _false dependencies_ and arise when a later instruction writes to a register that is used---read, or written---by an earlier instruction.
Naively allowing the later instruction to execute first would leave the value in the register mangled as the earlier value would eventually overwrite the later value, or the earlier instruction would use a value produced by a later instruction.

=== A High-Level Overview

@fig:ooo-architecture shows a high-level overview of the various pieces that go into an OoO processor.

#figure(
  ```monosketch
                   ┌────────┬───┐        
                   │        │ROB├───────┐
                   │   ┌────▶──▲┘       │
                   │ ┌ ┼ ─ ─ ─ ┼ ─ ─ ─ ┐│
  ┌──┐ ┌──┐ ┌──┐ ┌─▼┐  │┌──┐ ┌─┴┐ ┌───┐ │
  │I$├─▶IF├─▶ID├─▶RR├┼─┴▶IQ├─▶FU◀─▶MEM│││
  └──┘ └─▲┘ └──┘ └──┘   └─▲┘ └┬┬┘ └───┘ │
         └───────────┼────┼───┘│       ││
                          │  ┌─▼─┐      │
                     │    └──┤PRF◀─────┼┘
                             └───┘       
                     └ ─ ─ ─ ─ ─ ─ ─ ─ ┘ 
                        Out-of-order
  ```,
  caption: [High-level overview of an out-of-order processor architecture],
  kind: image,
)<fig:ooo-architecture>

The different parts are 
- the instruction-cache `I$`, 
- instruction fetch `IF` and instruction decode `ID` as seen earlier,
- register-rename `RR`,
- issue-queue `IQ`,
- re-order buffer `ROB`,
- functional units `FU`,
- physical register file `PRF`, and
- the memory `MEM`.

The various components are described in more detail further on.
This overview hides a lot of complexity---especially in the FUs.
One important FU is the unit for managing memory accesses.

=== Register Renaming

_Register renaming_ (RR) is an important piece of the puzzle that enables OoO execution.
Register renaming removes false dependencies from the instruction stream by using a new physical location each time an instruction would write to a register.

Register renaming uses a _physical register file_ (PRF) that is different from the register file defined by the ISA.
The registers defined by the ISA are called _architectural registers_ and the register file is the _architectural register file_ (ARF).
Every time an instruction enters the processor and is going to write to some target architectural register, the instruction is given an unused physical register that it should write to instead.
Later instructions that read from that same architectural register will similarly read from the physical register that was assigned earlier.

The status of registers in the PRF can be used or unused, and the value within the register can be ready or not ready.
If two instructions $a$ and $b$ write to the same architectural register, they each receive a physical register to write to instead.
The physical register destination of $a$ can be _released_ (set to unused) when no more instructions between $a$ and $b$ depend on the result from $a$.
Intuitively, no instructions after $b$ can depend on the result of $a$ as $b$ overwrites the value in the architectural register.

The PRF must be at least as large as the ARF plus one to ensure the entire architectural state can be tracked at any time and that there is at least one unused physical register to map an incoming architectural register to.
Often, the PRF is several times larger than the ARF, depending on how many instructions can be tracked at once.

=== Frontend, Backend, and Commit

OoO processors are usually discussed in terms of an InO _frontend_ that fetches instructions, decodes them, renames the architectural registers, and dispatches them to the OoO _backend_ as uOPs.

The backend consists of one or more IQs, FUs, the PRF, and the ROB.
The ROB contains the instructions/uOPs in the order they entered the frontend.
The IQs contain _slots_ in which the uOPs wait.
For example, the physical registers that a uOP depends upon may not yet have its value written; the value is not ready.
The job of the IQ slot is to wait for the dependencies to become ready, possibly fetching and storing the values temporarily.
When all dependencies are available, the uOP is ready to be _issued_ (sent) to one or more appropriate FUs.

There are several FUs in an OoO processor just like there are in an InO processor.
The difference is that FUs in InO processors are all in the same stage and thus cannot be utilised in the same cycle.
Thus, most of the FUs in an InO processor go unused for most of the cycles.
There may multiple ALU-like units containing various circuits for performing arithmetic.
There may be _address generation units_ (AGU) whose sole purpose is to calculate the addresses used by memory operations.

FUs can produce results instantly (in the same cycle), or they can take many cycles for a single uOP.
FUs that take many cycles may re-use the same inner parts in multiple of the cycles, meaning the FU cannot process more than one uOP at a time, or it may itself be pipelined, using new components in each cycle.

When FUs produce results, the results may be passed on to other units for further processing, or they may be completed, in which case they are written back to the PRF and the corresponding entry in the ROB is marked as completed.

The ROB has a _head-_ and a _tail_-end.
uOPs enter the ROB at the tail-end.
As uOPs at the head-end finish, they _commit_ and the head moves toward the tail.
When instructions commit, the 
It is only after committing that instructions are truly reflected in the architectural state.
Commit happens in-order because the ROB is in-order.
Up until that point, their results may be _rolled back_ (undone), which can be necessary in the case of exceptions or mispredictions.
In practice, the ROB is implemented as a circular buffer.

=== Memory Access Unit

As mentioned, the FU for accessing memory is hidden in the high-level overview of @fig:ooo-architecture.
This unit will usually manage structures like the L1d and the _translation look-aside buffer_ (TLB).
The TLB is responsible for translating virtual addresses to physical addresses.
It is essentially a small cache for address translations.
The tables used for translation are stored in memory and the processor would need to make additional memory requests for all virtual memory accesses were it not for the TLB.

In addition to these structures, the memory access unit contains structures for tracking requests to the L1d like loads and stores.

=== Unlocking Memory-Level Parallelism

One of the biggest advantages of OoO execution is that it easily unlocks _memory-level parallelism_ (MLP).
As long as memory instructions do not depend on each other's results, they can make progress in parallel.
Properly exploiting MLP requires certain optimisations to the L1d like _hit-under-miss_ which allows later memory instructions to make progress even while the L1d is processing a memory instruction that missed.

==== Latency Hiding

By unlocking and properly exploiting MLP, the apparent latency of memory instructions is reduced.
Even whithout certain optimisations to the L1d, memory instructions can usually start execution earlier than they would be able to in an InO processor, thus reducing their apparent latency.
In large designs, the processor often has enough available work to perform to completely hide the impact of a miss in the L1d.

=== Speculative Execution

Processors rely on branch predictors to keep the frontend from stalling and keep the backend fed with instructions.
Branch instructions may take a lot of time to resolve, for example if they depend on the result of a load instruction that misses in the L1d.

The nature of OoO execution means later instructions will continue executing while waiting for the branch to resolve.
If the prediction turns out to be wrong, the processor state will be rolled back to just after the branch and the frontend will be redirected to the correct path of execution.

All the work between a branch prediction being made and a branch resolving is _speculative_.
When the prediction is incorrect, the speculative work is squashed and is called _transient execution_.
The Merriam-Webster dictionary defines "transient" as "passing especially quickly into and out of existence", which is a fitting description of work that has been performed only to be squashed.

Speculation happens in InO processors too, but as branches are resolved in order, incorrectly fetched instructions do not get to affcet microarchitectural state such as caches.
This is not the case in OoO processors where a load instruction fetched after a speculated branch is allowed to access memory before it is known whether it really is part of proper execution.

=== Performance and Metrics

When discussing the performance of modern processors, there are several important metrics to consider.
The total work performed by a processor is the _instructions per second_ (IPS), commonly given as _millions of instructions per second_ (MIPS).
IPS is a product of the average number of _instructions per cycle_ (IPC) and _cycles per second_ (which is just called the frequency, denoted by Hz).
The inverse of IPC is _cycles per instruction_ (CPI).

Consider that not all instructions are created equal.
An IPS of 1'000'000 in one ISA may not be equivalent to an IPS of 1'000'000 in another ISA if one of them performs less "real work" per instruction.
It is still a useful metric when comparing micro-architectures for the same ISA, but can be misleading when comparing microarchitectures for different ISAs.

Lastly, _performance per watt_ (PPW) and _energy per instruction_ (EPI) are useful metrics.
When operating at the limit of heat dissipation, the only way to improve performance is to do so in tandem with improvements in PPW.

==== Predictions

As we discuss predictions in this thesis, we should cover some of the metrics used when discussing predictors of various sorts.

Various metrics affect the efficacy of cache prefetching such as _accuracy_, _coverage_, and _timeliness_.
Accuracy is the number of useful prefetches compared to the number of performed prefetches.
Coverage is the fraction of misses that instead become hits due to prefetching.
Timeliness is a metric that says something about the usefulness of the data that are prefetched.
If a prefetch request goes out too late, the next request may come in before the data are fully in cache.

Timeliness is a yes-or-no answer, while accuracy and coverage are metrics with tradeoffs.
Issuing more prefetches when the prediction is uncertain but there is available capacity may increase coverage at the cost of reducing accuracy and wasting more power.
Issuing more prefetches might also have the adverse effect of reducing performance by taking up limited bandwidth, or it might cause useful data to be _evicted_ (pushed out) from the cache to make space for prefetched data that aren't useful.

Branch predictors have an accuracy measurement which is the ratio of correct predictions to the number of branch instructions fetched.
Branch predictors do not have coverage as they have to cover 100% of branches, lest fetching stall completely.
When branch predictors fail to make predictions using advanced algorithms, they fall back on heuristics like "always jump" or "never jump" based on good guesses about how normal programs are written #footnote[ Branches that jump back in the program are associated with loops and are usually always taken in the first few iterations. ].

Whether branch predictors can be "timely" in the same manner is perhaps up for debate.
When fetching multiple instructions per cycle, a branch prediction can be "late" without affecting performance as long as the processor is not completing instrucitons faster than they can be fetched.
In fact, processors will commonly have several branch predictors where a fast predictor redirects instruction fetch quickly.
If a more accurate but slower predictor later disagrees with the prediction, instruction fetch is redirected to use the higher accuraly prediction.
