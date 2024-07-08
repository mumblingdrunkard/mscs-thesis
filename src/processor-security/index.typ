= Processor Security <ch:processor-security>

This thesis revolves around microarchitectural optimisations in the context of secure speculation.
We should therefore explain what is meant by _security_ of processors.

== Secrets in Processors

During execution of programs, some values are _secrets_.
Revealing these values to attackers would allow the attackers to affect the normal operation of the program.
For example, extracting encryption keys from a program would allow an attacker to interfere with the private communications of a program by listening in on private messages or pretending to be one of the communicating parties.
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

== Attacks on In-Order Processors

Because microarchitectural state is not flushed when switching applications, malicious applications can often observe the effects that other applications have had on the system.
By timing memory accesses to its own address space, an application can use information about the cache implementation to determine _something_ about the addresses that applications have accessed previously.
For example, if it can determine that one of its cache blocks was flushed since the last time it ran, it is likely because another application accessed a block with an equal index.
If this memory access used an address that was calculated using a secret value, the attacker can know part of the secret.

In this case, microarchitectural state---state that only exists due to the specific implementation of an ISA---is used to make accurate assertions about the execution of another program.
This is called a _side-channel attack_.

Side-channels reveal information about execution of a program in a way that is not visible in the ISA, but is visible through other observations such as the passing of time, or the consumption of power.
Searching for side-channel attacks on an algorithm, protocol, or system is a subject of _cryptanalysis_.

Side-channels are not exclusive to processors and their microarchitectures, but appear in most any system.
The _advanced encryption standard_ (AES) @bib:aes-standard ---a symmetric encryption algorithm famous for securing internet communications for more than two decades---has been broken through various side-channels.
AES has been broken through the cache timing side-channel @bib:aes-cache, analysis of power consumption @bib:aes-power, and even through electromagnetic radiation while being completely detached from the system @bib:aes-em.

None of these attacks directly attack the mathematical properties of the AES algorithm.
The maths of AES are sound as far as we [researchers] know.
Side-channel attacks focus on other information that can be gained by observing execution of the specific implementation of the AES algorithm.

=== Anatomy of a Vulnerable Application

@lst:vulnerable shows a C program that is vulnerable to various side-channel attacks.
The number of iterations executed in the loop is dependent on the secret value.
A normal timing attack to determine how long the application takes to execute could easily reveal how many iterations were executed, meaning the secret is revealed.

In the next case, the secret value is used to derive an index into an array and a value is loaded from that index.
This is a common pattern for various cryptographic algorithms that use lookup tables.
An attacker that can determine which cache block is affected by that access would be able to determine the lower 8 bits of the secret value.

#figure(
  ```c
  extern int *p_secret_value;
  int secret_value = *p_secret_value;

  for (int i = 0; i < secret_value; i++) {
    // perform some iteration
  }

  extern int* prng_vals;
  int prng_val = prng_vals[secret_value % 256];
  ```,
  caption: "A possibly vulnerable program"
) <lst:vulnerable>

=== Defending Against Attacks on In-Order Processors

There are generally two approaches to preventing side-channel attacks on InO processors: preventing leaks, or making leaks independent of secrets.
The first approach is universal and secures all applications in the system.
Making leaked information independent of secrets requires programmers to make careful considerations about what instructions are executed, when they are executed, and which data those instructions depend upon.

==== Stopping the Leaks

The first and most intuitive approach to stopping leaks is to prevent leaky behaviour in the first place, or at least prevent other applications from observing leaks.

For example, the OS might ensure the entire microarchitectural state is flushed before switching applications, ensuring malicious applications cannot possibly read any microarchitectural state left behind by a victim application.

This obviously has a potentially big impact on application performance as each application has to rebuild its microarchitectural state every time it is given time on the processor.
Even with such a mitigation, applications may be vulnerable through other side-channels such as timing or power analysis.
Making all execution spend the same amount of time, independent of secrets is not an easy feat.

Because of such downsides, this approach is rarely taken as it slows down applications that have no need for such security measures.

==== Secret-Independent and Constant Time Programming

The other approach is to make execution independent of secrets such that a secret leaked through a side-channel cannot effectively be distinguished from other data or noise.
For example, the loop might be reprogrammed to iterate to an upper bound of the secret value every time, and the results of unused iterations can be discarded.
The array access can be reprogrammed to access all values in order and using a copy with a mask generated from a comparison as shown in @lst:secret-independent-load.
There are many guidelines for writing such code @bib:intel-guidelines.

#figure(
  ```c
  int val = 0;
  for (int i = 0; i < 256; i++) {
    // == evaluates to 1 if the condition is true, and 0 otherwise
    // -1 is a number with all bits set---an appropriate mask value
    int mask = -(i == (secret_val % 256));
    val |= mask & prng_vals[i];
  }
  ```,
  caption: "Pseudocode for accessing the array values in a safe manner",
) <lst:secret-independent-load>

