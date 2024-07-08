#import "../utils/utils.typ": *

= Discussion <ch:discussion>

In this chapter, we discuss the results and try to reason about them.

== Interpreting Results

Similar to the results in @bib:doppelganger, the benefits are quite small.
At best, we would hope for the doppelganger loads to increase performance as much as speculative load wakeups.
In most cases, address prediction can at best make loads behave _as if_ speculative load wakeups were enabled.
That is: the performance of *ldpred-no-spec-ld* should likely fall somewhere between *base-no-spec-ld* and *base*.

This is also largely what we observe: very small improvements with varying levels of success.
Most interesting is perhaps the cases where the combination of speculative wakeups and load address prediction lead to a worse result than any one technique applied in isolation.
We do not have a hypothesis for this behaviour.
Most likely it is down to luck in execution because these tests are so short that a few cycles improvement can lead to drastically different final IPC values.

One thing of note when looking only at the IPC is that the predictor seems to do better with workloads that iterate through arrays like *vvadd* and *median* and worse for the quicksort programs *rsort* and *qsort* where the access patterns depend heavily on the input data.
It seems to do nothing in the recursive *towers* application, which does look better than the performance reduction when adding speculative load wakeups.

Why speculative load wakeups may ever reduce performance is unclear to us, but it is possible that a speculative wakeup marks an IQ slot as ready and schedules it, taking up available issue-capacity for that cycle, only to be killed in the next cycle.

Bringing accuracy and coverage into the mix muddies the picture significantly.
The *vvadd* test which seems to benefit greatly from address prediction in the MediumBoomConfig case has a coverage of less than 50% in the SmallBoomConfig, and lower than 25% in the MediumBoomConfig.
Additionally, the accuracy for *vvadd* is nothing short of abysmal.

Our hypothesis is that *vvadd* has such a tight loop that multiple iterations of the same load instruction are being observed by the predictor, without any commits to update the previous address, causing the predictor to issue incorrect predicted values for later loads.

The fact that *median* gets a much better coverage and accuracy supports the hypothesis as it has a munch longer loop.
*median* also has a much lower IPC in the first place, meaning each loop takes longer.

As for coverage in general, we observe that the total coverage (predictions made/total number of loads committed) varies only slightly between the SmallBoom and MediumBoom configurations, with the latter having a slightly lower coverage overall.
For the effective coverage (predictions used/total number of loads committed), there is a more severe reduction.
Most likely, this is due to there simply being more conflicts where a prediction is made, but cannot be issued because some other operation is given priority.
The same number of actions must be performed by the LSU in around half the time, leading to a higher utilisation factor with fewer opportunities to insert predictions.
Both the SmallBoom and MediumBoom configurations have only a single port to the L1d, which supports the hypothesis of contention.

== Evaluating Hardware Cost

Without a working synthesis process, it is difficult to evaluate the definitive hardware cost.
The most important thing to know is whether adding the code for doppelgangers increases the length of the critical path and how much hardware is needed to implement the predictor.

Because of the banking strategy, the complexity of the predictor storage should be considerably lower than that of the PRF.
Additionally, the predictor storage has some cycles of latency for access, meaning implementation can feasibly be done with SRAM blocks as opposed to flip-flop type registers.
Thus, the critical path is likely unchanged.

As for how much hardware is needed to implement the entire scheme, the added bits to track doppelgangers in the LSU are largely irrelevant, requiring only one bit per LDQ entry, and the major cost is likely to be the predictor storage itself which requires storing the tag, the previous accessed address, the stride, and the confidence for each entry.

With the current implementation, there is a lot of waste, but for the planned architecture this should not be a problem.
The planned architecture does seem feasible to implement with additional time and better knowledge of the working components of the BOOM.

Without any obvious indication of anything to the contrary, we claim similar hardware cost as @bib:doppelganger:
One additional bit per entry in the LDQ and the predictor storage itself.

