= Modern Hardware Design

Throughout this thesis, we discuss the relationships between abstract representations of circuits and their implementation as transistors and wires.
This chapter briefly describes a standard flow of modern hardware development.

== Register-Transfer Level and Hardware Description Languages

Modern processors are not designed as sequences of logic gates and registers in large diagrams.
They are far too complex for that.
Logic gates are also too concrete for the algorithms used when optimising designs, described later in this chapter.

Instead, modern hardware is designed using _hardware description languages_ (HDL): code that describes registers and logic and how they are connected.
Popular languages include the _VHSIC#footnote[Very High Speed Integrated Circuit was a research program by the United States Department of Defense to develop high-speed integrated circuits.] hardware description language_ (VHDL) @bib:vhdl-standard, and _SystemVerilog_ @bib:systemverilog-standard.

=== Language Primitives

HDLs define various concepts, types, and components.
Some concepts have very clear, direct mappings to real hardware.
Other concepts exist to enhance development of the hardware.
Even at this level, HDLs concern themselves with abstract machines and operations within those abstract machines.

Generally, there is a strict divide between _synthesisable_ and _unsynthesisable_ features of HDLs.
Synthesisable features are those that can be _synthesised_ by a compiler.
Synthesis means translating the abstract representation (the code) into a physical form (a network of transistors and wires).
When we discuss hardware design, we are most concerned with the synthesisable features.
The elements described here come from SystemVerilog.
@lst:systemverilog-example showns an example of SystemVerilog code.

#figure([```systemverilog
  typedef logic[31:0] word_t;
  typedef enum { ADD, SUB, AND, OR, XOR } op_t;
  module alu (
    input  logic  clk,
    input  logic  nrst,
    input  word_t in_a,
    input  word_t in_b,
    input  op_t   in_op,
    input  logic  in_valid,
    output logic  out_valid,
    output word_t out_value,
  );
    word_t value;
    logic valid;
    word_t result;
    always_comb begin
      case (in_op)
        ADD : result = in_a + in_b;
        SUB : result = in_a - in_b;
        AND : result = in_a & in_b;
        OR  : result = in_a | in_b;
        XOR : result = in_a ^ in_b;
        default : result = 'x;
      endcase
      out_value = value;
      out_valid = valid;
    end
    always_ff @(posedge clk or negedge nrst) begin
      if (!nrst) begin
        valid <= '0;
      end else begin
        if (in_valid) begin
          value <= result;
        end
        valid <= in_valid;
      end
    end
  endmodule : alu
  ```],
  caption: [SystemVerilog code displaying several features of the language],
  kind: raw,
)<lst:systemverilog-example>

It has to be noted that SystemVerilog is a high-level language.
Logic and flip-flops are _inferred_ and are not explicitly declared by the programmer.
The programmer only controls how the circuit should behave and not how the final circuit has to be implemented.

First off, the code in @lst:systemverilog-example declares a module called `alu` that has six inputs: `clk`, `nrst`, `in_a`, `in_b`, `in_op`, and `in_valid`.
The types of these inputs can be user-defined like `word_t` and `op_t` or one of the primitive types like `logic`.
The module also declares two outputs `out_valid` and `out_value`.
Within the module, more variables are created for `value`, `valid` and `result`.

A procedure is declared with `always_comb` indicating the intent that the logic contained within is purely combinational.
Here, a `case`-statement uses the `in_op` value to select between one of several operators and assigns the result to the `result` variable.
In SystemVerilog `=` is a _blocking assignment_, meaning all subsequent operations in the procedure use the new value.
The default case ensures `result` is always assigned to something, no matter the value of `in_op`.
The outputs are also set to match the internal values `value` and `valid`.

Next follows another procedure `always_ff` (always flip-flop) indicating the intent that the code within will require flip-flop circuits to implement.
This logic only triggers on the positive edge of `clk` or on the negative edge of `nrst`.
Then, if `nrst` is false (if `!nrst` is true), set the `valid` value to 0 using a _non-blocking assignment_ (`<=`).
A non-blocking assignment is different in that the assignment only takes effect at the end of the simulation cycle.
Other operations continue using the same `valid` until the next simulation cycle.
Otherwise, if `!nrst` is false, the code checks whether the `in_valid` signal is high, and if it is, sets the `value` to the `result`.
`valid` is always written to be the `in_valid` value as long as the circuit is not reset by `nrst` going low.

=== Mapping High-Level Constructs to Logic Gates

As mentioned, we are concerned with the synthesisable subset of the discussed HDLs.
As part of that, we describe how different HDL code can be synthesised into hardware.

==== Logic

For example, the case-statement can be represented as a series of `if`-`else if`-`else` statements, which can be constructed in hardware as a series of muxes, as shown in @fig:case-synthesis.
There are five units that perform the respective operations.
There are also comparison units to determine whether the incoming `op` is one of the given operations, represented as `*?` where `*` is the operation.
The results of these comparisons are used to control several muxes represented by `M`.
When the control signal is low, the mux selects the top output, and when the signal is high, it selects the bottom output.

#figure(
  ```monosketch
  a b op                             
  │ │ │                              
  │ │ └──────┬───┬───┬───┐           
  │ ├─▶─┐  ┌─▼┐┌─▼┐┌─▼┐┌─▼┐          
  │ │ │+┼─┐│-?││&?││|?││^?│          
  ├─│─▶─┘ │└─┬┘└─┬┘└─┬┘└─┬┘          
  │ ├─▶─┐ └─▶▼┐  │   │   │           
  │ │ │-┼─┐ │M├┐ │   │   │           
  ├─│─▶─┘ └─▶─┘└▶▼┐  │   │           
  │ ├─▶─┐       │M├┐ │   │           
  │ │ │&├───────▶─┘│ │   │           
  ├─│─▶─┘          └▶▼┐  │           
  │ ├─▶─┐           │M├┐ │           
  │ │ │|│───────────▶─┘│ │           
  ├─│─▶─┘              └▶▼┐          
  │ └─▶─┐               │M├───▶result
  │   │^├───────────────▶─┘          
  └───▶─┘                            
  ```,
  caption: [Implementation of the `case`-statement from @lst:systemverilog-example],
  kind: image,
)<fig:case-synthesis>

==== Maybe, DontCare, and Unknown

Notice that the value `'x` is assigned to `result` in the default case.
This is not a "real" value and is treated as "unknown" or "invalid".
When assigning `'x` like this, the programmer says that they do not care about the result in that case.
All values must eventually resolve to high or low in a physical implementation; `x` is thus an unsynthesisable value as it does not actually exist as a value.
"Don't care" values convey the semantic meaning that, in this case, the implementation of the circuit is allowed to do anything.
This liberty has been taken by merging the `+` case with the default case.

