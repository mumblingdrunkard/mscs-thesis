#import "./latex.typ" as latex
#import "./acronyms.typ" as acronyms

#let setup = body => {
  set text(size: 10pt)
  set par(justify: true, linebreaks: "optimized", leading: 0.5em, first-line-indent: 2em)
  
  set page(paper: "a4", margin: (x: 30mm, top: 21mm, bottom: 21mm), number-align: bottom, header-ascent: 2em, footer-descent: 2em)

  show par: set block(spacing: .5em)

  set page(header: {
    // place(top + left, line(start: (0mm, 18mm), end: (150mm, 18mm), stroke: .5pt))
  }, footer: {
    // place(bottom + left, line(start: (0mm, -18mm), end: (150mm, -18mm), stroke: .5pt))

    place(bottom + left, box(width: 100%, height: 18mm, {
      align(center + top, {
        locate(loc => {
          if loc.page-numbering() != none {
            (latex.size.normalsize.with(weight: "regular"))({
              numbering(loc.page-numbering(), counter(page).get().first())
            })
          }
        })
      })
    }))
  }, )
  

  show raw.where(lang: "asciidraw"): it => {
    set par(leading: 0.5em)
    set text(font: "Fira Code")
    it
  }

  set figure(numbering: num => {
    // Get heading numbering at this point
    let n = query(selector(heading.where(level: 1)).before(here())).last().numbering
    numbering(n, counter(heading).get().first())
    if n.last() != "." {
      [.]
    }
    numbering("1.", num)
  })
  
  show figure.where(kind: math.equation): set figure(numbering: num => {
    let loc = query(selector(math.equation).after(here())).first().location()
    let n = query(selector(heading.where(level: 1)).before(here())).last().numbering
    [(]
    numbering(n, counter(heading).get().first())
    if n.last() != "." {
      [.]
    }
    numbering("1", counter(math.equation).at(loc).first())
    [)]
  })
  show figure.where(kind: math.equation): set figure(supplement: [])

  show figure.where(kind: math.equation): it => {
    it.body
    align(center, it.caption.body)
  }
  
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
        set text(weight: "bold", size: 12pt)
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
  show heading.where(level: 1): it => {
    pagebreak(to: "odd", weak: true)
    sym.zws
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: raw)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(math.equation).update(0)
    v(5.7em)
    locate(loc => {
      if it.numbering != none {
        counter(heading.where(level: 1)).display(me => {
          (latex.size.huge)({
            [Chapter ]
            numbering("1", me)
          })
        })
      }
      {
        v(2.7em, weak: true)
        (latex.size.Huge)(it.body)
        v(2em, weak: true)
      }
    })
  }

  show heading.where(level: 2): set text(size: 14.4pt)
  show heading.where(level: 3): set text(size: 12pt)
  show heading.where(level: 4): set heading(numbering: none)

  show heading: it => {
    v(weak: true, 2.65em)
    it
    v(weak: true, 1.75em)
  }

  set heading(numbering: none, outlined: false)

  include "../frontmatter/front-page.typ"

  set page(paper: "a4", margin: (inside: 36mm, outside: 24mm))

  set page(numbering: "i")
  counter(page).update(1)

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
