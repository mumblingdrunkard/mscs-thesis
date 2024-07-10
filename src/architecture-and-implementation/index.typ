= Architecture and Implementation <ch:architecture-and-implementation>

In this chapter, we cover the architecture and implementation of the predictor and how it connects to other components in the BOOM core.
We start by summarising the work done previously.

== Previous Work

*Disclaimer:* this section is presenting work that was done before work on this project started, but it is relevant to understanding the rest of the work that has been done, thus we have included it here.
Work in following sections is done afterwards and for this thesis.

In a preparartion for this project, we implemented and started integrating a load-address predictor based on instruction addresses @bib:nodland-paper.
As load instructions commit, they are sent to the predictor to train it.
The predictor detects simple strided patterns.

=== The Predictor

We opted for a simple strided predictor for testing purposes.
A strided predictor detects _strides_ in the address stream generated by load instructions.
I.e. the predictor detects when the same load instruction accesses addresses in consistent increments (or decrements).
The predictor is accessed using instruction address of a load instruction and the storage is organised like a direct-mapped cache.
The storage uses full-width tags (based on instruction addresses) to prevent aliasing as described in @bib:doppelganger.
This simple organisation and implementation was chosen to ensure predictions could be generated quickly on demand.

Each entry of the predictor contains a tag, the previous accessed address, a stride, and the confidence of this prediction.
Predictions are based on physical addresses because that is the information available to the predictor at the commit side.

This has necessitated changing the predictor slightly so that predictions that fall outside of the page of the previous access must be considered invalid so as to not cause exceptional conditions.
Thus, if the new prediction increases the page number in the address, the prediction is marked as invalid.

=== Efficient Predictor Storage

The predictor storage is organised as a specialised cache and is accessed using bits of the instruction address.
As the BOOM is a superscalar microarchitecture, it is possible that multiple predictions need to be read or updated at the same time.
One major discovery from @bib:nodland-paper is that the predictor storage can be implemented efficiently by splitting the storage into multiple banks where each bank requires only one write port and two read ports.
This optimisation relies on the fact that the frontend and backend of the BOOM only dispatch and commit consecutive instructions up to the width of the processor.
The optimisation is trivial when instruction addresses always align to a four-byte boundary.
By using a power-of-two number of banks larger than or equal to the processor width, assigning a bank per instruction is as simple as taking bits $2+n-1:2$ (inclusive range) of the instruction address and using that as an index.
The nature of consecutive instruction addresses guarantees that this scheme yields different banks for each of the incoming instructions.

However, as the BOOM supports the C-extension of RISC-V, instructions can align to two-byte boundaries and may be either four or two bytes wide.
This creates complexity in determining the appropriate banks for consecutive instructions.
In @bib:nodland-paper we showed a simple scheme that provides fairness---similar usage across all banks---and has a low complexity, requiring only an XOR-gate and a concatenation of bits to get the appropriate bank number.

Due to time constraints and the fact that we only ran simulations, the actual implementation uses a single bank with many ports but still uses the algorithm to select the appropriate port.
Synthesis tools are unlikely to detect that the port numbers are guaranteed to be different and is thus unlikely to generate the optimal implementation.
Instead, a proper implementation that exploits this property would need to use something similar to a crossbar switch.
Our original thinking was that this crossbar switch could be implemented physically with tri-state buffers in an integrated circuit.
This supposedly poses some challenges with capacitances in shared wires and such, but the reduced port count should still be advantageous.

RISC-V technically supports more instruction sizes in increments of 16 bits, but none of the ratified extensions thus far use instructions larger than 32 bits.
Adding more instruction sizes while keeping the alignment requirements of 16 bits adds more complexity in bank selection logic.

=== Training the Predictor

Along with the scheme for efficient predictor storage we displayed the predictor's ability to detect strides in the addresses accessed by committed load instructions by showing an increasing confidence value in an entry of the predictor.
The predictor is only trained on cacheable addresses to prevent sending spurious load instructions to locations that may have side-effects.

== Integrating the Predictor

Here we describe the process of integrating the predictor into the system and sending predictions to the LSU and how they are handled from there.
@fig:doppelganger-load-architecture is how we have implemneted it in the BOOM, but it is included in the previous chapter to illustrate concepts around how doppelgangers work.

=== Generating Predictions for Incoming Load Instructions

The core is connected to the predictor and the predictor receives the uOPs that are sent to the decode units, thus the predictor starts quite early in the pipeline.
Because the predictor receives "raw" instructions, bits like `is_load` in the uOP are not yet set.

From here, the predictor generates a prediction by looking up in the storage to see if there is a matching entry.
If there is a matching entry, a prediction is created by adding the stride to the previous address.

If there is a match, the instruction is guaranteed to be a load instruction as the only way the entry would have ended up in the predictor storage in the first place is by receiving a committed load.
It is still reasonable to perform a simple check to see whether the instruction is a load and use clock-gating to conserve the power spent accessing the predictor storage, but this has not been done for the sake of saving time.

=== Sending Predictions to the Load-Store Unit

The predictor only sends a single prediction to the LSU per cycle, no matter the width of the memory interface.
When multiple predictions are generated in the same cycle, the one with the highest confidence is prioritised.
Predictions are not buffered, so if there is available capacity in the LSU the next cycle, but no predictions generated, the LSU stalls.

