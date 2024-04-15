= Three 

More pages

== Hello

#figure(caption: "A figure of some text", [Some text]) <fig:c>
#figure(caption: "A figure of some text", [Some text]) <fig:d>
#figure(caption: "A table", table(columns: (5em, ) * 2, [A], [B], [C], [D])) <tbl:a>
#figure(caption: "A code block", 
````
Hello, World
````
)

#figure(caption: "Core Overview", image("./diagrams/cpu.svg"))

=== Hello

Hello again, I'm a skeleton

== World

=== This world is cruel

#figure(caption: "Test", kind: math.equation, $ 
  5 + 5 
$) <eq:five-plus-five>

$ 12 + 3 $

#figure(caption: "Test", kind: math.equation, $ 
  7 + 5 
$) <eq:seven-plus-five>

As seen in @eq:five-plus-five

#math.equation(numbering: none, block: true, [
  7 + 5
])

Have a look at @eq:navier-stokes
