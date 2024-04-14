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

#show raw.where(lang: "asciidraw"): it => {
  set par(leading: 0.5em)
  set text(font: "Cascadia Mono")
  it
}

#outline(target: figure.where(kind: image), title: "List of Figures")
#outline(target: figure.where(kind: raw), title: "List of Listings")
#outline(target: figure.where(kind: table), title: "List of Tables")

#let listOfAcronyms = (usedAcronyms) => list(..usedAcronyms.pairs().sorted().map(((acr, uses)) => {
  [
    *#acr:* 
    #acronyms.at(acr) 
    #label("acronyms:" + acr) 
    \[#uses.dedup(key: use => use.page()).map(use => {
      link(use)[#use.page()]
    }).join(", ")\]
    // \[#uses.map(use => use.page()).dedup().map(str).join(", ")\]
  ] 
}))

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
  [#[]<end-of-acronyms>]
}

#show: enableAcronyms

= Load Address Prediction in the BOOM Core

The Operating Systems (OS) we focus on are Linux,

OS

The CPU is responsible for

The API is responsible

#pagebreak()

This is some stuff

#figure(caption: "Hello", kind: image)[
  #set text(size: 9pt)
  ```asciidraw
        +10-15V                0,047R                                        
       ●─────────○───────○─░░░░░─○─○─────────○────○─────╮                    
    +  │         │       │       │ │         │    │     │                    
    ─═════─      │       │       │ │         │    │     │                    
    ─═════─    ──┼──     │       │╭┴╮        │    │     │                    
    ─═════─     ─┼─      │       ││ │ 2k2    │    │     │                    
    -  │      470│ +     │       ││ │        │    │     │                    
       │       uF│       ╰──╮    │╰┬╯       ╭┴╮   │     │                    
       └─────────○          │    │ │     1k │ │   │     ▽ LED                
                 │         6│   7│ │8       │ │   │     ┬                    
              ───┴───    ╭──┴────┴─┴─╮      ╰┬╯   │     │                    
               ─═══─     │           │1      │  │ / BC  │                    
                 ─       │           ├───────○──┤/  547 │                    
                GND      │           │       │  │ ▶     │                    
                         │           │      ╭┴╮   │     │                    
               ╭─────────┤           │  220R│ │   ○───┤├┘  IRF9Z34           
               │         │           │      │ │   │   │├─▶                   
               │         │  MC34063  │      ╰┬╯   │   │├─┐ BYV29       -12V6 
               │         │           │       │    │      ○──┤◀─○────○───X OUT
             - │ +       │           │2      ╰────╯      │     │    │        
6000 micro ────┴────     │           ├──○                C│    │   ─── 470   
Farad, 40V ─ ─ ┬ ─ ─     │           │ GND               C│    │   ███  uF   
Capacitor      │         │           │3                  C│    │    │\       
               │         │           ├────────┤├╮        │     │   GND       
               │         ╰─────┬───┬─╯          │       GND    │             
               │              5│  4│            │              │             
               │               │   ╰────────────○──────────────○             
               │               │                               │             
               ╰───────────────●─────/\/\/─────────○─────░░░░──╯             
                                     2k            │         1k0             
                                                  ╭┴╮                        
                                                  │ │5k6   3k3               
                                                  │ │in Serie                
                                                  ╰┬╯                        
                                                   │                         
                                                  GND
  ```
] 
<fig:asciidraw>

Hello, world

#locate(loc => {
  listOfAcronyms(usedAcronyms.at(loc))
})

