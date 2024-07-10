#import "../utils/utils.typ": *

= Methodology and Results <ch:methodology-and-results>

Here, we describe our approach to gathering the results for the implementation and list these results.
The results are interpreted and discussed in the next chapter.

== Running Programs and Extracting Results

The best approach would be to run hardware accelerated simulation using FireSim, loading in representative programs like the SPEC CPU @bib:spec-cpu suite and evaluating performance after a warm-up period per program.

However, our process of synthesis fails on a cryptic error from Vivado when trying to run the flow for FireSim.
Because of time-constraints, we have decided to use the software simulator to evaluate performance.
We also do not have straightforward access to a RISC-V version of the SPEC CPU suite.

Because of these issues, we have decided to use a software simulator built with Verilator to run a small suite of programs that complete within a reasonable time on the software simulator.

=== About the Programs

The Chipyard project includes a number of test-applications to verify that a RISC-V implementation is behaving properly.
These programs are not intended for such benchmarking, but can at least serve as sanity checks that the implementation is not broken.
They are also small enough that running them to completion is feasible on the software simulator.

The programs we have available are located under `.conda-env/riscv-tools/riscv64-unknown-elf/share/riscv-tests/benchmarks`.
Although the directory is called "benchmarks", they are not actually _performance benchmarks_, but we have used them for rudimentary verification and performance testing.

The nice thing about these programs is that they include testing of the outputs, meaning if they pass, we can be more confident that the behaviour of the core is unchanged.
The downside of these benchmarks is that they are not intended to measure performance and the results we se here may not be representative of real programs, making it close to pointless to discuss metrics like mean speedup.

The programs themselves are given short descriptions in their source code, a summary of which follows here @bib:riscv-tests.
- *vvadd* adds elements of two vectors and stores the results in a third vector,
- *median* calculates the median of each group of three elements in a vector,
- *rsort* is a sorting program,
- *spmv* performs multiplication on sparse matrices,
- *multiply* is similar to *vvadd*, but uses multiplication instead of addition,
- *qsort* is another sorting program,
- *dhrystone* is the classic dhrystone synthetic benchmark @bib:dhrystone, and
- *towers* solves the classic towers of hanoi puzzle using a recursive algorithm.

All of these programs run in "bare-metal" mode, meaning there is no virtual memory.
Virtual memory might change results by needing to deal with things like TLB misses and 

== Evaluating Predictor Performance

With the predictor, we are interested in a few different metrics such as coverage and accuracy.

We can also determine a form of timeliness as with L1d prefetchers.
The current predictor implementation is always timely because it always makes a prediction before the related uOP has time to reach an AGU and calculate the real address.
However, it is interesting to inspect how many cycles pass between the LSU receiving a predicted address and the LSU receiving the real address.
If there is a significant number of cases where the difference is much greater than the normal L1d access latency, it is possible to justify a more complex predictor that uses more cycles to increase coverage and accuracy.

== Evaluating System Performance

With the system itself, we are mainly interested in measurements like IPC to determine the impact of the predictor on performance.
The "benchmark" programs are set up to read the `mcycle` and `minstret` CSRs before and after the test.
These registers contain the number of cycles spent running the program and the dynamic instruction count, respectively.
By subtracting the end point from the start point, we get a fair approximation of how the program executed and can calculate IPC as $d "minstret"\/d "mcycle"$.

Other interesting metrics would be power consumption and similar performance per watt, but it is hard to gauge without working synthesis.

=== Weird Printing with Doppelganger Loads

When load address prediction is enabled, the results printed to the output by the programs themselves are mangled as shown in @lst:mangled-output.

#figure(kind: raw,  {
  show raw: set text(size: 7pt)
  grid(columns: (auto, ) * 2, inset: 5pt, [
    ```
    Microseconds for one run through Dhrystone: 229
    Dhrystones per Second:                      4347
    mcycle = 115126
    minstret = 196029
    ```
  ],
  grid.vline(),
  [
    ```
    Microseconds for one run through Dhrystone: 229
    Drystones per Second:                      6
    mcycle = 1146
    istret = 02
    ```
  ])}, 
  caption: "Normal output without address prediction disabled (left) and mangled output with address prediction enabled (right)"
) <lst:mangled-output>

