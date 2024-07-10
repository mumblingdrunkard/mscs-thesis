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

Several structures and mechanisms have successfully been used as covert channels such as the cache, timing differences, port contention, and branches.

Because of these many variants and mechanisms that are difficult to close, speculative execution attacks form an incredibly powerful technique that is difficult to protect against.

=== Covert Channels and Meltdown

Modern operating systems will commonly map unrelated, privileged memory into the virtual address space of all processes and only mark those privileged regions as such---relying on permission checking for security.

There is a "bug" in some implementations of processors where the permission to perform a load instruction is not checked or handled until long after the load in question was performed and the value is allowed to propagate to dependent instructions.

Under mis-speculated transient execution, rules can be broken without a program crashing because the work is bound to be squashed.

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

The first step to constructing a threat model consists of determining the possible threats such as which code is allowed to execute on the system and who controls that code.
A good number of systems are expected to run applications such as web browsers where a web server is in control of code executed on a user's system.
Similarly, cloud platforms allow uploading code to be run on a system that is potentially shared with many other applications uploaded in a similar fashion.

Because of these cases, it is reasonable for a threat model to consider all deployments of processors as potentially vulnerable and in need of protection.
As has been mentioned earlier, it is an acceptable solution to make the processor as secure as a normal in-order processor, allowing for non-speculative leaks.
Thus _our goal is to make an out-of-order processor at least as secure as an in-order processor_.

=== Secrets

The next stage is to determine which values are in fact secret and of interest to an attacker.
This may be values like encryption keys, or unencrypted data.
These values are potentially stored in memory.

Because there are no special instructions to execute when loading secret data from memory as opposed to non-secret data, all threat models may make the reasonable assumption that all values loaded from memory in a speculative manner are potentially secrets and should be protected.

The big difference between some of the models is what happens to values once they are in registers and no longer speculative.
If values are loaded in registers, it is reasonable to assume that the values are going to be used and there is a high likelihood that the value is about to be leaked through some side-channel, even in an in-order system.

Some models act on the assumption that non-speculative values in registers are leaked and only provide protection for values that are loaded speculatively from memory.
Other models intend to provide protection for registers as well.

=== Attack Mechanisms

Next, the threat model should consider mechanisms for gaining the secret knowledge and which of them should be protected against.
Some attacks on in-order processors were presented.
As these attacks are possible on in-order processors, our threat model can ignore them seeing as our goal is only to make an out-of-order processor as safe as an in-order processor.

The threat of speculative execution attacks is unique to out-of-order processors and requires protecting against.
Attacks rely on being able to perform three distinct steps:
+ access the secret,
+ transmit the secret through a covert channel, and
+ recover the secret.

Barring implementation errors causing Meltdown-like bugs, Spectre-like attacks rely on applications containing exploitable sequences of instructions and being able to intentionally train a speculative microarchitectural structure to cause the processor to mis-speculate and enter the exploitable section in a victim application.

Transmitting the secret is done through a side-channel---most popularly the cache.
Load instructions are popular for the purpose of leaking information during speculation as they only affect the microarchitectural state.

Finally, the malicious application depends on being able to access the side-channel to recover the secret that was transmitted.
In the case of the cache acting as the side-channel, this is generally performed as a cache-timing attack.

By preventing one or more of these distinct stages, Spectre attacks are prevented.

==== Chosen-Code and Control-Steering

Accessing the secret is generally done in one of two ways:
a chosen-code attack is able to inject arbitrary code to be executed in some context where secrets are mapped into memory and may be accessed.
A control-steering attack has to find exploitable code in the victim application and intentionally steer the processor to execute instructions along that exploitable path.

==== Implicit and Explicit Channels

The difficult part of preventing speculative execution attacks is enumerating all of the possible side-channels that exist and may be able to transmit secret values.

Explicit channels exist when a known leaky instruction depends on unsafe speculative data, such as a load instruction using the result of another load instruction as an address.

Implicit channels are less overt and exist when non-leaky instructions are allowed to execute and end up affecting the execution of leaky instructions.
Take the example in @lst:implicit-channel.
Here, all the obviously leaky actions for the code under `// implicit channel` use values that are non-speculatively loaded.
A scheme that does not provide register protection may accidentally leak a secret here.
Because the branch instruction depends on a speculatively loaded value, the instructions executed after the branch may reveal information about the speculatively loaded value.

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
) <lst:implicit-channel>

== Defending Against Attacks on Out-of-Order Processors

Defending against speculative execution attacks is not so simple.
The obvious solution is to disable speculation, but this has such a large performance impact that it is not a practical solution.

=== Secure Speculation Schemes

Several schemes have been proposed to patch the speculative execution vulnerabilities of out-of-order processors.
The most conservative approach is to delay all instructions that potentially access secrets until they are deemed non-speculative.

This has a big performance impact.
Below we describe a few schemes that try to improve on this conservative scheme without sacrificing on security, or make concious decisions about which security guarantees are given up.

==== Non-Speculative Data Access

