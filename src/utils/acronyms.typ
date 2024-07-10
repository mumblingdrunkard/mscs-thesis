#let acronyms = (
  // Assembly: ("(A|a)ssembly", "Human-readable form of machine language"),
  AGU:      ("AGUs?"       , "Address generation unit"                ),
  ALU:      ("ALUs?"       , "Arithmetic-logic unit"                  ),
  ARF:      ("ARFs?"       , "Architectural register file"            ),
  BOOM:     ("BOOM"        , "Berkeley out-of-order machine"          ),
  CPI:      ("CPI"         , "Cycles per instruction"                 ),
  CPU:      ("CPUs?"       , "Central processing unit"                ),
  CSR:      ("CSRs?"       , "Control and status registers"           ),
  DAG:      ("DAGs?"       , "Directed acyclic graph"                 ),
  DCPT:     ("DCPT"        , "Delta-correlating prediction tables"    ),
  DoM:      ("DoM"         , "Delay-on-miss"                          ),
  DRAM:     ("DRAM"        , "Dynamic Random Access Memory"           ),
  DSL:      ("DSLs?"       , "Domain-specific language"               ),
  FU:       ("FUs?"        , "Functional unit"                        ),
  HDL:      ("HDLs?"       , "Hardware description language"          ),
  ILP:      ("ILP"         , "Instruction-level parallelism"          ),
  IPC:      ("IPC"         , "Instructions per cycle"                 ),
  IPS:      ("IPS"         , "Instructions per second"                ),
  IQ:       ("IQs?"        , "Issue queue"                            ),
  ISA:      ("ISAs?"       , "Instruction set architecture"           ),
  InO:      ("InO"         , "In-order"                               ),
  JAL:      ("JALs?"       , "Jump-and link"                          ),
  L1:       ("L1s?"        , "First-level cache"                      ),
  L1d:      ("L1ds?"       , "First-level data cache"                 ),
  L1i:      ("L1is?"       , "First-level instruction cache"          ),
  L2:       ("L2s?"        , "Second-level cache"                     ),
  L3:       ("L3s?"        , "Third-level cache"                      ),
  LDQ:      ("LDQs?"       , "Load queue"                             ),
  LLC:      ("LLCs?"       , "Last-level cache"                       ),
  LSU:      ("LSUs?"       , "Load-store unit"                        ),
  MIPS:     ("MIPS"        , "Millions of instructions per second"    ),
  MLP:      ("MLP"         , "Memory-level parallelism"               ),
  MSHR:     ("MSHRs?"      , "Miss status holding register"           ),
  NDA:      ("NDA"         , "Non-speculative data access"            ),
  OS:       ("OSs?"        , "Operating system"                       ),
  OSS:      ("OSS"         , "Open source software"                   ),
  OoO:      ("OoO"         , "Out-of-order"                           ),
  PC:       ("PCs?"        , "Program counter"                        ),
  PRF:      ("PRFs?"       , "Physical register file"                 ),
  RAM:      ("RAM"         , "Random access memory"                   ),
  RAW:      ("RAWs?"       , "Read-after-write"                       ),
  RFP:      ("RFPs?"       , "Register file prefetching"              ),
  RISC:     ("RISCs?"      , "Reduced instruction set computer"       ),
  ROB:      ("ROBs?"       , "Re-order buffer"                        ),
  RR:       ("RR"          , "Register renaming"                      ),
  RTL:      ("RTL"         , "Register-transfer level"                ),
  SRAM:     ("SRAMs?"      , "Static random access memory"            ),
  STQ:      ("STQs?"       , "Store queue"                            ),
  STT:      ("STT"         , "Speculative taint tracking"             ),
  TSO:      ("TSO"         , "Total store order"                      ),
  TVM:      ("TVMs?"       , "Test virtual machine"                   ),
  UCB:      ("UC(B| Berkeley)", "University of California, Berkeley"  ),
  VHDL:     ("VHDL"        , "VHSIC hardware description language"    ),
  VHSIC:    ("VHSIC"       , "Very high speed integrated circuit"     ),
  VLIW:     ("VLIWs?"      , "Very long instruction word"             ),
  VP:       ("VPs?"        , "Value prediction"                       ),
  WAR:      ("WARs?"       , "Write-after-read"                       ),
  WAW:      ("WAWs?"       , "Write-after-write"                      ),
  eDSL:     ("eDSLs?"      , "Embedded domain-specific language"      ),
  uOP:      ("uOPs?"       , "Micro-operation"                        ),
)

#let usedAcronyms = state("used", (:))

#let listOfAcronyms = () => locate(loc => {
    grid(columns: (auto, 1fr), align: (left, left), inset: 5pt,
      ..usedAcronyms.final().pairs().sorted().map(((acr, uses)) => { 
        (
          [*#acr*],
          [#acronyms.at(acr).at(1) #label("acronyms:" + acr)
          #box(repeat(" ."), width: 1fr)
          #box(width: 5pt)
          #uses.dedup(key: use => use).map(use => {
            link(use)[#use.page()]
          }).join(", ")],
        ) 
      }).flatten()
    )
  }
)

#let enableAcronyms(body) = {
  for (acr, (expr, desc)) in acronyms {
    body = {
      let match = "\b" + expr + "\b"
      show regex(match): (it) => {
        locate(loc => {
          usedAcronyms.update(used => {
            if used.keys().contains(acr) {
              if used.at(acr).last().page() != loc.page() {
                used.at(acr).push(loc)
              }
            } else {
              used.insert(acr, (loc,))
            }
            used
          })
          link(label("acronyms:" + acr), it)
        })
      }
      body
    }
  }
  body
}