== Problems

There are some obvious problems with the current implementation, some of which are outlined and explained here.

=== `debug_pc` is Used

`debug_pc` is a signal in the uOP bundle in the BOOM.
As the name implies, it is the program counter value (instruction address) of the uOP intended for debug purposes and should not be required in a real implementation.

This signal is used at various points in the predictor.
The use with the most impact is on the commit-side when the predictor is being trained as this forces the ROB to store the full PC value for every single instruction.
It is less bad to use it on the prediction side as the instruction passed in has not yet even entered decode and passing the PC value on for a a few stages is not too much of an impact.

It is also used in the LSU to compare the incoming predictions with the incoming (dispatching) uOPs.
This is slightly worse as it requires passing the full width PC through both stages.

The ROB already stores the PC per instruction, but in a format that saves storing the upper bits more than once per row.
It should be simple to reconstruct the PCs/addresses of uOPs that leave the ROB.

We mistakenly believed in @bib:nodland-paper that reading from the ROB to reconstruct the PC would be better in all cases.
Upon reflection, we have determined that this would only serve to increase the pressure on the ROB and that passing the address on for a few stages is preferable to adding extra ports to the ROB in terms of complexity.

=== Incorrect Printout From Tests

As shown in the previous chapter, the output from the tests have missing characters.
It looks like the first few lines print fine, or close to fine, but then get messed up.

Normal programs would write to the terminal by using system calls or environment calls.
These tests do not do that and instead use a different protocol to interact with a sort of "hidden" system in the BOOM.
The programs do this by writing a value at a specific address, then setting a flag at another address referred to as `tohost`, then entering a loop until another flag at another address referred to as `fromhost` is raised.
This hidden system is referred to as a _test virtual machine_ (TVM) @bib:riscv-tests.

With the way the printing behaves, our working hypothesis is that there is some sort of ordering failure arising when predicted loads are added.
The LSU can have ordering failures on loads, but these seem to be checked in relation to the real load.
If the doppelganger load would incur an ordering violation but the real load does not, the value that is written back is possibly inconsistent.

This might make the `fromhost` flag being visible too early, or there may be something in the TVM that gets an incorrect value when checking available buffer capacity for a serial port.
This issue is very difficult to debug.

Attempts at debugging this issue yielded little and the effects of the TVM appear to be invisible in waveforms and debug print logs, making the results of our investigations inconclusive.

== Future Work

We outline the future work that should be done for a proper implementation of doppelganger loads in the BOOM core.
The ordering here is thought to be a reasonable order of steps for actual implementation.

=== Implement Doppelganger Loads Alongside Secure Speculation Schemes

Ultimately, the performance improvements are meagre when compared to speculative load wakeups.
This is not a surprising result and seems mostly in line with the results from the original paper on doppelganger loads @bib:doppelganger.

Instead, doppelganger loads should be seen in relation to secure speculation schemes such as NDA, STT, and DoM.
This requires some modifications to how doppelganger loads are performed such as allowing doppelgangers to execute despite ordering violations and store-forwarding as these mechanisms can reveal information about other load and store instructions in flight.
It may also require delaying changes to the cache replacement policy.

=== Detecting and Compensating for Tight Loops

We hypothesised that the poor accuracy displayed in simple applications like *vvadd* and *multiply* comes mainly from the predictor's current inability to detect when there are very tight loops, causing it to issue predictions for additional load instructions without being updated by a commit.

Said in a different way: the LDQ holds multiple iterations of the same load instruction, meaning the predictor is not updated with new training data.

Solving this problem requires first detecting when a tight loop occurs and then deciding what to do when in such a loop.
Detecting such a loop can be done by incrementing a counter each time an instruction address is used to make a prediction, and decrementing the counter when the same address is committed.
That gives a reasonable estimate for how many instructions are in flight and thus how many times the stride should be added.
This requires a multiplier, though likely not a large one.

