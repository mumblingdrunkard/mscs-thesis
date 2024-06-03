#let acronyms = (
  AGU:      ("AGUs?"       , "Address generation unit"                ),
  ALU:      ("ALUs?"       , "Arithmetic-logic unit"                  ),
  ARF:      ("ARFs?"       , "Architectural register file"            ),
  Assembly: ("(A|a)ssembly", "Human-readable form of machine language"),
  BOOM:     ("BOOM"        , "Berkeley out-of-order machine"          ),
  CPU:      ("CPUs?"       , "Central processing unit"                ),
  DAG:      ("DAGs?"       , "Directed acyclic graph"                 ),
  DRAM:     ("DRAM"        , "Dynamic Random Access Memory"           ),
  FU:       ("FUs?"        , "Functional unit"                        ),
  HDL:      ("HDLs?"       , "Hardware description language"          ),
  VHDL:     ("VHDL"        , "VHSIC hardware description language"    ),
  VHSIC:    ("VHSIC"       , "Very high speed integrated circuit"     ),
  ILP:      ("ILP"         , "Instruction-level parallelism"          ),
  InO:      ("InO"         , "In-order"                               ),
  ISA:      ("ISAs?"       , "Instruction set architecture"           ),
  IQ:       ("IQs?"        , "Issue queue"                            ),
  JAL:      ("JALs?"       , "Jump-and link"                          ),
  L1:       ("L1s?"        , "First-level cache"                      ),
  L1d:      ("L1ds?"       , "First-level data cache"                 ),
  L1i:      ("L1is?"       , "First-level instruction cache"          ),
  L2:       ("L2s?"        , "Second-level cache"                     ),
  L3:       ("L3s?"        , "Third-level cache"                      ),
  LDQ:      ("LDQs?"       , "Load queue"                             ),
  LLC:      ("LLCs?"       , "Last-level cache"                       ),
  LSU:      ("LSUs?"       , "Load-store unit"                        ),
  MLP:      ("MLP"         , "Memory-level parallelism"               ),
  OoO:      ("OoO"         , "Out-of-order"                           ),
  OSS:      ("OSS"         , "Open source software"                   ),
  PC:       ("PCs?"        , "Program counter"                        ),
  PRF:      ("PRFs?"       , "Physical register file"                 ),
  RAM:      ("RAM"         , "Random access memory"                   ),
  RAW:      ("RAWs?"       , "Read-after-write"                       ),
  RISC:     ("RISCs?"      , "Reduced instruction set computer"       ),
  ROB:      ("ROBs?"       , "Re-order buffer"                        ),
  RR:       ("RR"          , "Register renaming"                      ),
  RTL:      ("RTL"         , "Register-transfer level"                ),
  SRAM:     ("SRAMs?"      , "Static random access memory"            ),
  STQ:      ("STQs?"       , "Store queue"                            ),
  TSO:      ("TSO"         , "Total store order"                      ),
  UCB:      ("UC(B| Berkeley)", "University of California, Berkeley"  ),
  uOP:      ("uOPs?"       , "Micro-operation"                        ),
  VLIW:     ("VLIWs?"      , "Very long instruction word"             ),
  WAR:      ("WARs?"       , "Write-after-read"                       ),
  WAW:      ("WAWs?"       , "Write-after-write"                      ),
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
