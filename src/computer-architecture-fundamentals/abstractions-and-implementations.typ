== Abstractions and Implementations

Most everything in the field of computing an _abstraction_.
There are multiple _layers_ of abstraction.
There are contracts/interfaces between those layers, specifying a common _language_ that the layer above speaks, and that the layer below understands.
A programmer describes a program in a defined language.
The language standard defines how parts of the language affect an _abstract machine_.

Programs are written with _intent_ and are written for _machines_.
The fundamental job of a compiler or interpreter is to take the program code and transform it into a different form that is executable on a _target_ machine while preserving the behaviour of the program (the intent) as it would have executed on the abstract machine.

This target machine is no different from the abstract machine:
The interface of the target machine is defined by a document that specifies a language---_instructions_ and instruction _encodings_---and the effects that this language has on the state of the machine.
This is referred to as the _instruction set architecture_ (ISA).
When programmers write this language, it is usually in the form of _assembly_ which is a human-readable encoding that has a direct and obvious mapping to the machine version of the same language.

The machine specified by the ISA is an abstraction.
Computer hardware engineers are tasked with _implementing_ a machine that behaves like this abstract machine using transistors and wires.
Different requirements of the hardware and its use-cases will motivate different implementations.
Some use-cases require low power consumption---others might require the most computing performance possible.

=== Logic Fundamentals

The most basic unit of computation is the transistor.
It is a switch that can be turned on or off using electricity.
By using clever organisations of transistors, it is possible to express boolean logic.

Boolean logic concerns itself with two values: true and false, 1 and 0, yes and no, on and off, high and low.
Because individual transistors are hard to work with and do not look pretty in diagrams, they are grouped together to form basic _logic gates_ and the group is replaced by an appropriate symbol.
This is an abstraction to more easily focus on the logic and not the physical implementation, though it is a trivial mapping, like assembly to machine code.

A logic gate has one or more inputs and outputs.
It always has the same output for the same input.
The behaviour of a logic gate can be expressed through truth tables such as the one shown in @tab:truth-tables.

#figure(caption: "Truth table for two-input, single-output AND, OR, and XOR gates", {
show "F": set text(fill: gray.darken(20%))
table(
  columns: (auto, ) * 5,
  $p$, $q$, $p "AND" q$, $p "OR" q$, $p "XOR" q$,
  [F], [F], [        F], [       F], [        F],
  [F], [T], [        F], [       T], [        T],
  [T], [F], [        F], [       T], [        T],
  [T], [T], [        T], [       T], [        F],
)})<tab:truth-tables>

Here, the values 'F' and 'T' stand for "False" and "True", respectively.
$p$ and $q$ are the inputs and the remaining three columns show the output of three types of gates.
Logic gates can be arranged in larger circuits to do more useful work.

==== Selecting From Several Sources

As an example of how gates can be arranged in larger circuits, a multiplexer, or "mux" for short, is a very fundamental kind of circuit.
It has at least three inputs: $p$, $q$, and $s$, and an output $o$.
The truth table for a mux is shown in @tab:mux-truth-table.

#figure(caption: "Truth table for a two-input multiplexer", {
show "F": set text(fill: gray.darken(20%))
table(
  columns: (auto, ) * 4,
  $p$, $q$, $s$, $o$,
  [F], [F], [F], [F],
  [F], [T], [F], [F],
  [T], [F], [F], [T],
  [T], [T], [F], [T],
  [F], [F], [T], [F],
  [F], [T], [T], [T],
  [T], [F], [T], [F],
  [T], [T], [T], [T],
)})<tab:mux-truth-table>

The basic operation of a mux is that $s = "F" ==> o = p$, and $s = "T" ==> o = q$.
In other terms: when $s$ is false, the output is set to the first input and when $s$ is true, the output is set to the second input;
$s$ _selects_ which input to assign to the output.
A mux can, as an example, be implemented as $(p "AND" ("NOT" s)) "OR" (q "AND" s)$.
The unary $"NOT"$-gate simply inverts its input.

==== Working with Numbers

"True" and "False" can be used to represent the ones and zeroes of a binary number.
It is simple to create a logic circuit that performs, for example, long-addition on these numbers.
The most basic version is called a _half-adder_ which takes two input bits $a$ and $b$ and sums them up.
It has two outputs: sum $s = a "XOR" b$, and carry $c = a "AND" b$.

A _full-adder_ is like a half-adder, but it also accounts for a third input bit: carry-in.
An adder is constructed by chaining full-adders, connecting the carry output of one full-adder into the carry-in of the next.

==== Circuits with Memory

Logic is useful, but computers require _state_---as in "state of being".
When building circuits, it is a good idea to ensure logic does not directly depend on its own result.
That is to say: the input of any one gate cannot depend on its own output, directly or transitively; there is no path from the output of the gate back to the input.
Such a path is called a _combinational loop_ and most tools prevent making them.