Another option is to track how far off the prediction is from the real address and storing that in the LDQ.
This increases the cost of the LDQ because it requires storing the stride.
However, on the commit-side, the predictor can store the new stride and make new predictions using that.
Assuming the tight loop reaches some sort of steady state, this should be sufficient to ensure the predictions are ahead by the correct amount.

However, the steady state might easily flip-flop between having $n$ loads in flight and $n plus.minus 1$ loads in flight, which would make the appropriate offset change accordingly.
This might warrant a more complex predictor to detect such flip-flopping.
Calculating an appropriate confidence value also becomes more complicated in this scenario.

=== Making Predictor Storage Set-Associative

Currently, the predictor storage acts like a direct-mapped cache.
Changing this to an associative implementation is likely to result in fewer evictions and better coverage with an equal number or fewer entries.

=== Storing Values in the Physical Register File

First, the values should be sent to the PRF as responses arrive from the L1d, just as for real loads.
This requires some mechanism to hold off dependent instructions until the address is confirmed, and a way to wake them up when the address is confirmed.

It may be possible to re-use the writeback logic as wakeup logic to avoid adding additional ports to the IQ slots, though this also means confirmed addresses sometimes have to wait.
The other alternative is to add an entirely different port for waking up dependents, but this adds pressure on each IQ slot.
It may also be possible to re-use the speculative wakeup port as a dual-purpose port, prioritising signalling correctly predicted doppelgangers.

=== Removing the Dependency on `debug_`-Signals

In its current form, the code makes use of the `debug_pc` signal of the MicroOp bundle in various locations.
This signal should not exist in a final deployment and the PC either has to be explicitly added or reconstructed from other available information.

For the prediction side, it is likely fine to pass the PC through the initial stages instead of potentially adding more ports to the FTQ to read the high-order bits of the PC.
On the commit side, the PC should be reconstructed from the low-order bits contained in the uOP and the high-order bits from the FTQ.

=== Buffering Predictions to Fill More Cycles

There is potential to fill unused cycles with more predictions.
For example, when a prediction is made in the same cycle as an address arriving from the AGUs, the LSU prioritises issuing operations to the L1d based on the data from the AGU and the prediction is dropped.

If predictions were not dropped but put in a buffer-like structure instead, the LSU could prioritise issuing loads for predicted addresses when it has available capacity.
Keeping predictions around for 1-2 cycles seems reasonable to fill more cycles.

=== Allow Other Operations to Execute Upon Correct Predictions

When a correct prediction is made, the `will_fire_load_incoming` signal is high, causing the LSU to "think" that the L1d is being accessed, even if the operation is intercepted.
This leaves room for other operations that access the L1d, such as more predictions, or waking up loads that have already had their address translated.

=== Compressing Predictor Entries

Currently the predictor uses full-width tags, previous addresses, and strides.
In the case of the BOOM, the max address width is 39 bits.
This makes for very large entries in the predictor.
Strides likely tend toward smaller values and can likely be compressed to something closer to 10-12 bits.

The previous address is more difficult to compress, but likely has a lot of bits in common with other addresses registered in the predictor.
For this case, it might be possible to store low-order bits and a reference to a smaller table for storing shared high-order bits, similar to how the PC is stored for each instruction in the ROB.
This approach likely requires an additional cycle of latency, but that may be a worthwhile tradeoff.

=== More Complex Predictors

When the delay from prediction to receiving the real address is greater than the normal L1d access latency, there is room for having a predcitor that detects more advanced patterns but uses more cycles to perform the prediction to increase accuracy.
It may also justify deeper pipelines to access predictor storage, which may in turn allow for storing more predictions overall.

One such predictor might be using _delta-correlating prediction tables_ (DCPT) in which individual load instructions do not exhibit purely strided patterns, but still have patterns of offsets @bib:dcpt.

==== Hybrid Predictor

