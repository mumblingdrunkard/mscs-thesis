= Computer Architecture Fundamentals <ch:comp.arch.-fundamentals>

By the nature of the genre (master's theses), this text is targeted at those graduating from a programme in computer science or similar.
Let $A$ be the set of all computer science students, and $B$ be the set of all computer science students that specialise in computer architecture.
Supposedly, $A != B$.
That is to say: there are computer science students that do not study computer architecture; or in mathematical terms: $B #math.subset.neq A$ ($B$ is a proper subset of $A$).

The goal of this chapter is to equip the reader with foundational knowledge required to understand the discussions within this thesis and to establish common terminology.

This thesis revolves around _reduced instruction set computers_ (RISC).
Though the history and debate around _complex instruction set computers_ (CISC) vs. RISC is interesting and could contribute to understanding the evolution of processing, we have decided to omit it for brevity. 

#{
  include "./abstractions-and-implementations.typ"
  include "./anatomy-of-an-in-order-pipelined-processor.typ"
  include "./scaling-up.typ"
  include "./memory-and-caching.typ"
  include "./high-performance-processor-architecture.typ"
}

= Processor security

== Attacks on In-Order Processors

=== Defending Against Attacks on In-Order Processors

== Attacks on Out-of-Order Processors

=== Speculative Execution Vulnerabilities in Common Microarchitectures

=== Defending Against Attacks on Out-of-Order Processors

Not that simple.
Constant time programming does not work.

==== Secure Speculation Schemes

= Modern Hardware Design

== Register-Transfer Level and Hardware Description Languages

=== Mapping High-Level Constructs to Logic Gates

While it may be possible to think about circuits in terms of gates, registers, wires, and 
#figure(
  ```asciidraw
                                                       │   
                                                │  ──┬─┴─┐ 
                                         │  ──┬─┴─┐  │MUX├─
                                  │  ──┬─┴─┐  │MUX├──┴───┘ 
                           │  ──┬─┴─┐  │MUX├──┴───┘        
                    │  ──┬─┴─┐  │MUX├──┴───┘               
             │  ──┬─┴─┐  │MUX├──┴───┘                      
      │  ──┬─┴─┐  │MUX├──┴───┘                             
  ──┬─┴─┐  │MUX├──┴───┘                                    
    │MUX├──┴───┘                                           
  ──┴───┘                                                  
  ```,
  caption: "Staggered mux for eight inputs",
  kind: image,
)

#figure(
  ```asciidraw
             │                 
         ──┬─┴─┐               
           │MUX├─┐             
      │  ──┴───┘ │  │          
  ──┬─┴─┐        └┬─┴─┐        
    │MUX├───────┐ │MUX├─┐  │   
  ──┴───┘       └─┴───┘ └┬─┴─┐ 
                         │MUX├─
  ──┬───┐       ┌─┬───┐ ┌┴───┘ 
    │MUX├───────┘ │MUX├─┘      
  ──┴─┬─┘        ┌┴─┬─┘        
      │  ──┬───┐ │  │          
           │MUX├─┘             
         ──┴─┬─┘               
             │                 
  ```,
  caption: "Turning the staggered mux into a tree",
  kind: image,
)

=== Place and Route

// TODO: Make this its own chapter
= The Berkeley Out-of-Order Machine
  + Chisel
  + Verilator
  + 