Such values are often referred to as "maybe", "don't care", or "unknown".
They are neither true nor false, but possibly both.
The truth tables for gates can be modified to account for unknown values and produce sensible results.
For example: the output of an OR-gate is always true if at least one of its inputs are true, it is only false if both inputs are false, and otherwise, it is unknown.
The output of an AND-gate is true only if both inputs are true, it is false if at least one of the inputs are false, and it is unknown otherwise.

This kind of three-valued logic is available in SystemVerilog, though standard practice seems to avoid them.
In this case, it may be better to explicitly specify that the default case should return the same result as the `+`-case.

==== Latches and Flip-Flops

The implication of `always_ff` is that the logic contained inside should require flip-flops for the logic.
Non-blocking assignments can be implemented using flip-flops as described in the previous chapter.
By using a flip-flop style circuit, the output is only updated once the clock-signal goes low again.

Latches are inferred at synthesis when a signal is not assigned in all possible cases.
For example if the `case`-statement was missing cases and did not have a `default` case, the value of `result` would be indeterminate.
SystemVerilog is defined such that variables retain their previously assigned value unless updated.
A latch can be used to accomplish this and only enable the latch when there is an updated value available.
A latch continuously reads and outputs the input value while the enable-signal is active.
However, this behaviour is commonly undesirable as it is often unintentional and adds more delay on account of needing to pass through a latch, which is why the `always_comb` block exists to warn the programmer.
If something inside an `always_comb` block results in an inferred latch, the tooling for the language gives an error or a warning.

=== Scaling Circuits

With high-level HDLs, it may be easy to forget that the circuit is destined for synthesis.
For example: variable indexing (where the index might change every cycle) in arrays requires a network of muxes for each place the array is indexed.
Adding more ports to read from an array of values can be even more expensive as it complicates wiring.

This is more true for arrays of stored values (large flip-flop structures).
Ports dedicated to writing to registers are more expensive to implement than ports for reading.
For multiple instructions to write back their results to the PRF, it must have multiple ports for writing.
Naive scaling is expensive and much research has been done to reduce the number of ports needed in the register file @bib:banked-register-files.

== Testing Designs

There are several ways to go about testing hardware designs.
Unsynthesisable features of HDLs are included because they are useful for testing and debugging circuit behaviour.

=== Simulation of Register-Transfer Level

One alternative is to run the code in a simulator.
A simulator takes the code and runs it according to the lanugage standard.
A popular simulator is _Verilator_ @bib:verilator which accepts SystemVerilog and translates it to a multithreaded model that can be executed on the host system.
The freedom of a software simulator allows for great support for various testing and debugging.

=== Field-Programmable Gate Arrays

