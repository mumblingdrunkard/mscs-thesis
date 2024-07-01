#import "../utils/utils.typ": *

= Discussion <ch:discussion>

In this chapter, we discuss the results and try to reason about them.


== Interpreting Results

Similar to the results in @bib:doppelganger, the benefits are quite small.
At best, we would hope for the doppelganger loads to increase performance up to the point where 

== Evaluating Hardware Cost

Without a working synthesis process, it is difficult to evaluate the definitive hardware cost.
The most important thing to know is whether adding the code for doppelgangers increases the length of the critical path and how much hardware is needed to implement the predictor.

Because of the banking strategy, the complexity of the predictor storage should be considerably lower than that of the PRF.
Additionally, the predictor storage has some cycles of latency for access, meaning implementation can feasibly be done with SRAM blocks as opposed to flip-flop type registers.
Thus, the critical path is likely unchanged.

As for how much hardware is needed to implement the entire scheme, the added bits to track doppelgangers in the LSU are largely irrelevant, requiring only one bit per LDQ entry, and the major cost is likely to be the predictor storage itself which requires storing the tag, the previous accessed address, the stride, and the confidence for each entry.

Obviously, with the current implementation, there is a lot of waste, but for the planned architecture this should not be a problem.
The planned architecture does seem feasible to implement with additional time and better knowledge of the working components of the BOOM.

== Problems

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
With the way the 

== Future Work

=== More Complex Predictors

=== Buffering Predictions to Fill More Cycles

=== Timeliness

== Miscellaneous Musings

=== On the Possibility of Merging With the L1d Prefetcher

One of the ideas mentioned in @bib:doppelganger is to merge the address predictor for doppelganger loads with that of the L1d prefetcher.
This makes sense in the cases where the L1d prefetcher is predicting which address will be needed soon.
Instead of predicting the next address, the predictor should determine the current address.

This can be feasible with L1d prefetchers that use strided patterns.
State of the art prefetchers like best-offset would be considerably more difficult to integrate with.
Best-offset does not predict the next address, but an offset that is calculated to be a few accesses ahead to ensure timely prefetches.
The stride between accesses need only be a factor of the offset used by the prefetcher.

An additional issue is that the L1d prefetcher generally has different design requirements for the storage.
With the address predictor for doppelgangers, we know things about concurrent accesses that allow us to efficiently bank accesses.
The guarantees we rely upon for this strategy are lost at the point the L1d prefetcher is employed.
Adding ports to the L1d prefetcher could be costly.

If the two structures are physically far apart on the chip, that introduces additional issues, but can potentially be compensated for by allowing more latency for predictions.

=== Following Through on Data Cache Misses for High-Confidence Doppelganggers

=== United Nations Sustainability Goals

This work is relevant to the United Nations Sustainability Goals by creating more performant processors that perform the same amount of work using less energy.
