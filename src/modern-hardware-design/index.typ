= Modern Hardware Design

Throughout this thesis, we discuss relations between abstract representations of circuits and their actual implementation as transistors and wires.

== Register-Transfer Level and Hardware Description Languages

Modern processors are not designed as sequences of logic gates and registers in large diagrams.
They are far too complex for that.
Logic gates are also too concrete for the algorithms used when optimising designs, described later in this chapter.

Instead, modern hardware is designed using _hardware description languages_ (HDL): code that describes registers and logic and how they are connected.
Popular languages include the _VHSIC hardware description language_ (VHDL) @bib:vhdl-standard, and _SystemVerilog_ @bib:systemverilog-standard.

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
        default : result = in_a + in_b;
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
Logic and registers are _inferred_ and are not explicitly declared by the programmer.

First off, the code in @lst:systemverilog-example declares a module called `alu` that has six inputs: `clk`, `nrst`, `in_a`, `in_b`, `in_op`, and `in_valid`.
The types of these inputs can be user-defined like `word_t` and `op_t` or one of the primitive types like `logic`.
The module also declares two outputs `out_valid` and `out_value`.
Within the module, more variables are created for `value`, `valid` and `result`.

A procedure is declared with `always_comb` indicating the intent that the logic contained within is purely combinational.
Here, a `case`-statement uses the `in_op` value to select between one of several operators and assigns the result to the `result` variable.
In SystemVerilog `=` is a _blocking assignment_, meaning all subsequent operations in the procedure use the new value.
The default case ensures `result` is always assigned to something, no matter the value of `in_op`.
The outputs are also set to match the internal values `value` and `valid`.

Next follows another procedure `always_ff` indicating the intent that the logic within will be sequential.
This logic only triggers on the positive edge of `clk` or on the negative edge of `nrst`.
Then, if `nrst` is false (if `!nrst` is true), set the `valid` value to 0 using a _non-blocking assignment_ (`<=`).
A non-blocking assignment is different in that the assignment only takes effect at the end of the simulation cycle.
Other operations continue using the same `valid` until the next simulation cycle.
Otherwise, if `!nrst` is false, the code checks whether the `in_valid` signal is high, and if it is, sets the `value` to the `result`.
`valid` is always written to be the `in_valid` value as long as the circuit is not reset by `nrst` going low.

=== Mapping High-Level Constructs to Logic Gates

As mentioned, we are mostly concerned with the synthesisable subset of the discussed HDLs.
As part of that, we should describe how different HDL code can be synthesised into actual hardware.

For example, the case-statement can be represented as a series of `if`-`else if`-`else` statements, which can be constructed in hardware as a series of muxes, as shown in @fig:case-synthesis.
Here, there are five units that perform the respective operations.
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

To synthesise non-blocking assignments, registers will be inferred to store values between cycles.

=== Scaling Circuits

With HDLs, it may be easy to forget that the circuit is supposed to go through synthesis.
For example: variable indexing in arrays requires a mux network for each place the array is indexed.
Adding more ports to read from an array of values can be expensive.

This is even more true for arrays of registers.
Ports dedicated to writing to registers are much more expensive to implement than read ports.
For multiple instructions to write back their results to the PRF, it must have multiple ports for writing.
Naive scaling is expensive and a lot of research has been done to reduce the number of actual ports needed in the register file @bib:banked-register-files.

== Testing Designs

There are several ways to go about testing hardware designs.
Unsynthesisable features of HDLs are included exactly because they are useful for testing circuit behaviour.

=== Simulation of Register-Transfer Level

The first alternative is to run the code in a simulator.
A simulator takes the code and runs it according to the lanugage standard.
A popular simulator is _Verilator_ @bib:verilator which accepts SystemVerilog and translates it to a multithreaded model that can be executed on the host system.

=== Field-Programmable Gate Arrays

When the design has been tested in a simulator and correct behaviour is confirmed, it is common to prototype the circuit on a _field-programmable gate array_ (FPGA).
An FPGA is a large canvas of _look-up tables_ (LUT) that can be programmed to provide a given output for any given input.
The simplest possible LUT has two inputs and a single output.
Within it are four register cells that can be selected by using the two inputs as an address.
The values of the four register cells can be programmed to any values.
Wires between the LUTs and other components like registers can be programmed in a similar fashion to decide which components are connected together.
A two-input LUT can act as any logic gate by programming it with the same behaviour as the appropriate truth table.

With a proper bit-stream and enough components, an FPGA can be programmed to act like any circuit.
FPGAs are much faster than simulators, and even though they are slower than creating a dedicated circuit, they are still representative of metrics like _instructions per cycle_.

== Logic Synthesis: From Register-Transfer Level to Logic Gates

As shown in @fig:case-synthesis, translation from HDL to a circuit can be quite simple and easy.
This is the job of synthesis.
The abstract circuit behaviour described by the HDL must be translated to a concrete implementation in terms of logic gates.

Real logic synthesis tools will generally use larger primitives, often with various different actual implementations depending on the needs.
Often, a larger circuit can have a lower latency#footnote[See carry look-ahead adders.].

=== Circuit Optimisation

The circuit was generated naively and contains a critical path that has to go through more blocks than necessary.
There are many transformations that can be performed on the circuit that preserve correct behaviour.

One example is turning a cascaded sequence of muxes---like the one in @fig:case-synthesis ---into a tree as shown in @fig:mux-tree.
This reduces the number of muxes that a signal must pass through to get to the final output.

#figure(
  ```monosketch
      │          
   ──┬┴┐  │           
     │M├─┬┴┐       
   ──┴─┘ │M├┐ │     
        ─┴─┘└┬┴┐    
        ─┬─┐ │M├─  
         │M├─┴─┘   
        ─┴┬┘    
          │       
  ```,
  caption: "Turning the staggered muxes into a tree",
  kind: image,
)<fig:mux-tree>

=== Place and Route

Another step in the process is _place and route_ in which the individual logic gates are placed in space and are connected by wires.
The rules of place and route are dictated by the underlying technology to be used.
Place and route ties together with higher level logic synthesis and optimising a circuit is an iterative process.

The longest possible path a signal can take between a register output and another register input is called the critical path.
Here, longest means the one with teh longest delay.
There may be physically long wires with short delays.
Optimisation will iteratively focus on shortening the longest path by replacing circuits along it with ones that shorten the delay.

It is common for certain circuits with defined behaviours to be hand-designed.
Place and route will use these hand-designed circuits as building blocks for the larger circuit.
_Static random access memory_ (SRAM) blocks are often hand-designed to optimise for area and power usage.
