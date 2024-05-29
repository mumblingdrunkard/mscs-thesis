== Scaling Up

There are two main ways to increase the performance of a processor to do more work in the same amount of time:
1) Increase the frequency of the clock, or
2) increase the number of instructions performed each clock cycle... somehow.
This section provides a short overview of the history of performance improvements and the mechanisms by which the performance improvements have been achieved.

=== The Easy Option: Increasing Frequency

For a while, two key phenomena dominated the improvements in processor performance: Moore's Law, and Dennard Scaling.
Moore's Law is the observation that the number of transistors that fit within a given area roughly doubles every eighteen months (later changed to every two years) because improvements in technology lead to smaller transistors.
Because everything shrinks, the physical distances get shorter, and the required energy to transmit information from A to B also shrinks.
The water analogy holds here.
If the wires between components in the chip are tubes, and the tubes have to be filled up and drained every time a bit is changed, shorter, narrower tubes require less total volume to flow.
The tubes have a lower capacity.
The electrical equivalent is _capacitance_, denoted by the symbol $C$.

The important capacitances in a circuit are those of the transistors and of the wires.
For the water analogy, transistors have buckets that must be filled or drained.
For a transistor to reliably switch on or off, the water level, or voltage, must reach above or below a certain threshold.
Capacitance in a circuit means that after applying a voltage at one end, it takes some time before the other end reaches that same voltage.
Transistors also have an internal _transition time_, the time it takes for the output to reliably change after changing an input.
This time is proportional to the capacitance.
The maximum frequency of the circuit is governed by delays, which are in turn dominated by this transition time.
The frequency of the transistor cannot exceed $1/d_max$ where $d_max$ is the maximum delay from one register to the next.

A basic equation governs the power consumption of processors:
$
  P = alpha f C V^2
$
Dynamic power consumption (power consumed due to signals turning on and off within the circuit) is equal to the frequency of switching, multiplied by the capacitance of the circuit, multiplied by the square of the applied voltage.
This is scaled by some scaling factor $alpha$.

Due to physical properties, a reduction in transistor size causes an approximately equal reduction in capacitance and voltage.
With an equal shrinking voltage, the transition time still decreases in proportion to the transistor shrink.
Because the transition time decreases, the delay decreases, and the frequency can be scaled up and performance can be increased.
With these different factors, it can be shown that as technology improves and transistors shrink, the _power density_ stays approximately constant.
That is, each square millimetre of circuit has approximately the same power output, no matter the technology.
Conversely: the same circuit can be implemented in less area, using less power, all while running faster.

This is Dennard Scaling: the observation that power density stays the same across improvements in technology.
To get a faster and more power-efficient processor: wait.

These two "laws" stood for much of the improvements in processor performance until Dennard Scaling started breaking down around two decades ago.
The number of transistors per area has still been increasing steadily---albeit at a slower pace---but the frequency increases have been much, much smaller.
The reason for this is mostly attributed to static power (power needed just because the circuit is turned on without any computation going on) becoming a larger factor as transistors shrink.

To meet performance goals, companies started turning up frequencies more than Dennard Scaling allowed for.
To increase the frequency beyond the max frequency, the voltage must be tuned up to decrease the delays.
This causes the power output to scale with the cube of the frequency increase, which has necessitated more powerful cooling to keep up with the increased heat output.

=== Scaling Horizontally

The second alternative to increase work per second is to scale horizontally by adding more units that can perform execution.
This still works quite well as the number of transistors per area keeps increasing: this extra area can be spent on more execution units.
This category can be split into two further groups:

==== Adding Cores

Most high-performance computers are systems that run a wide variety of programs at the same time.
By adding more cores to the processor, multiple applications can be executed in parallel.
This does not directly speed up programs that are not explicitly written to use many cores.
However, in a system with many tasks, and only a single core, the system must divide time on the processor between each of the tasks.
By adding more cores, more time becomes available to each task.

==== Superscalar Processors

Though adding cores helps for overall system performance, and for workloads written with multiple cores in mind, it cannot speed up programs that are written for a single core.
Some programs can be rewritten to take advantage of multiple cores.
Others require so much fine-grained synchronisation between the cores that the overhead of synchronisation negates any benefit.

However, these programs are still likely to have a lot of available ILP, even if they are too serial to be split across many cores.
This is where _superscalar processing_ helps.
Superscalar processing attempts to exploit available ILP to complete more than one instruction per cycle.
It is possible to construct a superscalar pipelined processor by simply doubling up all of the units shown in @fig:pipelined-cpu.
Two IF stages, two ID/OF stages... etc. that all run in parallel.

This adds some complexity in handling hazards.
The forwarding logic becomes twice as complex and instead of 3 bundles of connections running from various pipeline registers, there are 12.
It must also be ensurred that two instructions entering at the same time do not depend on each other, or the later instruction must somehow be stalled.
This can be dealt with.

Increasing the number of pipelines to three worsens the problem.
The forwarding logic increases from 12 to 27 wire bundles.

=== Scaling Complexity

Generally, naive scaling like this turns out to be quadratic for integral parts of the circuit.
One way to tackle the problem is to use static scheduling with _very long instruction words_ (VLIW) and design the ISA such that instructions cannot depend on results that are generated in other pipelines until they are written back to the register file.
VLIW requires that the programmer (or more likely: the compiler) must find instructions that can safely be executed in parallel and group them together in a packet.
Where a single instruction is usually just called an instruction word, this packet of multiple instructions is called a very long instruction word.
This allows all the forwarding logic and dependency detection to be removed.

This moves complexity over to the programmer (or more likely: the compiler) who has to find suitable groups of instructions and where to put them.
However, it has its own set of issues with scaling into the future where code written with one width in mind cannot benefit from increased execution width.

Modern processors use various techniques to efficiently tackle this scaling without increasing complexity for compilers and programmers.
This is explained further in @sec:high-performance-processor-architecture.
