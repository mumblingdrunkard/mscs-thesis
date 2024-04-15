= Implementability of the Addressing Scheme

The naively written code shown in #text(fill: red)[REF HERE] is unlikely to undergo the optimisations necessary for actually achieving only one write port and two read ports per bank of the predictor.

However, we can use a `Mux1h` to convey this meaning and increase the likelihood of getting the correct optimisations.