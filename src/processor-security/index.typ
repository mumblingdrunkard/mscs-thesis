= Processor Security

This thesis revolves around microarchitectural optimisations in the context of secure speculation.
We should therefore explain what is meant by _security_ of processors.

== Secrets in Processors

During execution of programs, some values are _secrets_.
Revealing these values to attackers would allow the attackers to affect the normal operation of the program.
For example, extracting encryption keys from a program would allow an attacker to interfere with the private communications of a program by listening in on private messages or injecting its own messages.
The security of a system relies on it protecting secret values---like encryption keys---from attackers.

The framework for analysing security is called a _threat model_.
The most conservative models may assume as much as:
+ The attacker has physical access to the system and knows the microarchitecture.
+ The attacker can run any self-chosen code on the system at any time.
+ The attacker knows the other code running on the system.
+ The attacker can measure how long execution takes.
+ The attacker can measure the power consumption of the system.

== Why Processors are Vulnerable in the First Place

Processors are _virtualised_: 
The processing capacity is being shared between many applications in the same span of time.
This is done by stopping applications, saving their state, loading the state of some other application, and resuming execution on this new application.
This is great for users of computer systems because even with a single core, it is possible to run many applications.

Applications are isolated from each other by virtualising their address spaces so that they can only access their own memory.
When swapping applications, only the architectural state needs to be properly replaced to ensure correct operation.
Microarchitectural structures like branch predictor storage and cache do not need to be cleared and commonly are not because doing so would reduce performance.

Because of this, malicious applications can determine which cache blocks have been accessed by timing accesses and they can interfere with the branch predictor before other applications get to run.

== Attacks on In-Order Processors

By timing memory accesses to its own address space, an application can use information about the cache implementation to determine _something_ about the addresses that applications have accessed previously.
For example, if it can determine that one of its cache blocks was flushed since the last time it ran, it is likely because another application accessed a block with an equal index.
If this memory access used an address that was calculated using a secret value, the attacker can know part of the secret.

In this case, microarchitectural state---state that only exists due to the specific implementation of an ISA---is used to make accurate assertions about the execution of another program.
This is called a _side-channel attack_.

Side-channels reveal information about execution of a program in a way that is not visible in the ISA, but is visible through other observations such as the passing of time, or the consumption of power.
Searching for side-channel attacks on an algorithm, protocol, or system is a subject of _cryptanalysis_.
Several side-channel attacks have been discovered and demonstrated.

=== Defending Against Attacks on In-Order Processors

There are generally two approaches to preventing attacks on InO processors: preventing leaks, or making leaks independent of secrets.
The first approach is universal and secures all applications in the system.
Making leaked information independent of secrets requires programmers to make careful considerations about what instructions are executed, when they are executed, and which data those instructions depend upon.

==== Stopping the Leaks

Stopping leaks can be done 

==== Secret-Independent Programming

Accepting side channels as a fact of life.

== Threat Modelling

A _threat model_ is a framework for analysing the security of a processor.
_Defining such a model is difficult_.
Determining

== Speculative Execution Vulnerabilities in Out-of-Order Processors

While InO processors may be vulnerable to some attacks, the applications are in control of what they leak through the cache side-channel.
This is not the case in OoO processors, as has been demonstrated by the _speculative execution vulnerabilities_: _Spectre_ @bib:spectre and _Meltdown_ @bib:meltdown.

The nature of OoO processors means an application may leak values through various side-channels during transient execution---execution that is not even supposed to take place.
Speculative execution attacks use features of the microarchitecture to reliably force the processor to mis-speculate in a victim application and enter an unintended path of execution that leaks secret values into side-channels.
They then use the same, or other features to reliably extract information from those side-channels to obtain the secret values.

OoO processors are uniquely vulnerable to a class of attacks that are not possible on InO processors.

=== Spectre and Meltdown as a Class of Vulnerabilities

==== Meltdown is a Dumb Bug

Meltdown is a race condition 

=== Defending Against Attacks on Out-of-Order Processors

Not that simple.
Constant time programming does not work.

=== Secure Speculation Schemes

==== Delay-on-Miss

==== Non-Speculative Data Access

==== Speculative Taint Tracking
