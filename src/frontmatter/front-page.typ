#import "../utils/latex.typ" as latex
#import "../utils/config.typ" as config

#set page(header: none, footer: none)

#align(center, {
  v(4.5em)
  image("./images/ntnu-logo-norsk-m-visjon.svg", width: 40%)
  v(1cm, weak: true)
  smallcaps((latex.size.LARGE)([Department of ] + config.department))
  v(1.5cm, weak: true)
  smallcaps((latex.size.Large)(config.course.code + [ -- ] + config.course.name))
  v(.4cm, weak: true)
  v(2em)
  v(.6cm, weak: true)
  line(length: 150mm, stroke: .5pt)
  v(1cm, weak: true)
  (latex.size.huge)(text(weight: 500, config.project.name))
  v(1cm, weak: true)
  line(length: 150mm, stroke: .5pt)
  v(1.7cm, weak: true)

  (latex.size.large)(
    {
      emph(if (config.authors.len() > 1) { "Authors:" } else { "Author:" })
      table(columns: (1fr,)*2, stroke: none, 
        ..for (name, email) in config.authors {
          (table.cell(name, align: right), )
          (table.cell(raw("<" + email + ">"), align: left), )
        }
      )
    }
  )

  place(bottom + center, [#datetime.today().display()])
})

