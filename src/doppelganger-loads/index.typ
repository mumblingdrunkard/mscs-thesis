= Doppelganger Loads

We are implementing doppelganger loads in hardware @bib:doppelganger.
This chapter presents the concept of Doppelganger Loads, how they do not change the safety guarantees of secure speculation, and how they improve performance.
At its core, doppelganger loads attempt to regain some of the MLP that is lost when applying secure speculation schemes.

== Register File Prefetching

To explain doppelganger loads, it is useful to first explain _register file prefetching_ (RFP).
The increasing complexity of processors has necessitated deeper L1 cache pipelines, causing relative access latencies to increase to as much as 5 cycles.
One of the key observations by the team behind RFP is that performance could be improved as much as 9% by making L1 access appear like accessing the register file @bib:rfp.

RFP recognises that by using a predictor to guess which addresses are going to be accessed by individual load instructions, the value can be read from L1 cache before the real address is generated.
The prefetched values are put in the correct location in the register file and are marked as prefetches until the address is confirmed, at which point dependent instructions can use the value immediately and do not have to wait an additional 5 cycles after the address has been generated, nor for the value to become available in the register file as it is already there.

With this kind of setup, the team achieved a 3.1% performance improvement on a modern processor, and as much as a 5.7% performance improvement in a "futuristic" twice-as-wide core design with increased L1 bandwidth @bib:rfp.

Note that this is different from the concept of _value prediction_ (VP) in which dependent instructions are executed before their dependencies are definitely known.
RFP does not allow dependent instructions to execute until the prediction is known to be correct (correct address and not violating any ordering requirements).

== Register File Prefetching is Safe Under Some Conditions

What Kvalsvik et al. recognise in @bib:doppelganger is that by training a load address predictor on committed loads only and issuing loads early using predicted addresses, it is possible to recover some of the MLP that is lost when using secure speculation schemes.
This is because what some of these schemes do is essentially making L1 cache accesses look even slower.

Because it is only trained on committed loads, speculative cache accesses using these predictions only reveal information about past correct execution, which is already considered leaked under the appropriate threat models.
There are some extra edge-cases that have to be handled carefully but the approach is generally safe.

== The Cost of Doppelganger Loads

One of the important aspects of doppelganger loads is that it is a cheap technique in terms of additional required hardware, requiring only storage for the predictor and a few bits per load to correctly mark prefetches.
Address storage in the memory access unit does not have to be expanded as the real address and the predicted address are only needed at the same time when they are compared, which is done as soon as the real address is generated.
Thus, the real address can simply replace the predicted one for mispredicted load instructions.
Said in a different way, once the real address is generated, the predicted address is no longer needed, meaning they can share the same storage.

They @bib:doppelganger further propose to merge the predictor with the one found in the L1 data prefetcher to further save on implementation costs.
This is only mentioned in passing and is not explored deeply in the paper.