When the design has been tested in a simulator and correct behaviour is confirmed, it is common to prototype the circuit on a _field-programmable gate array_ (FPGA).
An FPGA is a large canvas of _look-up tables_ (LUT) and various other components on a _fabric_.
The LUTs can be programmed to provide a given output for any given input.
The simplest possible LUT has two inputs and a single output.
Within it are four register cells that can be selected by using the two inputs as an address.
The values of the four register cells can be programmed to any values.
A two-input LUT can act as any logic gate by programming it with the same behaviour as the appropriate truth table.
The fabric consists of wires between the components and can be programmed in a similar fashion to decide which components are connected together.

With a proper bit-stream and enough components, an FPGA can be programmed to act like any circuit.
FPGAs are much faster than simulators, and even though they are slower than creating an integrated circuit, they are still representative of metrics like IPC.

An FPGA is less flexible than a simulator in that the code has to go through synthesis and unsynthesisable features therefore become unavailable.
Additionally, FPGAs are less flexible in how certain language elements are implemented.
This means that some features that are synthesisable in one technology may be unsynthesisable in a different technology.
One example is tri-state buffers that allow an output to both source and sink current, or be electrically disconnected.
FPGAs usually have tri-state ports on the chip interface (the input and output ports to the chip) and generally don't support tri-state logic internally, which then has to be implemented some other way.

== Logic Synthesis: From Register-Transfer Level to Logic Gates

As shown in @fig:case-synthesis, translation from HDL to a circuit can be simple.
This is the job of synthesis.
The abstract circuit behaviour described by the HDL must be translated to a concrete implementation in terms of logic gates made from transistors.

Logic synthesis tools will use primitives with various different implementations depending on timing requirements.
A physically larger circuit can often have a shorter delay#footnote[See carry look-ahead adders.].

=== Circuit Optimisation

The circuit in @fig:case-synthesis was generated naively and contains a path that has to go through more logic than necessary; the maximal delay of the circuit is higher than it needs to be.
There are many transformations that can be performed on the circuit that preserve correct behaviour.

==== Restructuring

One example is turning a cascaded sequence of muxes---like the one in @fig:case-synthesis ---into a tree as shown in @fig:mux-tree.
This reduces the number of muxes that a signal must pass through to get to the final output without increasing the number of components needed.
The important thing here is that the longest possible delay is reduced.

#figure(
  ```monosketch
    │          
  ─┬┴┐  │           
   │M├─┬┴┐       
  ─┴─┘ │M├┐ │     
      ─┴─┘└┬┴┐    
      ─┬─┐ │M├─  
       │M├─┴─┘   
      ─┴┬┘    
        │       
  ```,
  caption: "Turning the staggered muxes into a tree",
  kind: image,
)<fig:mux-tree>

The longest possible path a signal can take between a flip-flop output and another flip-flop input---in terms of delay---is called the _critical path_.
There may be physically long wires with short delays.
Optimisation will iteratively focus on shortening the longest path by replacing circuits along it with ones that shorten the delay.

==== Retiming

Another important optimisation is _retiming_ where flip-flops and latches are moved, inserted, or removed in the circuit in a way that preserves behaviour at the output @bib:retiming.
For example, in the circuit shown, the result is assigned to an output in a way that should infer a flip-flop.
However, if the output of this circuit is immediately assigned to a flip-flop again by a consumer, there is an imbalance where a lot of logic is done in the first circuit, but no logic (and thus, inconsequential delay) is performed between the output flip-flop and the next flip-flop.

A synthesising process will recognise this situation and move the output flip-flop into the circuit, so that some of the logic occurs before the flip-flop, and some of it happens after it.
This way, the clock frequency can be increased because the longest path between flip-flops is shortened.

Because of this retiming, it is often not necessary to be explicit about manually balancing logic between flip-flops.
It is possible to do complex, slow logic, then assign the result to a chain of flip-flops and let the retiming algorithm deal with balancing the timing of the circuit.

Optimisations like these are only possible because the code conveys _intent_.
The language standard does not require that each signal used by the programmer actually exists in the final implementation, only that the circuit behaves _as if_.
I.e., behaviour is only required to be preserved at the inputs and outputs of the system.

=== Place and Route

The final step in the process is _place and route_ in which the individual transistors are placed in space and are connected by wires.
The rules of place and route are dictated by the underlying technology to be used.
Certain designs that are simple to implement when creating integrated circuits, can be complicated to implement when using an FPGA.
High-level designs can be optimised for the underlying technology, but it requires having the knowledge of how constructs translate to the underlying technology.
Place and route ties together with higher level logic synthesis and optimising a circuit is an iterative process.

It is normal for certain common circuits to be designed by hand.
Place and route will use these circuits as building blocks for the larger circuit.
_Static random access memory_ (SRAM) blocks are often hand-designed to optimise for area and power usage.