_Non-speculative data access_ (NDA) presents various possible threats @bib:nda.
First, leaking memory contents via control-steering, then leaking register contents with control-steering, and finally leaking memory contents with chosen-code attacks.
Finally, they present their most conservative model that combines all of the threats.

NDA considers an attacker that has the ability to monitor any covert channel from anywhere and is able to introduce arbitrary speculation.

For the control-steering attacks, they assume the attacker is able to direct instruction fetch at any branch point.
The difference between spilling memory contents and spilling register contents is that with the register contents, the access phase has possibly already been performed non-speculatively.
When protecting memory contents, it would possibly be enough to prevent the access phase of a Spectre attack.
This is not the case when protecting register contents that are already non-speculative and protections must therefore focus on blocking the transmission phase.

For the chosen-code attack, they consider an attacker that can decide code executed both correctly and transiently (incorrectly executed, then squashed).
In this variant, correct path instructions that retire cannot leak secrets accessed in the wrong path of execution.
At least not directly.

One of the NDA variants, called "strict data propagation", considers instructions to be _unsafe_ if they may be affected by branches or store instructions that have not yet had their address resolved.
That is, a later load may depend on a store, but perform its access ahead of time only to be squashed because the store resolves to access overlapping addresses#footnote[Unresolved store addresses are a problem in a so-called speculative store bypass (SSB) attack that we have not discussed here.].
Instructions after a branch may obviously be unsafe as they are possibly on the wrong path of execution due to a misprediction.
Under this variant, unsafe instructions are allowed to execute as long as their dependencies are not from unsafe instructions.
This is achieved by not propagating the results of unsafe instructions until they are marked as no longer unsafe.
This approach protects secrets in memory and in registers.

A second variant called "permissive data propagation" only protects secrets in memory.
In this variant only load instructions may be marked unsafe.
All other instructions are considered safe with the observation that only load instructions can access secrets.
This allows for more parallelism as chains of instructions are allowed to dispatch and complete as long as the chain does not contain a load instruction.

The first approach has a reported performance overhead of 36.1% while the second, permissive scheme has a performance overhead of 10.7%.

NDA also has several other variants to protect against chosen-code attacks, but we have focused mainly on control-steering attacks.

==== Speculative Taint Tracking

_Speculative taint tracking_ (STT) is a different scheme with a similar threat model to NDA with permissive propagation, aiming to protect secrets in memory @bib:stt.
Secrets accessed non-speculatively, then transmitted speculatively are not protected by STT.
This with the observation that the arguably most dangerous attacks are those where the access is performed speculatively as it can be induced to access data that would not have been accessed non-speculatively.
This kind of attack allows forming _universal read gadgets_ that read any address in mapped memory.

The reasoning behind this is that security-minded programmers are already aware that they have to be careful with handling secrets.
A universal read gadget may be accidentally introduced anywhere and allow an attacker to read the secret from code that never intentionally accessed the secret.

One of the important observations made by the authors of STT is that predictive mechanisms can be used to leak secrets in two different ways.
If the predictor is updated speculatively, an attacker may induce behaviour such that the predictor learns the secret value.
The attacker can then determine the secret by observing differences in timing that arise because the processor does or does not squash later instructions.
This first mechanism is referred to as _prediction_-based leakage.

The second mechanism is called _resolution_-based leakage and allows an attacker to determine a secret even if the predictor has not been trained speculatively.
Instead, the attacker trains a prediction so that the branch result resolves in a certain way, then observes the actual behaviour of the branch during execution by differences in timing or observing other behaviour.

STT refers to speculatively loaded values as secrets.
STT works by "tainting" secrets---hence the name.
The authors define three characteristics:
+ which values should be tainted,
+ when values can be marked as no longer tainted, and
+ which instructions have to be careful when handling tainted values.

Values in memory that are accessed speculatively are considered tainted.
Values may be untainted when the instructions generating them can no longer be squashed (i.e. bound to commit).
A more relaxed approach only requires all explicit previous speculation to be resolved while still potentially allowing instructions to be squashed for other reasons.

Instructions that can leak values have to be careful about handling tainted values.
A wide variety of instructions can potentially leak values through various explicit or implicit channels.

STT builds on the assumptions that the prediction- and resolution-based channels are eliminated by only training on untainted data, and delaying the effects of branch resolution until the dependencies of the branch become untainted.

The two main pieces to implementing STT is tainting and untainting instructions, and blocking instructions that may leak.
Tainting is trivial while untainting and propagating untaint information is non-trivial.
STT solves untainting with a novel algorithm.

==== Delay-on-Miss

_Delay-on-miss_ (DoM) takes an entirely different approach.
DoM protects secrets in memory by delaying all updates to the memory hierarchy caused by loads until the loads are non-speculative @bib:dom.
If a load hits, the value is allowed to propagate, but updates to microarchitectural state is delayed.
For example, the replacement policy would normally be updated immediately, but is delayed under DoM until loads are known to be non-speculative.

This idea can be extended to start performing loads from deeper cache levels, but this requires changes to all affected levels of the cache to allow delaying effects.

DoM does not attempt to hide differences in timing that can occur due to misspeculation and only attempts to block side-channels based on modifying stored microarchitectural state.
