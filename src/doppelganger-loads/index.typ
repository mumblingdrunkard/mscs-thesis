= Doppelganger Loads

We are implementing Doppelganger Loads in hardware @bib:doppelganger.
This chapter presents the concept of Doppelganger Loads, how they do not change the safety guarantees of secure speculation, and how they improve performance.
At its core, Doppelganger Loads attempt to regain some of the MLP that is lost when applying secure speculation schemes.

== Register File Prefetching

To explain Doppelganger Loads, it is useful to first explain _Register File Prefetching_ (RFP).
The increasing complexity of processors has necessitated deeper L1 cache pipelines, causing relative access latencies to increase to as much as 5 cycles.
One of the key observations by the team behind RFP is that performance could be improved as much as 9% by making L1 access appear like accessing the register file @bib:rfp.

RFP shows that by using a predictor to guess which addresses are going to be accessed by individual load instructions, the value can be read from L1 cache before the real address is generated.
The prefetched values are put in the correct location in the register file and are marked as prefetches until the address is confirmed, at which point dependent instructions can use the value immediately and do not have to wait an additional 5 cycles after the address generation, nor for the value to become available in the register file as it is already there.

With this kind of setup, the team achieved a 3.1% performance improvement on a modern processor, and as much as a 5.7% performance improvement in a twice-as-wide core design with increased L1 bandwidth.

Note that this is different from the concept of _value prediction_ (VP) in which instructions are executed before their dependencies are known to be good.
RFP does not allow dependent instructions to execute until the prediction is known to be correct (correct address and not violating any ordering requirements).

One of the most important aspects of RFP is that it is a cheap technique in terms of additional required hardware.

== Register File Prefetching is Safe Under Some Conditions

== The Cost of Doppelganger Loads
