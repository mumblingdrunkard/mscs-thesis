= Doppelganger Loads <ch:doppelganger>

We are implementing doppelganger loads in hardware @bib:doppelganger.
This chapter presents the concept of Doppelganger Loads, how they do not change the safety guarantees of secure speculation, and how they improve performance.
At its core, doppelganger loads attempt to regain some of the MLP that is lost when applying secure speculation schemes.

== Register File Prefetching

To explain doppelganger loads, it is useful to first explain _register file prefetching_ (RFP).
The increasing complexity of processors has necessitated deeper L1 cache pipelines, causing relative access latencies to increase to as much as 5 cycles.
One of the key observations by the team behind RFP is that performance could be improved as much as 9% by making L1d access appear like accessing the register file on a modern design with a 5 cycle L1d access latency @bib:rfp.

RFP recognises that by using a predictor to guess which addresses are going to be accessed by individual load instructions, the value can be read from L1 cache before the real address is generated.
The prefetched values are put in the correct location in the register file but dependents are not issued until the address is confirmed, at which point dependent instructions can use the value immediately and do not have to wait an additional 5 cycles after the address has been generated to perform the cache access, nor for the value to become available in the register file as it is already there.

With this kind of setup, the team achieved a 3.1% performance improvement on a modern processor, and as much as a 5.7% performance improvement in a "futuristic" twice-as-wide core design with increased L1 bandwidth @bib:rfp.

Note that this is different from the concept of _value prediction_ (VP) in which dependent instructions are executed before their dependencies are definitely known.
RFP does not allow dependent instructions to execute until the prediction is known to be correct (correct address and not violating any ordering requirements).

== Doppelganger Loads are Safe

What Kvalsvik et al. recognise in @bib:doppelganger is that by training a load address predictor only on committed loads and issuing loads early using predicted addresses, it is possible to recover some of the MLP that is lost when using secure speculation schemes.

Because it is only trained on committed loads, speculative cache accesses using these predictions only reveal information about past correct execution, which is already considered leaked under the appropriate threat models.
There are some extra edge-cases that have to be handled carefully depending on the underlying secure speculation scheme but the approach is generally safe.

Accesses based on these predictions are dubbed _doppelgangers_ or _doppelganger loads_ and stand in for a load to the real address until the real address is calculated.

== Doppelganger Loads Architecture

Doppelganger loads are proposed to be implemented with an architecture that resembles the one in @fig:doppelganger-load-architecture.

#figure(
  ```
    ┌────────────────┐  ┌───────────────────────────┐
  ┌─▶     LDPRED     ◀──┤            IF             │
  │ └────────▲───────┘  └────────────┬──────────────┘
  │          │          ┌────────────▼──────────────┐
  │       commit   ┌────┤            ID             │
  │          │     │    └────────────┬──────────────┘
  │ ┌────────┴─────▼─┐  ┌────────────▼──────────────┐
  │ │                │  │            RR             │
  │ │      ROB       │  └───┬──────────────┬────────┘
  │ │                │  ┌───▼───┐ ┌────────▼────────┐
  │ │                │  │  mIQ  │ │       iIQ       │
  │ └────────┬───────┘  └───┬───┘ └───┬─────────┬───┘
  │          ▼          ┌───▼─────────▼─────────▼───┐
  │       commit  ┌─────▶            PRF            │
  │               │     └───┬─────────┬─────────┬───┘
  │ ┌─────────────┴──┐      ▼     ┌───▼───┐ ┌───▼───┐
  │ │      LSU    ▲  │┌──  AGU    │MUL/DIV│ │  ALU  │
  │ │             │  ││           ├───────┤ └───┬───┘
  │ │ LDQ ┌──────▶┴┐ ││           │MUL/DIV│     ▼    
  └─▶ ADDR│DG?┐  │=│ ◀┘           ├───────┤   to PRF 
    │ ├───┼───┤  └─┘ │            │MUL/DIV│          
    │ ├───┼───┤      │            └───┬───┘          
    │ ├───┼───┤      │                ▼              
    │ └───┴───┘      │              to PRF           
    └───────▲────────┘                               
            │                                        
    ┌───────▼────────┐                               
    │                │                               
    │       D$       │                               
    │                │                               
    └────────────────┘                               
  ```,
  kind: image,
  caption: "Doppelganger load architecture",
) <fig:doppelganger-load-architecture>

An address predictor `LDPRED` makes predictions for incoming instructions and sends those predictions to the LSU.
The LSU sends those predictions to the L1d `D$`.
Entries in the LDQ for doppelganger loads are shared with the loads they stand in for and are tracked with a flag marking them as doppelgangers `DG?`.

As doppelganger loads complete, the results are written back to the PRF, but dependent instructions are not woken up.

When the real address arrives from an AGU, it is compared to the predicted address already stored in the LSU and, if they are equal, a signal is sent to the PRF/IQs that the result is ready and dependents are woken up to be issued.

The real address replaces the predicted address in the LDQ so that on commit, the address can be sent to the predictor for training.

== Special Considerations for Doppelganger Loads

There are some special cases to take into account when implementing doppelganger loads that are outlined in the paper @bib:doppelganger.

=== Ordering

=== Store-to-Load Forwarding

=== Special Considerations for Delay-on-Miss

== Doppelganger Loads Performance

== The Cost of Doppelganger Loads

One of the important aspects of doppelganger loads is that it is a cheap technique in terms of additional required hardware, requiring only storage for the predictor and a few bits per load to correctly mark prefetches.
Address storage in the memory access unit does not have to be expanded as the real address and the predicted address are only needed at the same time when they are compared, which is done as soon as the real address is generated.
Thus, the real address can simply replace the predicted one for mispredicted load instructions.
Said in a different way, once the real address is generated, the predicted address is no longer needed, meaning they can share the same storage.

They @bib:doppelganger also propose to merge the predictor with the one found in the L1 data prefetcher to save even more on implementation costs.
This is only mentioned in passing and is not explored deeply in the paper.
The reasoning is simple: because common L1d prefetchers predict the next address, the only modification that is needed is for the predictor to predict the current address.
