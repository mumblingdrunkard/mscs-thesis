#let acronyms = (
  OS: "Operating System",
  CPU: "Central Processing Unit",
  RAM: "Random Access Memory",
  DOS: "Disk Operating System",
  API: "Application Programming Interface",
  LED: "Light Emitting Diode",
  IBM: "International Business Machines",
  PC: "Personal Computer",
  BOOM: "Berkeley Out-of-Order Machine",
  RP: "Rendering Pass",
)
#let usedAcronyms = state("used", (:))



#outline(target: figure.where(kind: image), title: "List of Figures")
#outline(target: figure.where(kind: raw), title: "List of Listings")
#outline(target: figure.where(kind: table), title: "List of Tables")

#let listOfAcronyms = () => list(
  ..usedAcronyms.final().pairs().sorted().map(((acr, uses)) => { 
    [
      *#acr:* 
      #acronyms.at(acr) 
      #label("acronyms:" + acr) 
      \[#uses.dedup(key: use => use.page()).map(use => {
        link(use)[#use.page()]
      }).join(", ")\]
      // \[#uses.map(use => use.page()).dedup().map(str).join(", ")\]
    ] 
  })
)

#let enableAcronyms(body) = {
  for (acr, desc) in acronyms {
    body = {
      let match = "\b" + acr + "s?\b"
      show regex(match): (it) => {
        locate(loc => {
          usedAcronyms.update(used => {
            if used.keys().contains(acr) {
              used.at(acr).push(loc)
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