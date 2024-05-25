#let acronyms = (
  CPU: "Central Processing Unit",
  RAM: "Random Access Memory",
  PC: "Program Counter",
  BOOM: "Berkeley Out-of-Order Machine",
  MLP: "Memory Level Parallelism",
  LSU: "Load-Store Unit",
  
)

#let usedAcronyms = state("used", (:))

#let listOfAcronyms = () => locate(loc => {
    grid(columns: (auto, 1fr), align: (left, left), inset: 5pt,
      ..usedAcronyms.final().pairs().sorted().map(((acr, uses)) => { 
        (
          [*#acr*],
          [#acronyms.at(acr) #label("acronyms:" + acr)
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
  for (acr, desc) in acronyms {
    body = {
      let match = "\b" + acr + "s?\b"
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
