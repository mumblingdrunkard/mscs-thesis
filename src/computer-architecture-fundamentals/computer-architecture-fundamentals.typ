== Abstractions and Implementations

This section covers a short introduction to how boolean logic works within a computer to construct various functional components.
The last two subsections cover the essentials of a minimal instruction set for a computer, and shows how such an instruction set might be implemented in practice.

=== Turtles All the Way Down

Everything is an _abstraction_.
There are multiple layers of abstraction.
There are contracts between those layers, specifying a common language that the layer above speaks, and that the layer below understands.
When programming, a programmer is describing a program in a defined language.
The language standard defines how certain language constructs affect the _abstract machine_ of the language.

Programs are written with _intention_ and are written for _machines_.
The fundamental job of a compiler or interpreter is to take the source code and transform it into a different form that is executable on a _target machine_ while preserving the behaviour of the program as it would have executed on the abstract machine.

This target machine is no different from the abstract machine:
The interface of the target machine is defined by a document that specifies a language---instructions and instruction encodings---and the effects that this language has on the state of the machine.
This is referred to as the instruction set architecture (ISA), or "big A Architecture".

The machine specified by the ISA is also an abstraction.
Computer hardware engineers are tasked with implementing a machine that behaves like this abstract machine.
Different requirements of the hardware and its use-cases will motivate different implementations.
Some use-cases require low power consumption---others just need the most computing performance possible.

=== Logic Fundamentals

The most basic unit of computation is the transistor.
It is an electrical switch that can be flipped using electricity.
By using clever organisations of transistors, it is possible to express boolean logic.

Boolean logic concerns itself with two values: true and false, 1 and 0, yes and no, on and off, high and low.
Because individual transistors are hard to work with and don't look pretty in diagrams, they are grouped together to form basic _logic gates_ and the group is replaced by an appropriate symbol.
This is an abstraction to more easily focus on the logic and not the physical implementation, though it is still a simple mapping to do.

A logic gate has one or more inputs and outputs.
It always has the same output for the same input.
The behaviour of a logic gate is often expressed through truth tables such as the one shown in @tab:truth-tables.

#figure(caption: "Truth table for two-input, single-output AND, OR, and XOR gates", {
show "F": set text(fill: gray.darken(20%))
table(
  columns: (auto, ) * 5,
  [$p$], [$q$], [$p "AND" q$], [$p "OR" q$], [$p "XOR" q$],
  [ F ], [ F ], [         F ], [        F ], [         F ],
  [ F ], [ T ], [         F ], [        T ], [         T ],
  [ T ], [ F ], [         F ], [        T ], [         T ],
  [ T ], [ T ], [         T ], [        T ], [         F ],
)})<tab:truth-tables>

Here, the values 'F' and 'T' stand for "False" and "True", respectively.
$p$ and $q$ are the inputs and the remaining three columns show the output of three types of gates.
Logic gates can be arranged in patterns to produce all kinds of logic.

==== Selecting From Several Sources

A multiplexer, or "mux" for short, is a very fundamental kind of gate.
It has at least three inputs: $p$, $q$, and $s$, and an output $o$.
The truth table for a mux is shown in @tab:mux-truth-table.

#figure(caption: "Truth table for a two-input multiplexer", {
show "F": set text(fill: gray.darken(20%))
table(
  columns: (auto, ) * 4,
  [$p$], [$q$], [$s$], [$o$],
  [ F ], [ F ], [ F ], [ F ],
  [ F ], [ T ], [ F ], [ F ],
  [ T ], [ F ], [ F ], [ T ],
  [ T ], [ T ], [ F ], [ T ],
  [ F ], [ F ], [ T ], [ F ],
  [ F ], [ T ], [ T ], [ T ],
  [ T ], [ F ], [ T ], [ F ],
  [ T ], [ T ], [ T ], [ T ],
)})<tab:mux-truth-table>

The basic operation of a mux is that $s = "F" ==> o = p$, and $s = T ==> o = q$.
A mux can, as an example, be implemented as $(p "AND" ("NOT" s)) "OR" (q "AND" s)$.
The unary $"NOT"$-gate simply inverts its input.

==== Representing Numbers

"True" and "False" can be used to represent the ones and zeroes of a binary number.
It is simple to create a logic circuit that performs, for example, long-addition on these numbers.
The most basic version is called a _half-adder_ which takes two input bits $a$ and $b$ and sums them up.
It has two outputs: sum $s = a "XOR" b$, and carry $c = a "AND" b$.

