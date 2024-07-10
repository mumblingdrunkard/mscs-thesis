= Abstract

Processors are sometimes tasked with handling sensitive cryptographic algorithms or other applications that access and manipulate secret values.
Programmers have long been aware of side-channel attacks and several techniques exist to write programs that are resistant to such attacks.
Then Specre and Meltdown happened; speculative execution vulnerabilities that are unique to out-of-order systems.
Most of the research and reasoning around security before then was based around simple side-channels and was only applied in contexts handling secrets.
The danger of Spectre-like attacks is that they can use code that never handles secrets during correct execution (thus not needing secure programming standards) and make the processor access those secrets anyway.

Out-of-order processors make predictions about future execution and speculatively perform that work.
If the prediction is correct, the work is kept and the processor keeps going.
In the case of an incorrect prediction, the work must be squashed and the state rolled back.
The nature of out-of-order execution allows for mispredicted, transient execution to leave behind traces in microarchitectural state.
During transient execution, rules can be broken, such as array accesses going out of bounds.

Speculative execution attacks force the processor to mis-speculate and perform actions that access and transmit secret values for a malicious application to recover.

Schemes have been proposed to prevent speculative execution attacks by limiting when and how microarchitectural state such as caches may be updated.
All of these schemes reduce performance.
Much of this reduced performance is due to a loss of memory level parallelism as these schemes invariably limit when and how load instructions are allowed to issue to prevent updates to the cache hierarchy.

Doppelganger loads is a proposed technique to regain some of this parallelism by using safely predicted addresses instead of potentially speculatively loaded values.
A copy of the load instruction is issued to the data cache and the result is written back to the register file, but is not propagated until the address is confirmed and propagation is allowed by the underlying scheme.
This copy, called a doppelganger, stands in for the real load while the address is unavailable or the real load is still considered unsafe.
Doppelganger loads are a safe and cheap optimisation on top of these schemes, requiring few modifications to a standard out-of-order core design.
Doppelgangers were originally tested in a cycle-accurate simulator, which is a widely accepted approach to research.

Simulators hide much of the complexity of working with real hardware.
In this report, we present our work to integrate doppelganger loads in the Berkeley out-of-order machine, an open source out-of-order RISC-V core design.
We show: that a simple strided predictor is able to detect strides in accessed addresses, we are able to generate predictions and issue loads to the data cache using these addresses, compare the prediction once the real address arrives, and write back the result to the register file.

There are challenges related to superscalar processing of instructions which we handle with a novel approach developed in a previous project.
We also discuss various other challenges that arise with our specific implementation.

We show how the implementation slightly succeeds in improving performance over an intentionally slowed down, insecure baseline as well as various other statistics collected for the predictor and the predictions made.