== Speculative Execution Vulnerabilities in Out-of-Order Processors

While InO processors may be vulnerable to some attacks, the applications are mostly in control of what they leak through various side-channels.
This is not the case in OoO processors, as has been demonstrated by the _speculative execution vulnerabilities_: _Spectre_ @bib:spectre and _Meltdown_ @bib:meltdown.

The nature of OoO processors means an application may leak values through various side-channels during transient execution---execution that is not even supposed to take place.
OoO processors are uniquely vulnerable to a class of attacks that are not possible on InO processors.

=== Anatomy of a Speculative Execution Attack

A speculative execution attack is performed:
+ When the malicious application runs, it intentionally mis-train the branch predictor (or some other predicting structure) such that
+ when the victim application is run, it enters an incorrect path of execution that depends on secret values and leaks this secret value through a side-channel before
+ the malicious application is again given time on the processor and determines the secret by observing the side-channel.

This attack relies on locating or injecting vulnerable code  (called a _gadget_)that the processor can execute while executing the victim application.
The attacking application then "tricks" the processor into mispredicting in a way that leaks the secret through a _covert channel_.

A side-channel forms a covert channel for applications to communicate.
In general, anything not intended for communication being used for communication is called a covert channel.
Processes may not be allowed to communicate directly, but if both processes can access some shared structure and leave traces, they can effectively communicate anyway.

This is the Spectre attack at a high level:
locating or injecting a vulnerable sequence of instructions, and then forcing the processor to execute that sequence of instructions while running the victim process because of misprediction, causing the processor to spill the secrets of a victim application through a covert channel.

While the most popular example of Spectre uses the cache side-channel to communicate secrets, it is not the only variant of the attack.
Far from it, in fact.
Instead of being one vulnerability with a simple fix, Spectre is presented as a whole class of vulnerabilities that have a common general approach as outlined above.

=== Covert Channels and Meltdown

Modern operating systems will commonly map unrelated, privileged memory into the virtual address space of all processes and only mark those privileged regions as such---relying on permission checking for security.

There is a "bug" in some implementations of processors where the permission to perform a load instruction is not checked or handled until long after the load in question was performed and the value is allowed to propagate to dependent instructions.

Under mis-speculated transient execution, rules be broken without a program crashing because the work is bound to be squashed.

The above three facts combine to create Meltdown.
+ Mis-train the branch predictor.
+ Under mis-speculated transient execution, access memory that the process does not have permission for and read a secret value.
+ During the same transient execution, leak the secret value through a side-channel such as the cache.
+ During normal execution, determine the leaked secret value through the side-channel, for example by timing cache accesses.

Here, there is no need for the victim application to even execute or perform any action than to be mapped into virtual memory.
The process cannot directly use the secret value or store it somewhere that it has access to, but it can leak it through the cache side-channel by performing a load based on the secret value such as the array access example earlier.

== Threat Modelling

As mentioned, a threat model is a framework for analysing the security of a processor.
_Defining such a model is difficult_.
A threat model contains a few different assumptions about the attacker, the system under attack, and the applications under attack.

Threat modelling does not only apply to processor design and a system may still be vulnerable despite a secure processor.
On the flipside, a system may be secure in spite of an "insecure" processor because the system restricts the access an attacker has to the processor.

When building threat models for any system, the first question is "what is being protected?", then "how can it be attacked?", and finally "how to mitigate those attacks?".

In terms of speculative execution vulnerabilities, the main focus of threat modelling is on how a speculating OoO processor is vulnerable in ways that InO processors are not.
For this case, practically any structure that can be speculatively modified that is not reverted on mis-speculation poses the risk of a speculative execution vulnerability.

=== Analysis

=== Secrets

=== Implicit and Explicit Channels

#figure(
  ```c
  extern int** pp_other_secret;
  extern int* p_secret;
  extern int* p_a;
  extern int* p_b;

  if (/* Misprediction */) {
    // implicit channel
    int tmp = *p_secret;
    int val;
    if (tmp) {
      val = *p_a;
    } else {
      val = *p_b;
    }

    // explicit channel
    int* p_other_secret = *pp_other_secret;
    int other_val = *p_other_secret;
  }
  ```,
  caption: "An possible implicit channel",
)

== Defending Against Attacks on Out-of-Order Processors

Defending against speculative execution attacks is not so simple.
The obvious solution is to disable speculation, but this has such a large performance impact that it is not a practical solution.

=== Secure Speculation Schemes

Several schemes have been proposed to close Spectre attacks on certain structures within the processor.
These different schemes use different threat models and protect different things.
==== Delay-on-Miss

==== Non-Speculative Data Access

==== Speculative Taint Tracking
