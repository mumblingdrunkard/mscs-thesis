= Background

#{
  include("./01-anatomy-of-an-in-order-pipelined-processor.typ")
  include("./02-memory-and-caching.typ")
  include("./03-security-of-an-in-order-pipelined-processor.typ")
  include("./04-high-performance-processor-architecture.typ")
}

#figure(caption: "BOOM CPU Architecture", image("diagrams/cpu.svg"))

+ High-performance Caches

+ Security
  + Spectre and Meltdown
  + Patching the Hole II: Constant-time programming does not work
  + Patching the Hole III: Secure speculation schemes

+ Doppelganger Loads

+ Hardware Design
  + Turtles All the Way Down
    + Hang on... they're all abstractions?
  + Limiting Factors
    + Complexity (Critical Path)
    + Power Consumption
  + Managing Complexity
    + Reducing Port Counts
    + Reducing Dependencies
    + Increasing Number of Pipeline Stages
  + Managing Power

+ BOOM
  + Chisel
  + Verilator

+ Previous Paper
