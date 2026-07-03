# 01-counter — Explanation for the TA

This is a plain-language walkthrough of my up/down counter and its testbench.
I can read straight from this while demonstrating.

---

## 1. What the project is

I built a **4-bit up/down counter** in SystemVerilog and ran it on EDA Playground.

- "4-bit" means the count value goes from `0` to `15` (in hex: `0` to `F`).
- It can **count up**, **count down**, **load** a value I give it, **hold** its value, and **reset** to zero.
- I also wrote a **testbench** — a separate program that automatically drives the counter with signals and checks that it behaves correctly. If everything works, it prints **"All tests passed!"**

Two files:
| File | Role |
|------|------|
| `solution_counter.sv` | The actual counter (the "design") |
| `solution_counter_tb.sv` | The testbench that tests the design |

---

## 2. The counter design (`solution_counter.sv`)

### The inputs and outputs (the "ports")

```systemverilog
module updown_counter(
    input  logic clk,        // Clock — the heartbeat; the counter acts on each tick
    input  logic rst_n,      // Reset (active-low: 0 = reset, 1 = normal)
    input  logic load,       // When 1, load d_in into the counter
    input  logic up_down,    // 1 = count up, 0 = count down
    input  logic enable,     // 1 = allowed to count, 0 = hold still
    input  logic [3:0] d_in, // 4-bit value to load
    output logic [3:0] count // 4-bit counter output
);
```

- `input` / `output` = direction of the signal.
- `logic` = the basic signal type in SystemVerilog (think "a wire/register").
- `[3:0]` = a **4-bit bus** (4 wires bundled together). `clk`, `load`, etc. have no `[3:0]`, so they are single bits.
- **"active-low reset"** means reset happens when `rst_n` is **0**, not 1. The `_n` in the name is a convention for "active low".

### The logic (the important part)

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        count <= 4'h0;                 // 1. Reset wins: go to 0
    else if (load)
        count <= d_in;                 // 2. Load: copy d_in in
    else if (enable)
        count <= up_down ? count + 1   // 3a. Count up
                         : count - 1;  // 3b. Count down
    // else: hold (do nothing → keep the same value)
end
```

**How to explain this block:**

- `always_ff` = "this describes a **flip-flop** (memory)". It's the hardware that remembers the count between clock ticks.
- `@(posedge clk or negedge rst_n)` = "re-evaluate this **on the rising edge of the clock**, OR the moment reset goes low." This is called the **sensitivity list**.
  - `posedge clk` = rising edge (clock going 0→1).
  - `negedge rst_n` = falling edge of reset (going 1→0). Putting reset here makes it **asynchronous** — reset happens immediately, without waiting for a clock tick.
- `<=` is a **non-blocking assignment** — the correct way to update flip-flops in clocked logic. (Different from `=`, which is for combinational logic.)

**The priority (top to bottom = highest to lowest):**
1. **Reset** — if `rst_n` is 0, force count to 0. Beats everything.
2. **Load** — if not resetting and `load` is 1, copy `d_in` into count.
3. **Count** — if `enable` is 1, add 1 (up) or subtract 1 (down).
4. **Hold** — if none of the above, keep the current value (this is what `enable = 0` does).

`4'h0` means "a 4-bit value, in **h**ex, equal to 0". `4'hB` would be 11.

Because it's 4 bits, counting **wraps around**: `15 + 1 = 0`, and `0 - 1 = 15`. That's normal for a fixed-width counter.

---

## 3. The testbench (`solution_counter_tb.sv`)

A testbench is **not hardware** — it's a simulation script. It creates fake input signals, feeds them to the counter, and checks the output.

### The clock generator

```systemverilog
initial begin
    clk = 0;
    forever #5 clk = ~clk;   // flip the clock every 5 ns
end
```

- `initial` = "run this once at the start of simulation."
- `forever #5 clk = ~clk;` = every **5 nanoseconds**, invert the clock (`~` = NOT).
- Flipping every 5 ns → a full clock cycle (low+high) is **10 ns**. So one "tick" = 10 ns. That's why the tests use `#10`, `#20`, `#40` for 1, 2, and 4 cycles.

### Connecting the counter to the testbench

```systemverilog
updown_counter dut(
    .clk(clk), .rst_n(rst_n), .load(load), .up_down(up_down),
    .enable(enable), .d_in(d_in), .count(count)
);
```

- `dut` = "**D**evice **U**nder **T**est" — my counter being tested.
- `.clk(clk)` = "connect the module's `clk` port to my testbench signal `clk`." I wire up every port this way.

### The test sequence

`#N` means "**wait N nanoseconds**." Between waits, the clock keeps ticking and the counter reacts.

| Test | What it does | Expected result |
|------|--------------|-----------------|
| Setup | Hold reset low, then release it | count = 0 |
| **1. Load** | Put `7` on `d_in`, raise `load` | count becomes `7` |
| **2. Count up** | enable=1, up_down=1, wait 4 cycles | 7→8→9→A→B, count = `B` (11) |
| **3. Count down** | up_down=0, wait 3 cycles | B→A→9→8, count = `8` |
| **4. Disable** | enable=0, wait | count stays `8` (holds) |
| **5. Reset mid-run** *(I added)* | count a bit, then pull reset low | count = `0` |
| **6. Load while counting** *(I added)* | enable=1 but also load=1, d_in=5 | count = `5` (load beats counting) |
| **7. Disable while counting** *(I added)* | enable=0 after loading 5 | count stays `5` |

Each test does a check like:

```systemverilog
if (count !== 4'h7) begin
    $display("Test 1 Failed: Load operation");
    test_passed = 1'b0;
end
```

- `!==` = "not equal" (a strict compare that also catches unknown 'x' values).
- `$display(...)` = print a message to the console (like `print`).
- If any test fails, it sets `test_passed = 0`.

At the very end:

```systemverilog
if (test_passed) $display("All tests passed!");
else             $display("Some tests failed.");
$finish(0);   // end the simulation
```

**The three tests I added (5, 6, 7)** are the "extra test cases" the assignment asked for. They prove:
- **5** — asynchronous reset works even in the middle of counting.
- **6** — `load` has higher priority than counting (matches my design's priority order).
- **7** — when `enable` is 0, the counter truly holds and doesn't drift.

---

## 4. How to demonstrate / what to say

1. "This is a 4-bit up/down counter with load, enable, and asynchronous reset."
2. "The counter logic is a clocked `always_ff` block with a clear priority: **reset > load > count > hold**."
3. "The testbench generates a 10 ns clock and runs 7 test cases; I added tests 5–7 myself."
4. **Run it on EDA Playground** → point to the console output: **"All tests passed!"**
5. (Optional) Open **EPWave** to show the waveform — you can literally see the count going up, down, resetting, and holding.

---

## 5. Quick glossary (if the TA asks)

- **module** — a hardware block (like a function/class in software).
- **logic** — SystemVerilog signal type.
- **`[3:0]`** — a 4-bit bus.
- **posedge / negedge** — rising / falling edge of a signal.
- **always_ff** — describes flip-flops (sequential/memory logic).
- **`<=` (non-blocking)** — assignment used inside clocked blocks.
- **asynchronous reset** — reset takes effect immediately, not on a clock edge.
- **testbench / dut** — the test program / the design being tested.
- **`#10`** — wait 10 nanoseconds in simulation.
- **`4'hB`** — a 4-bit hexadecimal literal (= 11 in decimal).
