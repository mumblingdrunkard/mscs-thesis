= Architecture

In this chapter, we briefly cover the architecture of the predictor and how it connects to other components in the BOOM core.
We start by summarising the work done previously.

== Previous Work

*Disclaimer:* this section is mostly presenting work that was done before work on this project started, but it is relevant to understanding the rest of the work that has been done, thus we have included it here.

In a preparartion for this project, we implemented and started integrating a load-address predictor based on instruction addresses @bib:nodland-paper.
As load instructions commit, they are sent to the predictor to train it.
The predictor detects simple strided patterns.

=== Efficient Predictor Storage

The predictor storage is implemented as a specialised cache and is accessed using bits of the instruction address.
As the BOOM is a superscalar implementation, it is possible that multiple predictions need to be read or updated at the same time.
One major discovery from our previous work is that the predictor storage can be implemented efficiently by splitting the storage into multiple banks where each bank requires only one write port and two read ports.
This optimisation relies on the fact that the frontend of the BOOM only dispatches and commits consecutive instructions up to the width of the processor.
The optimisation is trivial when instruction addresses always align to a four-byte boundary.
By using a power-of-two number of banks larger than or equal to the processor width, assigning a bank per instruction is as simple as taking bits $2+n-1:2$ (inclusive range) of the instruction address and using that as an index.
The nature of consecutive instruction addresses guarantees that this scheme yields different banks for each of the incoming instructions.

However, as the BOOM supports the C-extension of RISC-V, instructions can align to two-byte boundaries and may be either four or two bytes wide.
This creates complexity in determining the appropriate banks for consecutive instructions.
In @bib:nodland-paper we showed a simple scheme that provides fairness---similar usage across all banks---and has a low complexity, requiring only an XOR-gate and a concatenation of bits to get the appropriate bank number.

=== Training the Predictor

Along with the efficient predictor storage we displayed the predictor's ability to detect patterns in the address of committed load instructions by showing an increasing confidence value in the predictor.

== Generating Predictions for Incoming Load Instructions

== Sending Predictions to the Load-Store Unit

== Passing Predictions to the Data Cache

=== Detecting Available Capacity

=== Prioritising Doppelganger Loads

== Handling Responses From the Data Cache

+ Sending requests
+ Handling responses
+ Sending responses to the register file
+ Waking up dependent instructions when 