Most of the benchmarks only print the `mcycle = ...` and `minstret = ...` parts, but the Dhrystone benchmark prints a little extra information.
What is most curious about this is that the results seem to be consistent up to some point, but then start to fall apart.
We will discuss various hypotheses for why this happens in @ch:discussion.

In any case, the tests self-report passing their own checks, an unlikely event if there was anything wrong with the loaded values in a single-threaded context.
Because of this, we operate with the assumption that program behaviour is as normal and that only thing causing problems is the way programs print their results when combined with address prediction.

== Extracting the Results

Because we cannot rely on the printed output from the tests, we have resorted to printing the relevant information from the simulation, instead of relying on program outputs.

We run the simulator with the `--verbose` flag to allow for debug information to be output while running and set `enableCommitLogPrintf = true` in the configuration for the processor.
This tracks all committed instructions and their effects and prints it to standard output in a specific format.
An excerpt of this log is shown in @lst:commit-log-excerpt.

#figure(
  kind: raw,
  ```
  ...
  3 0x0000000080002ae6 (0x4505) x10 0x0000000000000001
  3 0x0000000080002ae8 (0xae1ff0ef) x 1 0x0000000080002aec
  3 0x00000000800025c8 (0xb0002773) x14 0x00000000000004af
  3 0x00000000800025cc (0x00004797) x15 0x00000000800065cc
  3 0x00000000800025d0 (0xa8c78793) x15 0x0000000080006058
  ...
  ```,
  caption: "Excerpt from the commit log of a run"
)<lst:commit-log-excerpt>

The third instruction here reads `mcycle` and stores the value in register `x14`and is encoded as `b0002773`.
This encoding would be different if a different register was used, but register `x14` is used for all these test programs.
This is convenient as we can simply search the commit log for this specific instruction and use simple scripting to extract the results.

== System Configurations

We have gathered results for a few system configurations.

=== Predictor Configuration

The predictor is set to have 1024 slots, a very high number for these very small tests, but this extreme should at least show whether there is potential to the technique of doppelganger loads in an unsafe execution environment like this.

=== SmallBoomConfig and MediumBoomConfig

We have used the SmallBoomConfig and MediumBoomConfig for the BOOM core which are single-width and double-width designs, respectively.
A few other structures scale with the width of the core like the size of the IQs and the number of memory ports.

=== With and Without Speculative Load Wakeup

Speculative load wakeup reduces the apparent latency of hits in the L1d to just three cycles.
Without it, loads have to be written back to the PRF and IQ slots have to react a cycle later, meaning dependent instructions cannot issue until four cycles after the address is received in the LSU.

=== With and Without Doppelganger Loads

Finally, we have tested the system with and without address prediction activated.
With these two base systems, and the two on/off variables of speculative load wakeups and address prediction, we end up with 8 different configurations to gather results for.

== Results

We list the results for the different configurations.

=== Instructions Per Cycle

@tab:smallboom-ipc shows the different tests and their IPC when run on the SmallBoomConfig core configuration.
Column *base-no-spec-ld* is our baseline that we want to beat,
*base* is the normal configuration that has speculative load wakeups enabled,
*ldpred-no-spec-ld* adds address prediction to the *base-no-spec-ld* configuration, and *ldpred* uses load address prediction in combination with speculative load wakeups.
@tab:smallboom-ipc-relative lists the difference for each test from the *base-no-spec-ld* config as a percentage change.

#let smallboom = csv("./data/smallboom.csv")