An exception is made for the _register_ cell which is constructed by using logic gates that connect back to themselves with positive feedback.
A register cell _stores_ data that can be read back out at a later time.
It will usually have two inputs: data $d$, and enable $e$.
The operation of the register cell can be described thus:
When enable $e$ is true, the data $d$ are stored in the cell.

@fig:register-cell-diagram shows a basic register cell as described.
Notice how the output of each of the rightmost NOT-gates feed back into each other's inputs.
Because of this feedback, when one output is "True", the other must be "False".

#figure(
  ```monosketch
           ┌───┐
          ╭┤NOT├┬───┐
          │└───┘│AND├┬──┐ ┌───┐
          │  ╭──┴───┘│OR├─┤NOT├┬──── o
          │  │     ╭─┴──┘ └───┘│
          │  │   ╭─│───────────╯
          │  │   │ ╰───────────╮
          │  │   ╰───┬──┐ ┌───┐│
  d ──────┴──│──┬───┐│OR├─┤NOT├┴──── o'
             │  │AND├┴──┘ └───┘
  e ─────────┴──┴───┘
  ```,
  caption: [A register cell using logic gates],
  kind: image,
)<fig:register-cell-diagram>

With registers in place, _time_ is introduced as a factor.
The output of the circuit is no longer purely a function of the current input, but can depend on previous inputs and an initial state.
For example: the operation of a register cell is shown in @fig:register-cell-waveform.
This kind of diagram is called a _waveform_.

#figure(
  ```monosketch
     ╭─╮ ╭─╮     ╭─╮ 
  e ─╯ ╰─╯ ╰─────╯ ╰─
    ───────╮         
  d        ╰─────────
     ╭───────────╮   
  o ─╯           ╰───
  ```, 
  caption: [How the output $o$ changes over time with the three inputs for a register cell], 
  kind: image
)<fig:register-cell-waveform>

The storage element shown here is actually called a _latch_ and it updates continuously while the enable signal $e$ is active.
Another kind of register cell is the _flip-flop_ which can be constructed from two latches where the output of the first one (called the master), is fed into a second (called the slave).
The enable input of the slave latch $e'$ is the inverted value of the enable input $e$ of the master latch.
In this way, the master latch can receive an updated value while signal is high, and the slave latch is only updated once the clock signal goes low again.
It is difficult to ensure all latches update at the same time in a reliable manner.
Because of this, registers are usually implemented using flip-flops to give more tolerance.

==== Register-Transfer Level

Registers and combinational logic are the basic building blocks of the _register-transfer level_ (RTL).
This is an abstraction level where circuits are modelled as flows of data between registers.

A _clock_ signal that toggles between on and off can be attached to the enable input $e$ of all registers in the circuit to ensure a common time for when values change.
The space between two _rising edges_ (where the signal goes from low to high), is called a _clock cycle_.
When drawing diagrams, the clock signal is often left out for brevity.

=== Elements of an Instruction Set Architecture

An ISA defines an abstract machine, the instructions it executes, and what the effects of those instructions are.
That is, an implementation should behave as if there is some set of resources, and instructions that use and modify those resources.
In this section, we cover the most basic elements of such a specification.
Most ISA documents will specify all of these concepts.

==== Memory Space

Values can be loaded from or stored to memory at an _address_ which is an index into a large array of values.
Different ranges of addresses may be mapped to different types of memory.
The main memory stores program data and instructions and has no side-effects---i.e. using load and store instructions on the main memory has no other observable effect than to read or write those values.
Other address ranges may be mapped to various devices and can have side-effects.

ISAs designed for running operating systems usually contain specifications for _memory virtualisation_.
Virtualised memory uses _virtual addresses_ and a _translation_ scheme to translate from these virtual addresses to the "real" physical addresses.
This way, individual applications can access the same virtual address, but refer to different values.
Thus, an operating system can, for example, start two instances of the same program without them interferring with each other's values.

Modern virtual memory is handled at the granulaity of _pages_ where a fixed size virtual address range is mapped continuously to an equally sized section in physical memory.
Pages that are adjacent---according to their addresses---in virtual memory are not necessarily adjacent in physical memory.

Virtual memory is transparent.
I.e.: it does not matter to an individual application whether the memory space it uses is virtualised or not.

==== Program Counter

The _program counter_ (PC) holds the memory address of the next instruction to be executed.

==== Register File

Most ISAs state that the machine should have a set of registers, often called the _register file_.
This is storage that instructions will have fast and direct access to.
The ISA defines how many registers there should be and how large they are.
Each register in the file is assigned a number and instructions can refer to the particular register by its number.

==== Arithmetic and Logic Instructions

These instructions perform arithmetic and logic.
They read values from the register file, perform some computation with the values, and write the result to a destination in the register file.

==== Memory Instructions

Memory instructions load from or store to memory.
A load instruction has a destination register that it loads into, and a source register where the address comes from.
A store instruction has a source register where the address comes from, and another source register where the data come from.

==== Branch and Jump Instructions

