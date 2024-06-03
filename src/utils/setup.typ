#import "./latex.typ" as latex
#import "./acronyms.typ" as acronyms

#let setup = body => {
  set text(size: 10pt)
  set text(font: "New Computer Modern")
  set par(justify: true, linebreaks: "optimized")
  //set par(first-line-indent: 1em, leading: .65em)
  //show par: set block(spacing: .65em)
  
  set page(paper: "a4", margin: (x: 30mm, top: 21mm, bottom: 28mm), number-align: bottom, header-ascent: 2em, footer-descent: 2em)

  set page(header: {
    counter(footnote).update(0) 
  }, footer: {
    place(bottom + left, box(width: 100%, height: 28mm, {
      align(center + horizon, {
        locate(loc => {
          if loc.page-numbering() != none {
            (latex.size.normalsize)(weight: "regular", {
              numbering(loc.page-numbering(), counter(page).get().first())
            })
          }
        })
      })
    }))
  })

  set figure(numbering: num => {
    // Get heading numbering at this point
    let n = query(selector(heading.where(level: 1)).before(here())).last().numbering
    numbering(n, counter(heading).get().first())
    if n.last() != "." {
      [.]
    }
    numbering("1.", num)
  })

  show figure.where(kind: table): set figure.caption(position: top)
  
  set math.equation(numbering: num => {
    // Get heading numbering at this point
    let n = query(selector(heading.where(level: 1)).before(here()))
    if n.len() > 0 and n.last().numbering != none {
      [(]
      numbering(n.last().numbering, counter(heading).get().first())
      [.]
      numbering("1", num)
      [)]
    }
  })

  set math.equation(supplement: none)

  set outline(fill: repeat(" ."), indent: true)

  show outline.entry: it => {
    let start = measure(it.body).width
    let end = measure(it.page).width
    link(it.element.location(), {
      if it.element.func() == heading and it.level == 1 {
        v(1em, weak: true)
        set text(weight: 500, size: 12pt)
        it.body
        box(width: 1fr)
        text(size: 10pt, it.page)
      } else {
        it.body
        box(it.fill, width: 1fr)
        box(width: 5pt)
        it.page
      }
    })
  }

  // Fix the font in SVGs
  show image: it => {
    set text(font: "Fira Code")
    it
  }

  show heading: set par(first-line-indent: 0pt)
  show heading: set text(weight: 550)

  set figure(placement: auto)

  show ref: it => {
    let el = it.element
    if el != none and el.func() == figure {
      text(weight: "black", it)
    } else {
      it
    }
  }

  show heading: it => {
    block(breakable: false, {
      if it.numbering != none {
        numbering(it.numbering, ..counter(heading).at(it.location()))
        [ ]
      }
      show text: underline
      it.body
    })
  }

  show heading.where(level: 1): set heading(supplement: "Chapter")
  show heading.where(level: 1): it => {
    pagebreak(to: "odd", weak: true)
    block(breakable: false, {
      counter(figure.where(kind: image)).update(0)
      counter(figure.where(kind: raw)).update(0)
      counter(figure.where(kind: table)).update(0)
      counter(math.equation).update(0)
      v(3em)
      locate(loc => {
        if it.numbering != none {
          counter(heading.where(level: 1)).display(me => {
            text(size: 48pt, {
              numbering("1.", me)
            })
          })
        }
        {
          linebreak()
          // v(2.7em, weak: true)
          (latex.size.Huge)(it.body)
          v(1em)
        }
      })
    })
  }

  show heading.where(level: 2): set text(size: 14.4pt)
  show heading.where(level: 3): set text(size: 12pt)
  show heading.where(level: 4): set heading(numbering: none)

  set heading(numbering: none, outlined: false)
  include "../frontmatter/front-page.typ"

  set page(paper: "a4", margin: (inside: 36mm, outside: 24mm))

  set page(numbering: "i")
  counter(page).update(1)

  set table(stroke: none, fill: (x, y) => {
    if y.bit-and(1) != 1 {
      silver.lighten(60%)
    } else {
      white
    }
  })

  show raw.where(block: true): set text(font: "DejaVu Sans Mono", size: 7pt)
  set raw(theme: "../MultiMarkdown.tmTheme")
  show raw.where(block: true): set par(leading: .4em)

  include "../frontmatter/abstract.typ"
  include "../frontmatter/acknowledgements.typ"

  outline(target: heading, title: "Table of Contents", depth: 3)

  [
    = Glossary
    #grid(
      acronyms.listOfAcronyms()
    )
  ]
  
  outline(target: figure.where(kind: image), title: "List of Figures")
  outline(target: figure.where(kind: raw), title: "List of Listings")
  outline(target: figure.where(kind: table), title: "List of Tables")

  set page(numbering: none)
  pagebreak(to: "odd")

  show: acronyms.enableAcronyms

  set heading(outlined: true)
  set page(numbering: "1")
  counter(page).update(1)
  set heading(numbering: "1.1")

  body

  {
    set heading(numbering: none)
    bibliography("../bibliography.yaml")
  }
}