As only ~20% of predictions are compared to the real address within 10 cycles, there is a good possibility of using additional slower predictors to get more accuracy for longer loads.

One intriguing option is the possibility of issuing multiple doppelgangers per load using fast and slow predictors.
Similar to how some branch prediction structures work where IF is redirected with a fast, low-accuracy prediction first, and only later redirected if the high-accuracy predictor disagrees, this could work to increase accuracy at the cost of some latency.

We only collected statistics for load instructions that are already covered, but there is also a great possibility of increasing coverage with these predictor structures.

=== Test Predictor with Proper Benchmarking Suites and on Shared Systems

A glaring weakness of the tests we have run is that they are all very small programs that likely fit fully within the instruction cache and only run one at a time.
A useful predictor should be resilient to an OS switching tasks and should accomodate many tasks running within the same space of time and possibly with similar virtual address spaces.

With this, it should be considered whether sharing the predictor between many applications poses a security risk.
Intuitively, information in the predictor is only based on commited information and it should not be possible to extract information that is not already possible to extract through the cache side-channel.

Entries should likely still be tagged with information specifying which application they belong to to prevent interferring with each other's prediction performance.

=== Handle Changes to Virtual Memory

RISC-V has the instruction `SFENCE.VME` to signal that a change has occured to the virtual memory mapping and that the processor should invalidate some entries in structures like the TLB.
This is common when unmapping pages in virtual memory.
Similarly, corresponding entries in the predictor may need flushing as normal predictions bypass the TLB entirely and thus bypass permission checks on the assumption that subsequent accesses to a page are OK without permission checks.

This may also be entirely fine as the permission check is still be performed when the real address arrives, causing the processor to raise an exception if the prediction is correct and the address falls outside of mapped memory.

== Miscellaneous Musings

Here are a few of our musings on different relevant topics.

=== On the Possibility of Merging With the L1d Prefetcher

One of the ideas proposed in @bib:doppelganger is to merge the address predictor for doppelganger loads with that of the L1d prefetcher.
This makes sense in the cases where the L1d prefetcher is predicting which address will be needed soon.
Instead of predicting the next address, the predictor should determine the current address.

This can be feasible with L1d prefetchers that use strided patterns or DCPT which still have a semblance of predicting what the next load address is going to be.
State of the art prefetchers like best-offset @bib:best-offset would be considerably more difficult to integrate with.
Best-offset does not predict the next address, but an offset that is calculated to be a few accesses ahead to ensure timely prefetches.
The stride between accesses need only be a factor of the offset used by the prefetcher.

An additional issue is that the L1d prefetcher generally has different design requirements for the storage.
With the address predictor for doppelgangers, we know things about concurrent accesses that allow us to efficiently bank accesses.
The guarantees we rely upon for this strategy are lost at the point the L1d prefetcher is employed.
Adding ports to the L1d prefetcher could be costly.

If the two structures are physically far apart on the chip, that introduces additional issues, but can potentially be compensated for by allowing more latency for predictions.

=== Following Through on L1d Misses for High-Confidence Doppelganggers

We have decided to drop doppelgangers that miss in the L1d.
Our reasoning here is that in a system with an L1d prefetcher, predictable addresses will practically always hit.
Because our predictor uses a simple strided scheme, it is fair to say the addresses generated by the predictor are highly predictable.
Thus, by allowing misses to start fetching from deeper cache levels, there is a very low likelihood of those data being useful.

However, there is an interesting opportunity of a symbiotic relationship between the L1d prefetch predictor and the load address predcitor where they both detect different patterns and doppelganger loads appear almost like software prefetches to the L1d.

Additionally, it is obvious to us that L1d misses must be serviced for any MLP to be regained under certain secure speculation schemes such as DoM.

=== United Nations Sustainability Goals

This work is relevant to the United Nations Sustainability Goals by creating more performant processors that perform the same amount of work using less energy.