Branch instructions take two source registers and compare them.
If the result of the comparison fulfills some condition, the program counter is updated with some new value.
The new value can come from a register, but often it will be constructed by adding the current program counter to a value encoded in the instruction, called an _immediate_.
Most instruction types can have immediate values.

Jump instructions are like branch instructions, except there are no registers to compare and the condition is always true.
Jump instructions come in several variants, but _jump-and-link_ (JAL) is a common one.
Jump-and-link writes the current value of the program counter to a destination register and jumps to the specified location.
This is useful for function calls and returns.

==== Instruction Encoding Formats

Along with instructions and their effects, the ISA document must also specify what instructions "look like" to the processor: which sequences of bits and bytes correspond to each instruction.

=== A Basic Implementation

@fig:basic-computer shows an implementation of a compute-capable architecture.
Components with double borders are registers (storage), while those with a single border perform logic.

#figure(
  ```monosketch
  ┏ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━   ╔════╗         ╔════════╗
                       ┃  ║ADDR◀─────┐◁──▶  REG   ║
  ┃                       ╚═╤══╝     │   ╚════════╝
                       ┃  ╔═▼════╗   ├─────┬────┐  
  ┃        CTRL           ║ MEM  ◀──▷│   ╔═▼═╗╔═▼═╗
                       ┃  ╚══════╝   │   ║OP1║║OP2║
  ┃                    ◀────────────▷│   ╚═╤═╝╚═╤═╝
                       ┃  ╔══════╗   │   ┌─▼────▼─┐
  ┃                       ║  PC  ◀──▷│◁──┤  ALU   │
   ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ┛  ╚══════╝       └────────┘
  ```,
  caption: [A basic computer with a shared bus],
  kind: image,
)<fig:basic-computer>

The components are as follows:
- The shared bus, which is the line that runs vertically between the components,
- `ADDR`, the memory address to load from or store to in the memory:
- `MEM`, the memory of the processor,
- `REG`, the register file,
- `OP1` and `OP2`, the source operands of the
- `ALU`, the _arithmetic-logic unit_, and
- `PC`, the program counter.
- Finally, the control logic: `CTRL`.

Not shown are the connections from `CTRL` to all of the other components control signals.

The solid arrowheads indicate that there is always a connection.
The unfilled arrowheads indicate that the connection is optional.
Because this architecture uses a shared bus, components must be able disconnect their outputs from the bus to prevent interferring with values from other components.

==== Control Signals

- `ADDR`, `OP1`, and `OP2` all have input signals for write-enable.
- `MEM` has an input signal for write-enable and another for output-enable that controls whether `MEM` is outputting to the bus, in addition to the address coming from `ADDR`.
- `REG` also has input signals for write-enable and output-enable, but also has an input signal for register-select that selects which register is being read or written.
- `PC` only has write-enable and output-enable signals.
- `ALU` has a function-select signal that specifies what operation it should perform on the two values in `OP1` and `OP2` (add, subtract, compare...).
  It also has an output-enable.

==== Control Logic

Without going into too much detail, the control logic contains components that interpret encoded instructions and determine what and when control signals should be set to certain values to perform the instructions.
We will assume everything runs on a common clock.

The first thing the control logic should do is to load the next instruction from memory.
Cycle for cycle:
+ `PC` output-enable, `ADDR` write-enable.
+ `MEM` output-enable, `CTRL` stores the resulting value from the bus in some internal register.

If the instruction is an addition, the following should happen:
+ `REG` register-select set to first source register, `REG` output-enable, `OP1` write-enable.
+ `REG` register-select set to second source register, `REG` output-enable, `OP2` write-enable.
+ `ALU` function-select set to addition, `ALU` output-enable, `REG` register-select set to destination register, `REG` write-enable.

The `PC` then needs to be updated by incrementing the stored value:
+ `PC` output-enable, `OP1` write-enable.
+ `CTRL` puts increment value on bus, `OP2` write-enable.
+ `ALU` output-enable, `PC` write-enable.

And so it continues.
Notice that even a basic instruction like addition requires at least eight cycles---likely more, as the control logic has to determine which operations to perform in each step.
There are some easy optimisations like adding a separate connection from `MEM` to `CTRL` and read the instruction address straight from the bus instead, or to add specialised hardware to increment `PC`.

=== Microarchitecture vs. Big A Architecture

The presented computer is an example of how any given ISA can be physically implemented.
It is not the only possible implementation.
Just like the language standard does not specify which machine instructions should be used to implement specific concepts, ISAs do not specify what circuits to use, or where transistors should be placed relative to each other.

Herein lies the distinction between the ISA and what is called _microarchitecture_.
For an ISA, the basic unit of a program is an instruction.
However, as shown, any single instruction may require multiple steps such as various output-enable's and write-enable's at different times.
These steps are called _micro-operations_ (uOPs, u resembling the Greek letter #math.mu, the SI-prefix for micro-).

This under-specification of what an implementation must do gives a lot of freedom in choosing an appropriate microarchitecture for various use-cases.
Throughout this thesis, we present and discuss various microarchitectural patterns and optimisations.
