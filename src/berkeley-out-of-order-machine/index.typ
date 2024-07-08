= The Berkeley Out-of-Order Machine

The Berkeley Out-of-Order Machine (BOOM) is an open-source-software (OSS) project from the University of California, Berkeley (UC Berkeley).
It is an implementation of a 64-bit RISC-V processor

== RISC-V

The BOOM uses the RISC-V ISA, which is also developed at UC Berkeley @bib:riscv.
RISC-V is, as its name might imply, a RISC architecture.
The ISA has many variants and different extensions.

The BOOM uses the 64-bit base variant of RISC-V, rv64.
This variant specifies a base machine with 32 64-bit registers and instructions operating on 64-bit and 32-bit values.
Several instruction format variants are defined for different instruction types.
Some instructions require no destination register, while others require immediate values encoded in the instructions.
Instructions have a fixed size of 32 bits.
The PC is aligned at a four-byte boundary (the lower two bits of the PC are always 0).

=== Compressed Instructions

RISC-V supports instructions shorter than 32 bits through the C-extension.
The C-extension specifies a 16-bit instruction format for several common instructions and reduces the alignment requirement of the PC to a two-byte boundary (the lowest bit is always 0).
Even 32-bit instructions may start on any two-byte boundary.

The BOOM supports this extension, among many others.

=== Privileged Architecture

The RISC-V specification is split in a user-level architecture, and a privileged architecture.
The user-level architecture contains functionality most relevant to pure computation like branches, arithmetic, and memory instructions.
The privileged architecture contains functionality that is only available when executing in a privileged mode.
The privileged architecture specifies a scheme for virtual memory using pages of 4096 bytes (4 KiB).

Additionally, the privileged architecture specifies a number of _control and status registers_ (CSRs) that control the behaviour of the processor.
By writing different values to these registers, a programmer can manage the current execution mode, set up and control virtual memory, and control many other aspects of execution.
The CSR file additionally contains a number of _hardware performance counters_ (HPMs) to allow tracking things like time, the number of cycles, and the number of executed instructions.

== Development

Development of the BOOM project uses various tools for development, testing, and deployment.

=== Chisel

Chisel @bib:chisel-paper is a library of components and operations on those components written in Scala @bib:scala-lang.
Scala is a functional programming language built on top of the _java virtual machine_ (JVM).

Scala allows defining arbitrary operators which has enabled the developers of Chisel to create a system of various components that can be connected together with something that resembles a _domain-specific language_ (DSL), but is still fundamentally "just Scala".
Because Chisel is not its own language, but embedded in Scala, it is what is referred to as an _embedded_ DSL (eDSL).
Chisel in combination with Scala becomes its own eDSL HDL.

Similar projects exist in other functional languages like HardCaml in OCaml @bib:hardcaml and Clash in Haskell @bib:clash.

When writing a program in Scala using Chisel, the compiled code is a Scala program.
When running the Scala program, a Chisel _graph_ is generated by going through the code and instantiating components and connecting them together as specified by the program.
The code can include things like loops, variable reassignments, and everything else that normal Scala has to offer.
This is the real genius of Chisel: Scala can be used as a very powerful meta-programming language around Chisel.

The Chisel graph is verified against certain rules such as no disconnected inputs to modules and no combinational loops.
The Chisel graph might go through rudimentary optimisations by eliminating unused signals and other restructuring.

Finally, the graph can be used for purposes like simulation by tweaking input and output signals from code written in Scala.
However, the built-in simulator for the Chisel graph can be slow.
The graph can be used to output structural code in other HDLs such as VHDL or SystemVerilog which can in turn be used by other tools.

_Structural_ code is different from _behavioural_ code in that it describes circuits in terms of multiplexers, adders, and gates instead of 

=== Verilator

Verilator is a program that accepts SystemVerilog and translates the code to a multithreaded implementation of a simulator in C++ @bib:verilator.
This code is then compiled to create the final simulator.

Verilator gives a much faster simulator than simulating the Chisel graph directly and still preserves some of the nice debugging features that are available directly in Chisel such as printing debug information while simulating.

=== FireSim

FireSim is a platform for simulating circuits on FPGAs @bib:firesim.
Note that this is slightly different from simply implementing circuits on FPGAs.
FireSim includes various tools for debugging and profiling while running on the FPGA itself, features that have to be otherwise explicitly included in the RTL code otherwise.
This obviously leads to more complex circuits/systems, but these simulations are still much faster than in something like Verilator.

== Architecture and Implementation of Key Components

The BOOM uses, as the name would imply, an OoO microarchitecture.
Here, we present the components of the BOOM that are relevant to this text.
We may mention other components that are not fully explained, but their naming should give clear hints to their operation.

=== High-Level Architecture and Code Organisation

The BOOM source code is organised into a few directories: `common`, `exu`, `ifu`, `lsu`, and `util`.
The directory names hint at their contents.
For example: `common` contains `micro-op.scala` and `parameters.scala`, files that are used throughout the entire project and don't belong to one specific unit, or collection of units.
`util` has various utility components.
`exu` can be said to contain the actual processor and has files like `core.scala`, `decode.scala`, `rob.scala`, and all the files for various execution units, issue units, and register renaming.

`ifu` contains the front of the frontend such as the instruction cache implementation and various modules for fetching instructions, figuring out their alignments, and wrapping them up in packets for decoding down the line.
This is called the _instruction fetch unit_ (IFU).

