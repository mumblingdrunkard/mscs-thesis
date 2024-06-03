= Processor Security

This thesis revolves around microarchitectural optimisations in the context of secure speculation.
We should therefore explain what is meant by _security_ of processors.

== Secrets in Processors

During execution of programs, some values are secrets.
Revealing these values to attackers would allow the attackers to affect the normal operation of the program.
The security of a system relies on it being able to protect secret values from attackers.

Various models have been defined to analyse processor security.
The most conservative ones may assume as much as:
+ The attacker has physical access to the system and knows the microarchitecture.
+ The attacker can run any self-chosen code on the system at any time.
+ The attacker knows the code running on the system.
+ The attacker can measure how long execution takes.
+ The attacker can measure the power consumption of the system.

== Why Processors are Vulnerable in the First Place

Processors are usually _virtualised_.
That is: the processing capacity is being shared between many applications in the same span of time.
This is done by stopping applications, saving their state, loading the state of some other application, and continuing execution on this new application.
This is great for users of computer systems because even with a single core, it is possible to run many applications.

Applications are isolated from each other by virtualising their address spaces so that they can only access their own memory.
However, the state of caches and branch predictors stays unchanged when swapping applications.

== Attacks on In-Order Processors

By timing memory accesses to its own address space, an application can use information about the specific cache implementation to determine _something_ about the addresses that applications have accessed previously.
For example, if it can determine that one of its cache blocks was flushed since the last time it ran, it is likely because of another application accessing a block with an equal index.

In this case, microarchitectural state---state that only exists due to the specific implementation of an ISA---is used to make accurate assertions about the execution of another program.
This is called a _side-channel attack_.

Side-channels reveal information about execution of a program in a way that is not visible in the ISA, but is visible through other observations such as the passing of time, or the consumption of power.
Searching for side-channel attacks on an algorithm, protocol, or system is a subject for _cryptanalysis_.

Several side-channel attacks have been successfully demonstrated.

=== Defending Against Attacks on In-Order Processors

==== Stopping Side-Channels

==== Secret-Independent Programming

Accepting side channels as a fact of life, writing programs to 

== Speculative Execution Vulnerabilities in Out-of-Order Processors

While InO processors may be vulnerable to some attacks, the applications are at least in control of what they leak through the cache side-channel.
This is not the case in OoO processors, as has been demonstrated by the _speculative execution vulnerabilities_: _Spectre_ @bib:spectre and _Meltdown_ @bib:meltdown.

Fundamental properties of how OoO execution is achieved means an application that falls victim to a mispredicted branch may leak values through various side-channels during transient execution---execution that is not even supposed to take place.
Speculative execution attacks use these properties and certain techniques to reliably force the processor to mispredict a branch in a victim application and enter an unintended path of execution that leaks secret values into side-channels.
They then use the same, or other properties to reliably extract information from those side-channels to obtain the secret values.

=== Spectre and Meltdown as a Class of Vulnerabilities

==== Meltdown is a Dumb Bug

=== Defending Against Attacks on Out-of-Order Processors

Not that simple.
Constant time programming does not work.

=== Secure Speculation Schemes

==== Delay-on-Miss

==== Non-Speculative Data Access

==== Speculative Taint Tracking
