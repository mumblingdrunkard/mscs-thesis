== Reduced vs. Complex Instruction Set Computers

There has been ongoing discussion about this topic for decades.
It boils down to whether ISAs should be designed with a large spectrum of instructions that do many things, or if it should be designed with few instructons.
When programmers were still writing their own assembly instead of generating it with a compiler, it was arguably nicer to have dedicated instructions for string manipulation built into the processor.
These instructions could become quite obscure and could require many steps.
This meant more work for the hardware engineers who had to implement all of the instructions, but it resulted in a nicer face for programmers.
These are the _complex instruction set computers_ (CISC).

The opposing alternative is _reduced instruction set computers_ (RISC) that uses very few instructions.
RISC-V, a RISC architecture has fewer than 50 instructions in its base specification @bib:riscv.
The argument for RISC is that implementing all the CISC instructions in hardware increases hardware cost and the effort needed to maintain and implement them.
The argument for CISC was that it lessened effort for programmers, and it required less storage for equivalent programs because each instruction could do more.
In the end, CISC won.

As the technology evolved, processor performance increased and compiled languages became viable.
However, it was quickly discovered that compilers preferred to stay away from some of the more obscure instructions of CISC ISAs, choosing instead to emit multiple instructions for what could be expressed in a single instruction.
This happened for various reasons such as the compiler simply not recognising that the optimisation could be performed, or it was recognised and the compiler developers found out that it would be no optimisation at all.
What had happened is that as processors grew in complexity, these complex instructions became increasingly difficult to implement in any obvious manner in more modern architectures without breaking them up into many, smaller steps.
Because of this, the special instructions that were included for the sake of programmers---and included in modern revisions because of backwards compatibility---were being implemented by falling back to a slow mode of processing.
Compilers were choosing to emit only those instructions that did not require this fallback mode.

Lots of development has happened since then, and CISC architectures still have a strong presence in the market of high-end computing, mostly for historical reasons.
A symbiotic relationship between compiler developers and hardware engineers has caused a subset of the CISC ISAs to become reliably fast, while more obscure instructions can be much slower.
The fast subset almost resembles a RISC in how it is used.

Additionally, CISC processor design has started to resemble RISC processors internally and the fetch/decode stages break large CISC instructions into multiple RISC-like operations before they are passed to the backend.

Our own interpretation of the subject is that anything that has an obvious path to implementation in a typical state of the art OoO processor can be considered RISC.
RISC-V extensions add hundreds of instructions for things like vector processing, bit-manipulation, hardware-accelerated cryptography, and more, but implementation is relatively clear and straightforward.
Another way RISC and CISC ISAs are typically different is in instruction encodings.
RISC architectures have traditionally opted for fixed-size instructions which are much simpler for the processor to decode.
