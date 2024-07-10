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
When the address is correctly predicted, the value can propagate as soon as the underlying secure speculation scheme allows it.
This is a big improvement when the cache access latency is high.

With relation to prediction- and resolution-based implicit channels, doppelgangers are safe as they are only trained on non-speculative data, and the values returned by doppelgangers are not propagated until the underlying scheme allows it.

== Doppelganger Loads Architecture

Doppelganger loads are proposed to be implemented with an architecture that resembles the one in @fig:doppelganger-load-architecture.

#figure(
  ```
    ╔════════════════╗  ┌───────────────────────────┐
  ╔═▶     LDPRED     ◀──┤            IF             │
  ║ ╚════════▲═══════╝  └────────────┬──────────────┘
  ║          ║          ┌────────────▼──────────────┐
  ║       commit   ┌────┤            ID             │
  ║          ║     │    └────────────┬──────────────┘
  ║ ┌────────╨─────▼─┐  ┌────────────▼──────────────┐
  ║ │                │  │            RR             │
  ║ │      ROB       │  └───┬──────────────┬────────┘
  ║ │                │  ┌───▼───┐ ┌────────▼────────┐
  ║ │                │  │  mIQ  │ │       iIQ       │
  ║ └────────┬───────┘  └───┬───┘ └───┬─────────┬───┘
  ║          ▼          ┌───▼─────────▼─────────▼───┐
  ║       commit  ┌─────▶            PRF            │
  ║               │     └───┬─────────┬─────────┬───┘
  ║ ┌─────────────┴──┐      ▼     ┌───▼───┐ ┌───▼───┐
  ║ │      LSU    ▲  │┌──  AGU    │MUL/DIV│ │  ALU  │
  ║ │             ║  ││           ├───────┤ └───┬───┘
  ║ │ LDQ ╔══════▶╩╗ ││           │MUL/DIV│     ▼    
  ╚═▶ ADDR║DG?╗  ║=║ ◀┘           ├───────┤   to PRF 
    │ ├───┤╔══╣  ╚═╝ │            │MUL/DIV│          
    │ ├───┤╠══╣      │            └───┬───┘          
    │ ├───┤╠══╣      │                ▼              
    │ └───┘╚══╝      │              to PRF           
    └───────▲────────┘                               
            │                                        
    ┌───────▼────────┐                               
    │                │                               
    │       D$       │                               
    │                │                               
    └────────────────┘                               
  ```,
  kind: image,
  caption: "Doppelganger load architecture (changes to underlying architecture are highlighted with double borders)",
) <fig:doppelganger-load-architecture>

An address predictor `LDPRED` makes predictions for incoming instructions and sends those predictions to the LSU.
The LSU sends those predictions to the L1d `D$`.
Entries in the LDQ for doppelganger loads are shared with the loads they stand in for and are tracked with a flag marking them as doppelgangers `DG?`.

As doppelganger loads complete, the results are written back to the PRF, but dependent instructions are not woken up.

When the real address arrives from an AGU, it is compared to the predicted address already stored in the LSU and, if they are equal, a signal is sent to the PRF/IQs that the result is ready and dependents are woken up to be issued.

The real address replaces the predicted address in the LDQ so that on commit, the address can be sent to the predictor for training.

== Special Considerations for Doppelganger Loads

There are some special cases to take into account when implementing doppelganger loads that are outlined in the paper @bib:doppelganger.
Doppelganger predictions being made and then made not visible may reveal information about other microarchitectural state and form an implicit channel.

=== Ordering and Store-to-Load Forwarding

Doppelganger loads being squashed because of ordering violations reveals the fact that the address matches a different memory access.
The same goes for store-to-load forwarding which would reveal a match in the STQ.
Because of this, properly implemented doppelganger loads should complete independently of such mechanisms and instead be ignored once the access is complete.

=== Special Considerations for Delay-on-Miss

DoM provides register protection and uses a different philosophy for protecting secrets than the other two schemes.
The authors behind doppelganger loads show some special cases where the guarantees of DoM would be broken by doppelganger loads.

The first case is:
+ during a misprediction, load a secret value with a hit in the L1, allowed by DoM,
+ a branch depending on the secret value performs different loads depending on the value,
+ the predictions generated for doppelganger loads in either case miss in the L1.

If the second branch depending on the secret value can resolve before the mispredicted branch, the issued doppelganger may reveal the speculatively loaded secret.
The second case is similar, but the secret is loaded before the misprediction.

This happens because DoM does not track dependent instructions and instead makes all loads wait until they are non-speculative to update microarchitectural state.
Because doppelgangers do potentially update microarchitectural state, they can break the guarantees of DoM when a branch forms an implicit channel such as described above.

The solution to this is to block these various implicit channels.
By resolving all branches in order, the only thing that can be revealed by doppelgangers after the second branch is the branch prediction as it is not allowed to resolve and depend on the secret before the misspeculation is detected and squashed.
For this, it is also required that the branch predictor is not trained speculatively.

Doppelgangers can also form an implicit channel, which is blocked by only propagating values from doppelgangers once the accompanying load is determined to be non-speculative.
That is, if the doppelganger misses, but the prediction is correct, the value is only propagated once the associated load becomes non-speculative.
If a doppelganger hits and is correct, the value is allowed to propagate while the load is still speculative.

Similarly, values forwarded from stores are not forwarded until they would be visible by DoM.

== Doppelganger Loads Performance

Doppelganger loads, when implemented in a simulator showed little performance gain over an insecure baseline processor.
However, when combined with secure speculation schemes such as NDA-P, STT, or DoM, doppelganger loads were able to recover as much as half of the performance lost under the various schemes.

== The Cost of Doppelganger Loads

One of the important aspects of doppelganger loads is that it is a cheap technique in terms of additional required hardware, requiring only storage for the predictor and a few bits per load to correctly mark prefetches.
Address storage in the memory access unit does not have to be expanded as the real address and the predicted address are only needed at the same time when they are compared, which is done as soon as the real address is generated.
Thus, the real address can simply replace the predicted one for mispredicted load instructions.
Said in a different way, once the real address is generated, the predicted address is no longer needed, meaning they can share the same storage.

They @bib:doppelganger also propose to merge the predictor with the one found in the L1 data prefetcher to save even more on implementation costs.
This is only mentioned in passing and is not explored deeply in the paper.
The reasoning is simple: because common L1d prefetchers predict the next address, the only modification that is needed is for the predictor to predict the current address.