A full-adder is like a half-adder, but it also accounts for a third input bit: carry-in.
An adder is constructed by chaining full-adders, connecting the carry output of one full-adder into the carry-in of the next.

==== Storing Information

Logic is cool, but computers also require _state_---as in "state of being".
When arranging logic gates, most would say it is a good idea to ensure the resulting network of gates is a directed acyclic graph (DAG).
That is to say: the input of any one gate cannot depend on its own output, directly or transitively; there is no path from the output of the gate back to the input.
This is called a _combinational loop_ and most tools prevent making them.

An exception is made for the _register_ cell which is constructed by using logic gates that connect back to themselves with positive feedback.
A register cell stores a value that can be read back out.
It will usually have three inputs: data $d$, write $w$, and enable $e$.
The operation of the register cell can be described thus:
When write $w$ and enable $e$ are both true, the data $d$ is stored in the cell.

@fig:register-cell-diagram shows a basic register cell as described.
Notice how the output of each of the rightmost NOT-gates feed back into each other's inputs.
Because of this feedback, when one output is "True", the other must be "False".

#figure(
  ```asciidraw
           ┌───┐
          ╭┤NOT├┬───┐
          │└───┘│AND├┬──┐ ┌───┐
          │  ╭──┴───┘│OR├─┤NOT├┬──── o
          │  │     ╭─┴──┘ └───┘│
          │  │   ╭─│───────────╯
          │  │   │ ╰───────────╮
          │  │   ╰───┬──┐ ┌───┐│
  d ──────┴──│──┬───┐│OR├─┤NOT├┴──── o'
  w ───┬───┐ │  │AND├┴──┘ └───┘
       │AND├─┴──┴───┘
  e ───┴───┘
  ```,
  caption: [A register cell using logic gates],
  kind: image,
)<fig:register-cell-diagram>

With registers in place, _time_ is introduced as a factor.
The output is no longer purely a function of the current input, but can depend on system state.
For example: the operation of a register cell is shown in @fig:register-cell-waveform.
This kind of diagram is called a _waveform_.

#figure(
  ```asciidraw
     ╭─╮ ╭─╮ ╭─╮ ╭─╮ 
  e ─╯ ╰─╯ ╰─╯ ╰─╯ ╰─
     ╭─╮         ╭─╮ 
  w ─╯ ╰─────────╯ ╰─
    ───────╮         
  d        ╰─────────
     ╭───────────╮   
  o ─╯           ╰───
  ```, 
  caption: [How the output $o$ changes over time with the three inputs for a register cell], 
  kind: image
)<fig:register-cell-waveform>

==== Register-Transfer Level

Registers and logic are the basic building blocks of the _register-transfer level_ (RTL).
This is an abstraction level where circuits are modeled as flows of data between registers.

A _clock_ signal that toggles between on and off at a steady rate can be attached to the enable input $e$ of all registers in the circuit to ensure a common time for when values change.
The space between two _rising edges_ (where the signal goes from low to high), is called a _clock cycle_.
When drawing diagrams, the clock signal is usually left out for brevity.

==== Three-Valued Logic

What happens when the register cell in @fig:register-cell-diagram goes from an unpowered state, to a powered one, assuming that the inputs $d$, $w$, and $e$ are all "False"?
If the inputs to the NOT-gates also starts out as "False", both will turn on their output, in turn turning off the other output.
This is a _race condition_, and it leads to less predictable outcomes.
It is unreliable to assume a given value when power is first supplied.

This could be solved by adding reset logic to every register.
It is sometimes useful, however, to simply treat the value as an unknown.
Introducing a "Maybe" value gives rise to a three-valued logic.
As an example, the truth table in @tab:truth-tables-3vl shows the operation of the AND and OR gates with this three-valued logic.

#figure(
  caption: [Truth-table for OR and AND with three-valued logic],
  {
    show "F": set text(fill: gray.darken(20%))
    show "M": set text(fill: gray.darken(60%))
    table(columns: (auto, ) * 4,
      $p$, $q$, $p "AND" q$, $p "OR" q$,
      [F], [F], [        F], [       F],
      [F], [M], [        F], [       M],
      [F], [T], [        F], [       T],
      [M], [F], [        F], [       M],
      [M], [M], [        M], [       M],
      [M], [T], [        M], [       T],
      [T], [F], [        F], [       T],
      [T], [M], [        M], [       T],
      [T], [T], [        T], [       T],
    )
  }
)<tab:truth-tables-3vl>

