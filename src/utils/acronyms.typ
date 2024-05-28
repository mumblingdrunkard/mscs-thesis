#let acronyms = (
  ALU: ("ALUs?", "Arithmetic-logic unit"),
  Assembly: ("(A|a)ssembly", "Human-readable form of machine language"),
  BOOM: ("BOOM", "Berkeley out-of-order machine"),
  CPU: ("CPUs?", "Central processing unit"),
  DAG: ("DAGs?", "Directed acyclic graph"),
  DRAM: ("DRAM", "Dynamic Random Access Memory"),
  ILP: ("ILP", "Instruction-level parallelism"),
  ISA: ("ISAs?", "Instruction set architecture"),
  JAL: ("JALs?", "Jump-and link"),
  LDQ: ("LDQs?", "Load queue"),
  LSU: ("LSUs?", "Load-store unit"),
  MLP: ("MLP", "Memory-level parallelism"),
  PC: ("PCs?", "Program counter"),
  RAM: ("RAM", "Random access memory"),
  RTL: ("RTL", "Register-transfer level"),
  STQ: ("STQs?", "Store queue"),
  uOP: ("uOPs?", "Micro-operations"),
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