#figure(
  caption: "SmallBoomConfig IPC results with different configurations",
  placement: none,
  table(columns: (auto, ) * 5,
    [*Test*], [*base-no-spec-ld*], [*base*], [*ldpred-no-spec-ld*], [*ldpred*],
    ..smallboom.map(((name, base-no, base, ldpred-no, ldpred)) => {
      let base-no = calc.round(float(base-no), digits: 5)
      let base = calc.round(float(base), digits: 5)
      let ldpred-no = calc.round(float(ldpred-no), digits: 5)
      let ldpred = calc.round(float(ldpred), digits: 5)
      (name, base-no, base, ldpred-no, ldpred).map((v) => [#v])
    }).flatten(),
  )
) <tab:smallboom-ipc>

#figure(
  caption: "SmallBoomConfig IPC results with different configurations as relative to the baseline without speculative load wakeups, expressed as a percentage",
  placement: none,
  table(columns: (auto, ) * 5,
    [*Test*], [*base-no-spec-ld*], [*base*], [*ldpred-no-spec-ld*], [*ldpred*],
    ..smallboom.map(((name, base-no, base, ldpred-no, ldpred)) => {
      let base-no = float(base-no)
      let base = calc.round((float(base)/base-no - 1) * 100, digits: 5)
      let ldpred-no = calc.round((float(ldpred-no)/base-no - 1) * 100, digits: 5)
      let ldpred = calc.round((float(ldpred)/base-no - 1) * 100, digits: 5)
      (name, 0, base, ldpred-no, ldpred).map((v) => [#v])
    }).flatten(),
  )
) <tab:smallboom-ipc-relative>

Similarly, @tab:mediumboom-ipc and @tab:mediumboom-ipc-relative contain the absolute IPC and relative difference to *base-no-spec-ld* for the MediumBoomConfig.

#let mediumboom = csv("./data/mediumboom.csv")

#figure(
  caption: "MediumBoomConfig IPC results with different configurations",
  placement: none,
  table(columns: (auto, ) * 5,
    [*Test*], [*base-no-spec-ld*], [*base*], [*ldpred-no-spec-ld*], [*ldpred*],
    ..mediumboom.map(((name, base-no, base, ldpred-no, ldpred)) => {
      let base-no = calc.round(float(base-no), digits: 5)
      let base = calc.round(float(base), digits: 5)
      let ldpred-no = calc.round(float(ldpred-no), digits: 5)
      let ldpred = calc.round(float(ldpred), digits: 5)
      (name, base-no, base, ldpred-no, ldpred).map((v) => [#v])
    }).flatten(),
  )
) <tab:mediumboom-ipc>

#figure(
  caption: "MediumBoomConfig IPC results with different configurations as relative to the baseline without speculative load wakeups, expressed as a percentage",
  placement: none,
  table(columns: (auto, ) * 5,
    [*Test*], [*base-no-spec-ld*], [*base*], [*ldpred-no-spec-ld*], [*ldpred*],
    ..mediumboom.map(((name, base-no, base, ldpred-no, ldpred)) => {
      let base-no = float(base-no)
      let base = calc.round((float(base)/base-no - 1) * 100, digits: 5)
      let ldpred-no = calc.round((float(ldpred-no)/base-no - 1) * 100, digits: 5)
      let ldpred = calc.round((float(ldpred)/base-no - 1) * 100, digits: 5)
      (name, 0, base, ldpred-no, ldpred).map((v) => [#v])
    }).flatten(),
  )
) <tab:mediumboom-ipc-relative>

=== Accuracy and Coverage

We have collected statistics for accuracy and coverage in the *ldpred-no-spec-ld* configurations for both the SmallBoomConfig and MediumBoomConfig.
@tab:smallboom-prediction-stats and @tab:mediumboom-prediction-stats show the raw data collected.
The columns are as follows:
- *N Loads* is the total number of load instructions committed,
- *Fired* is the number of predictions that were actually used,
- *Correct Fired* is the number of used predictions that were also correct,
- *Total Pred.* is the total number of predictions made, and
- *Total Correct Pred.* is the total number of correct predictions made, used or not.

@tab:smallboom-prediction-stats-scaled and @tab:mediumboom-prediction-stats-scaled show the same data with the four last columns scaled to different quantities such that:
- *Fired/N Loads* gives the coverage (what portion of loads were given doppelgangers?),
- *Correct Fired/Fired* gives the accuracy of issued doppelgangers,
- *Total Pred./N Loads* gives the coverage if all predictions were used to generate doppelgangers, and
- *Total Correct Pred./Total Pred.* gives the accuracy if all predictions were used to generate doppelgangers.

Note that the SmallBoomConfig and MediumBoomConfig sometimes differ in the number of committed load instructions.
We have verified that for the tests themselves, all configurations commit exactly the same number of instructions (`minstret` is equal for each test no matter the configuration).
The difference likely stems from the setup and teardown that surrounds each test.

All of these statistics are only collected on committed loads.
Predictions made for uncommitted loads are not counted.

#let smallboom = csv("./data/acc-cov-smallboom.csv")

#figure(
  caption: "SmallBoomConfig total loads, number of fired predictions, number of fired correct predictions, total number of predictions, and total number of correct predictions, calculated per application",
  placement: none,
  table(
    columns: (auto, ) * 6,
    [*Test*], [*N Loads*], [*Fired*], [*Correct Fired*], [*Total Pred.*], [*Total Correct Pred.*],
    ..smallboom.flatten()
  ),
) <tab:smallboom-prediction-stats>

#figure(
  caption: "SmallBoomConfig total loads and number of fired predictions scaled to different quantities",
  placement: none,
  table(
    columns: (auto, ) * 6,
    [*Test*], [*N Loads*], [*Fired/N Loads*], [*Correct Fired/Fired*], [*Total Pred./N Loads*], [*Total Correct Pred./Total Pred*],
    ..smallboom.map(((name, a, b, c, d, e)) => {
      let a = float(a)
      let b = float(b)
      let c = float(c)
      let d = float(d)
      let e = float(e)
      let m = calc.round.with(digits: 4)
      (name, a, m(b/a), m(c/b), m(d/a), m(e/d)).map((it) => [#it])
    }).flatten()
  ),
) <tab:smallboom-prediction-stats-scaled>

#let mediumboom = csv("./data/acc-cov-mediumboom.csv")

#figure(
  caption: "MediumBoomConfig total loads, number of fired predictions, number of fired correct predictions, total number of predictions, and total number of correct predictions, calculated per application",
  placement: none,
  table(
    columns: (auto, ) * 6,
    [*Test*], [*N Loads*], [*Fired*], [*Correct Fired*], [*Total Pred.*], [*Total Correct Pred.*],
    ..mediumboom.flatten()
  ),
) <tab:mediumboom-prediction-stats>

#figure(
  caption: "MediumBoomConfig total loads and number of fired predictions scaled to different quantities",
  placement: none,
  table(
    columns: (auto, ) * 6,
    [*Test*], [*N Loads*], [*Fired/N Loads*], [*Correct Fired/Fired*], [*Total Pred./N Loads*], [*Total Correct Pred./Total Pred*],
    ..mediumboom.map(((name, a, b, c, d, e)) => {
      let a = float(a)
      let b = float(b)
      let c = float(c)
      let d = float(d)
      let e = float(e)
      let m = calc.round.with(digits: 4)
      (name, a, m(b/a), m(c/b), m(d/a), m(e/d)).map((it) => [#it])
    }).flatten()
  ),
) <tab:mediumboom-prediction-stats-scaled>

=== Prediction Timeliness

We observed that of correct predictions, the real address arrived after 3 cycles in 11.1% of the cases.
Another 5.4% of addresses arrived 4 cycles after the prediction.
In total, only around 22% of correct predictions are compared to the real address within 10 cycles of the prediction being made.

The statistics are similar for incorrect predictions, with the real address arriving 3 cycles after the prediction in 13.4% of the cases and 19.3% arriving within 10 cycles of the prediction being made.