Three-valued logic is not some sort of standard.
Different systems of logic can define different values with different operators entirely.
However, for the purposes of indeterminate binary logic, this type of three-valued logic is quite suitable.
Notice that in @tab:truth-tables-3vl, changing an incoming 'M' to a 'T' or 'F' will not make an outgoing 'T' or 'F' change.

#block(breakable: false)[
=== Components of an Instruction Set Architecture

An ISA defines an abstract computer, the instructions it executes, and what the effects of those instructions are.
In this section, we cover the most basic components of such a specification.
Most ISA documents will specify all of these concepts.
]

==== Memory Space

The memory space is most often defined as an array of bytes (groups of eight bits).
Values can be read from memory at an _address_ which is an index into this large array.
Certain areas of this memory may be used for storing things like instructions and data, others can be mapped to inputs and outputs of various devices.

==== Program Counter

The _program counter_ (PC) holds the memory address of the next instruction to be executed.

==== Register File

Most ISAs say that the machine should have a set of registers, often called the _register file_.
This is storage that instructions will have fast and direct access to.
The ISA defines how many registers there should be and how large they are.
Each register in the file is assigned a number and instructions can refer to the particular register by its number.

==== Arithmetic and Logic Instructions

These instructions perform arithmetic and logic.
They read values from the register file, perform some computation with the values, and write the result to a destination in the register file.

==== Memory Instructions

Memory instructions load from or store to memory.
A load instruction has a destination register that it loads into, and a source register where the address comes from.
A store instruction has a source register where the address comes from, and another source register where the data comes from.

==== Branch and Jump Instructions

Branch instructions take two source registers and compare them.
If the result of the comparison fulfills some condition, the program counter is updated with some new value.
The new value can come from a register, but often it will be constructed by adding the current program counter to a value encoded in the instruction, called an _immediate_.
Most instruction types can have immediate values.

Jump instructions are like branch instructions, except there are no registers to compare and the condition is always true.
Jump instructions come in several variants, but _jump-and-link_ (JAL) is a common one.
Jump-and-link writes the current value of the program counter to a destination register and jumps to the specified location.
This is useful for function calls and returns.

=== A Basic Implementation

@fig:basic-computer shows a very basic implementation of a compute-capable architecture.
Components with double borders are registers (storage), while those with a single border perform logic.

#figure(
  ```asciidraw
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
- `ADDR`, the memory address to read or write from in the memory:
- `MEM`, the actual memory of the processor,
- `REG`, the register file,
- `OP1` and `OP2`, the source operands of the
- `ALU`, the _arithmetic-logic unit_, and
- `PC`, the program counter.
- Finally, there the control logic `CTRL`.

Not shown are the connections from `CTRL` to all of the other components control signals.

The solid arrowheads indicate that there is always a connection.
The unfilled arrowheads indicate that the connection is optional.
Because this architecture uses a shared bus, components must be able to not give an output to prevent interferring with the values on the bus.

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

The first thing the control logic should do is to read the next instruction from memory.
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
Notice that even a basic instruction like addition requires at least eight cycles.
There are some easy optimisations like adding a separate connection from `MEM` to `CTRL` and read the instruction address straight from the bus instead, or to add specialised hardware to increment `PC`.

=== Microarchitecture vs. Big A Architecture

The presented computer is an example of how any given ISA can be physically implemented.
It is not the only possible implementation.
Just like the language standard does not specify which machine instructions should be used to implement specific concepts, ISAs do not specify what circuits to use, or where transistors should be placed relative to each other.

Herein lies the distinction between the ISA and what is called _microarchitecture_.
For an ISA, the basic unit of a program is an instruction.
However, as we have shown, any instruction may require multiple steps like various output-enable's and write-enable's at different times.
This sequence of operations is referred to as _microcode_ and it is composed of _microoperations_ (uOPs, u resembling the Greek letter mu, the SI-prefix for micro-).

This under-specification of what an implementation must do has many advantages.
For computer hardware engineers, it gives a lot of freedom in choosing an appropriate microarchitecture for various use-cases.