`lsu` contains the files for the _load-store unit_ (LSU) described later.

#figure(
  ```monosketch
                      ┌───────────────────────────┐
                      │            IF             │
                      └────────────┬──────────────┘
                      ┌────────────▼──────────────┐
                 ┌────┤            ID             │
                 │    └────────────┬──────────────┘
  ┌──────────────▼─┐  ┌────────────▼──────────────┐
  │                │  │            RR             │
  │      ROB       │  └───┬──────────────┬────────┘
  │                │  ┌───▼───┐ ┌────────▼────────┐
  │                │  │  mIQ  │ │       iIQ       │
  └────────┬───────┘  └───┬───┘ └───┬─────────┬───┘
           ▼          ┌───▼─────────▼─────────▼───┐
        commit  ┌─────▶            PRF            │
                │     └───┬─────────┬─────────┬───┘
  ┌─────────────┴──┐      ▼     ┌───▼───┐ ┌───▼───┐
  │      LSU       ◀───  AGU    │MUL/DIV│ │  ALU  │
  └───────▲────────┘            ├───────┤ └───┬───┘
          │                     │MUL/DIV│     ▼    
  ┌───────▼────────┐            ├───────┤   to PRF 
  │                │            │MUL/DIV│          
  │       D$       │            └───┬───┘          
  │                │                ▼              
  └────────────────┘              to PRF           
  ```,
  kind: image,
  caption: "High-level overview of BOOM microarchitecture",
)

=== Anatomy of a Micro-operation

The BOOM uses a single class to represent most of the control signals that flow through the processor.
With few exceptions, the control signals for each stage are either derived from, or directly embedded within the `MicroOp` class found inside `common/micro-op.scala`.

This uOP class contains various flags and fields that inform later units of the type of instruction, which architectural registers it reads and writes, which physical registers it depends upon and writes to, which branches the instruction is currently speculated under, and more.

Not all signals are used in all stages, but Chisel optimises out these signals and only keeps those that need to be brought along.
This is a big advantage for development and debugging because it allows for assigning a signal as early as instruction fetch, and reading it back out at commit.
It also has the downside of it being very easy to accidentally rely on a signal that is not meant to be available at a certain stage.
For example, at commit, the information in the uOP comes from the ROB.
Depending on a signal at commit that was previously optimised away has the often unintended effect of increasing the size of each entry in the ROB.

=== Instruction Fetch

Because the BOOM is a superscalar implementation, the frontend must be able to fetch multiple instructions per cycle.
The BOOM fetches a number of bytes from the L1i and performs rudimentary pre-decoding to determine instruction boundaries and to be able to perform branch prediction.

It places raw instructions in a buffer that is read by the instruction decode stage.

=== Instruction Decode

The ID stage decodes raw instructions from the fetch buffer and allocates various necessary resources.

=== Re-Order Buffer

The documentation for the BOOM outlines the organisation of the ROB.
The ROB is stored as a $w$ wide table where $w$ is the width of the processor.
Instructions that are decoded together are consecutive in memory and can be stored in the same row in the ROB.

The rationale for this is that the high-order bits of the PC can be shared across entries in each row, yielding major savings in the number of bits needing to be stored.
An obvious downside is the requirement that instructions in the same row must be consecutive, leaving bubbles if there are a lot of branches in the code.

Documentation states that the low-order bits of each instruction in the ROB are determined by the index within each row, but this information is likely outdated and from a time when the BOOM did not support compressed instructions.
Now the uOP class contains an explicit field `pc_lob` which can be concatenated with the high-order bits stored per row.

The high-order bits of the PC in each ROB row are stored in the _fetch target queue_ (FTQ) in the IFU and is used for referencing in other parts of the pipeline; for example when instructions have to be replayed and the frontend has to be redirected to some point in the past.

Entries in the ROB are allocated during instruction decode.

=== Issue Queues

The base BOOM configuration has two issue queues.
One for memory operations (mIQ), and a separate one for integer operations (iIQ).
If operations on floating point numbers are supported, there is a separate queue for those too.

=== Address Generation Units

The _address generation units_ (AGUs) are the functional units that calculate addresses for instructions that access memory.
These units are not pipelined.
In the same cycle that the uOPs are issued, the address exits the AGU and is sent to the load-store unit.

=== Load-Store Unit

The _load-store unit_ (LSU) is where we have made most of our changes, besides the predictor itself.
It consists of various components and a lot of logic to determine which operation to perform next.

==== Load Queue

The _load queue_ (LDQ) holds information about the load instructions currently active in the system.
It is implemented as a circular buffer.
Entries are allocated at the tail during decode and are freed at commit.

LDQ entries consist of a few crucial signals such as the address, whether the address is virtual or physical, if the load has been executed (sent to the cache), and whether the load succeeded.
The LDQ entries also store the associated uOP to access fields like the physical destination register during writeback.

==== Translation Lookaside Buffer

The BOOM has a TLB to cache virtual address translations.
All addresses that enter the LSU from the AGUs go through the TLB.
If virtual addressing is not enabled, the TLB simly simply passes the address through without any translation and always succeeds.

==== Deciding Which Operations to Perform

==== Tracking Load Instructions

=== Data Cache

==== Miss Status Holding Registers