In the LSU, the predicted addresses are stored next to the real addresses in the LDQ.
In a final implementation, these two slots should be merged, but they are separated for simpler debugging and implementation.
All predictions generated by the predictor are stored in the LDQ, even if they are not used.
This is done purely for tracking statistics.

Predictions are prioritised over various wakeup signals, but can not take priority over the `_incoming` signals.
The `_incoming` signals in the LSU are generated by AGUs and cannot be back-pressured because the AGUs are 0-cycle FUs, meaning they must be handled as they arrive.
`_wakeup` and similar signals are decided by the LSU itself, so we can safely prioritise doppelganger loads over them.

We have made efforts to properly synchronise the predictions that enter the LSU with the uOPs that arrive from dispatch/rename to the LSU.
Because predictions are based on uOPs that have not yet passed through rename, the LDQ index has not yet been generated.
LDQ entries are allocated in the LSU during the decode stage.

Most of the time, the naive approach works by assuming a fixed number of cycles from entering decode until leaving dispatch/rename.
Sometimes there is back-pressure and the predictions fall out of synchronisation with the uOPs from dispatch.
This is slightly difficult to fix without hooking into a lot of stalling logic, which we wanted to avoid for simplicity.
In the LSU, prediction PCs are compared with dispatched uOPs' PCs to verify that they belong to the correct instruction and are otherwise ignored when they are unsynchronised.

=== Passing Predictions to the Data Cache

As predictions arrive and there is available capacity, the LSU will issue a doppelganger load to the data cache.
The request is marked as such and flows almost like a normal load, except that if it misses, it is not passed to the MSHRs but is dropped instead.
The corresponding LDQ entry is marked as executed to prevent mechanisms like wakeup or triggering extra loads when the real address arrives.
Marking entries as executed, or at least triggering the pipeline that eventually marks them as such, also triggers additional mechanisms such as checking for ordering violations and such.

One important difference between doppelganger loads and normal loads is that doppelganger loads do not trigger the speculative load wakeups.
Speculative load wakeup is on a fixed cycle offset from issuing the load to the L1d and care must be taken to ensure doppelgangers suppress this logic.

=== Problems with Missing Mispredicted Doppelgangers

In the case of doppelgangers that miss, the LSU is informed to ensure the corresponding entry is marked as such.
Otherwise, in the case of a correct prediction, the LSU will be waiting for a response that never arrives.

Dropping the missing doppelgangers was done to save time from working around a bothersome issue where:
+ a doppelganger was issued to the data cache,
+ the doppelganger missed and was placed in a MSHR,
+ the doppelganger used an incorrect prediction,
+ the real load hit in the cache and returned its value before the doppelganger could complete,
+ the doppelganger finally returned, extremely late with no clear indication as to whether the LDQ slot had already been re-allocated for a new load, which was predicted correct, then
+ the extremely old doppelganger propagated its value to the wrong instructions.

In a proper implementation of doppelganger loads, doppelgangers should be allowed to miss in the first-level cache.
This requires the MSHRs to be informed when a doppelganger that missed is determined to be mispredicted so that the request can be dropped or tagged so that the request can be properly ignored when returning to the LSU.

=== When the Real Address Arrives

When the real address arrives from an AGU, the LSU raises a signal named `can_fire_load_incoming`.
This signal has the highest priority, so `will_fire_load_incoming` will always be high, barring a lack of capacity for other reasons such as back-pressure from the L1d.

After inspecting the relevant signals from the AGU, the LSU performs a lookup in the LDQ to check whether the address is for a previously predicted (and executed) doppelganger.
If it is, the predicted address is compared to the output from the TLB (unless it missed).
When the address is confirmed, the corresponding entry is marked as correct.

Here, it is important that the `can_fire_load_incoming` and `will_fire_load_incoming` signals are not suppressed if the prediction is determined to be correct.
We were under the assumption that doing this would allow the LSU to prioritise other actions that require the same resources, but these signals are used to select the input to the TLB, whose outputs are used to compare to the predicted address, whose output would be used to suppress the aforementioned signals, which are used to select the inptu to the TLB.
That is a combinational loop.

This handling is unfortunate as the LSU in theory would be able to issue wakeup operations for loads that have had their address translated but could not be issued to the L1d for other reasons.

=== Store Value Forwarding

If an older store aliases with a newer doppelganger load, the doppelganger receives the forwarded value and the request to L1d is squashed.

=== Handling Responses From the Data Cache

Normal responses from the L1d are sent straight to the PRF as they are already based on real addresses and dependent instructions can begin executing.
Doppelganger loads require holding off dependent instructions until the address is confirmed.

Because of time constraints, we have not implemented the logic to hold values in the PRF until they are ready.
Instead, the values are held in the LDQ until the address is confirmed and the writebacks are scheduled.

=== Sending Responses to the Physical Register File

An AGU can generate an address (and thus confirm a prediction) in the same cycle that the LSU receives a response from the L1d for a non-doppelganger load.
As confirmed doppelgangers and real loads have to share the same writeback ports, the doppelgangers are only written back when there is available capacity.

A priority mux detects confirmed, unsent doppelgangers and writes back the values when no other instructions require the ports.
Lower absolute indices in the LDQ are given priority.
A slightly more optimal strategy would be to prioritise from the head of the LDQ which is implemented as a circular buffer, ensuring that the oldest confirmed doppelgangers are sent to the PRF as soon as possible.
As this is not intended to be part of the completed solution, we choose this method of writebacks as an acceptable compromise for the time constraints.
