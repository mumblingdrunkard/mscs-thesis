#import "utils/acronyms.typ" as acronyms
#import "utils/setup.typ" as setup

#show: setup.setup

#include "misc/front-page.typ"

#pagebreak()
#set page(numbering: "i")
#counter(page).update(1)

// Frontmatter goes here
#outline(target: heading, title: "Table of Contents")
#outline(target: figure.where(kind: image), title: "List of Figures")
#outline(target: figure.where(kind: table), title: "List of Tables")
#outline(target: figure.where(kind: raw), title: "List of Listings")
#outline(target: figure.where(kind: math.equation), title: "List of Equations")

#pagebreak()
#set page(numbering: "1", number-align: center)
#counter(page).update(1)

#{
  set heading(numbering: "1.1")
  include("01-introduction/index.typ")
  include("02-background/index.typ")
  include("03-architecture/index.typ")
}

