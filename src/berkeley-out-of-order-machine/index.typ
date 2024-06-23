= The Berkeley Out-of-Order Machine

The Berkeley Out-of-Order Machine (BOOM) is an open-source-software (OSS) project from the University of California, Berkeley (UC Berkeley).
It is an implementation of a 64-bit RISC-V processor

== RISC-V

The BOOM uses the RISC-V ISA, which is also developed at UC Berkeley @bib:riscv.
RISC-V is a RISC architecture.
The ISA has many variants and different extensions.

=== Rv64i

The BOOM uses the 64-bit variant of RISC-V.
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

== Development

Development in the BOOM project uses various tools 

=== Chisel

=== Verilator

=== FireSim

== Architecture and Implementation of Key Components

The BOOM uses, as the name would imply, an OoO microarchitecture.
Here, we present the components of the BOOM that are relevant to this text.
We may mention other components that are not fully explained, but their naming should give clear hints to their operation.

=== High-Level Architecture and Code Organisation

=== Anatomy of a Micro-operation

=== Re-Order Buffer

=== Memory Issue Units

=== Address Generation Units

=== Load-Store Unit

==== Load Queue

==== Translation Lookaside Buffer

==== Connection to Address Generation Units

==== Deciding Which Operations to Perform

==== Tracking Load Instructions
