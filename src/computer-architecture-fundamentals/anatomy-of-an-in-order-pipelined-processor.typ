== Anatomy of an In-order Pipelined Processor

This first major optimisation of the microarchitecture is based on the observation that all instructions have required steps in common, and that the components used in each step are usually different.

This introduces the concept of the _pipelined processor_.
A classic processor pipeline may look like: instruction fetch (IF), instruction decode (ID), operand fetch (OF), execute (EXE), memory access (MEM), and writeback (WB).

Each stage focuses on a specific stage of performing an instruction.
IF fetches the instruction from memory.
ID decodes the instruction and determines which control signals to set later in the pipeline.
OF fetches the values to be used later in the pipeline.
EXE performs the operation on some of the values.
MEM performs memory access with an address computed in EXE.
WB writes the values back to the register file so that they can be used by later instructions.

Between each stage, there is a big register called a _pipeline register_ that holds values and control signals.
The values come from outputs of previous stages, and are used as inputs in the current stage.
Each stage takes only one cycle to complete 

This is a form of _instruction-level parallelism_ (ILP): the observation that a processor can work on many instructions at the same time because each instruction requires different parts of the processor at any given time.

@fig:pipelined-cpu shows a high-level overview of a pipelined processor.
In this version, the ID and OF stages are merged together, meaning values are read out of the register file at the same time the instruction is being decoded.
Each stage is separated by a pipeline register.

#figure(
  ```monosketch
            ┌───────────────────────────┐
            │       ┌────────┬────┐     │
            │       │ ┌───┐  │    │     │
  ┌──┐ ║ ┌──▼──┐ ║ ┌▼─▼┐ ╟┘┌─▼─┐ ╟┘┌──┐ │
  │IF├▶╟▶│ID/OF├▶╟▶│EXE├▶╟▶│MEM├▶╟▶│WB├─┘
  └─▲┘ ║ └─────┘ ║ └───┘ ╟┐└───┘ ║ └──┘  
    └─────────────────────┘              
  ```,
  caption: [A high-level overview of a pipelined microarchitecture],
  kind: image,
)<fig:pipelined-cpu>

The connection from the EXE/MEM pipeline register to IF is to allow branch and jump instructions to change the PC.
The connection from WB to OF is there to allow the WB stage to write values back to the register file which is traditionally stored where operand fetch is performed.

=== Overlapping Execution

A simple pipelined processor like this can perform any single instruction in just five cycles, which is a good deal better than the shared bus architecture.
However, the real trick is to overlap execution of multiple consecutive instructions.
When an instruction moves from IF into ID, the IF stage is freed up and can start fetching the next instruction.
This holds for every stage.

Because of this, a pipelined processor can finish executing one instruction every cycle.

==== Hazards

With overlapping pipelining comes execution _hazards_.
Hazards arise when instructions depend on results from older instructions that have not yet completed.
For some of these, the results are ready and available in pipeline registers even if they are not yet written to the register file.
In this case, the values can be _forwarded_ to the stages where they are needed.
The connections from the EXE/MEM and MEM/WB pipeline registers to EXE and from MEM/WB to MEM are there for forwarding.
When a stage detects that an instruction in either of these later stages is going to write to one of its own source registers, it will use the value from the pipeline registers instead.

Some hazards cannot be dealt with by only forwarding.
For example: when one instruction reads from memory, and the following instruction depends on the result in the EXE stage, the procsessor has to _stall_ for a cycle.

==== Branches

All instructions that enter IF after a branch have a dependency on the branch.
The simplest thing is to stall IF until the branch instruction has left EXE and potentially modified the PC.
A possible step up is to assume that the branch condition will resolve to "False" and to keep fetching.
If the assumption turns out to be correct, three cycles have been saved.
If the assumption turns out to be wrong, the results of the incorrectly fetched instructions must be _squashed_ (ignored).

The next step up is to observe patterns in branch instructions and predict the outcome with more accuracy to prevent squashing too often.
This is the founding basis of _branch prediction_, a form of _speculation_.
