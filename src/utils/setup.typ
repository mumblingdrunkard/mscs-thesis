#let setup = body => {
  set text(size: 10pt, font: "New Computer Modern")
  set par(justify: true, linebreaks: "simple")
  
  set page(paper: "a4", margin: (x: 30mm, top: 20mm))
  set page(header: {
    line(length: 150mm, stroke: .5pt)
  }, footer: {
    line(length: 150mm, stroke: .5pt)
    align(center, {
      locate(loc => {
        if loc.page-numbering() != none {
          numbering(loc.page-numbering(), counter(page).get().first())
        }
      })
    })
  })
  
  show raw.where(lang: "asciidraw"): it => {
    set par(leading: 0.5em)
    set text(font: "Cascadia Code")
    it
  }
  
  let LaTeX = {
    set text(font: "New Computer Modern")
    box(width: 2.55em, {
      [L]
      place(top, dx: 0.3em, text(size: 0.7em)[A])
      place(top, dx: 0.7em)[T]
      place(top, dx: 1.26em, dy: 0.22em)[E]
      place(top, dx: 1.8em)[X]
    })
  }
  show "LaTeX": LaTeX

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
  show outline: it => {
    if it.target != selector(heading) {
      set heading(outlined: true)
      it
    } else {
      it
    }
  }
  show outline.entry: it => {
    let m = page.width - page.margin.left - page.margin.right
    let start = measure(it.body).width
    let end = measure(it.page).width
    if it.element.func() == heading and it.level == 1 {
      v(1em, weak: true)
      set text(weight: "bold", size: 11pt)
      it.body
      box(width: 1fr)
      it.page
    } else {
      it.body
      box(it.fill, width: 1fr)
      box(width: 5pt)
      it.page
    }
  }
  
  show heading.where(level: 1): it => {
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: raw)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(math.equation).update(0)
    it
  }

  show heading: it => {
    it
    v(weak: true, 1em)
  }
  
  body
}