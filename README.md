# asynchronous_fifo
# Asynchronous FIFO in Verilog

A parameterizable, dual-clock (asynchronous) FIFO implemented in Verilog, designed to safely transfer data between two independent, unsynchronized clock domains using gray-coded pointers and 2-flop synchronizers.

## Why This Project

Crossing clock domains is one of the most common — and most commonly mishandled — problems in digital design. A naive FIFO that shares write/read pointers directly between clock domains is vulnerable to **metastability** and **data corruption**, since a multi-bit binary counter can have several bits changing at once, and a synchronizer sampling it mid-transition can capture a garbage value.

This project solves that using the standard industry technique:
- **Gray-coded pointers** — only one bit changes per increment, so a synchronizer can never sample an intermediate value that's more than 1 count off
- **2-flop synchronizers** — each pointer is passed through two flip-flops in the receiving clock domain to resolve metastability before it's used in flag logic

## Architecture

```
                 ┌─────────────────┐
   wclk ───────► │  wptr_handler   │────► gray-coded wptr
                 │ (write pointer, │           │
                 │  full flag gen) │           ▼
                 └─────────────────┘   ┌───────────────┐
                                        │ synchronizer  │──► synced to rclk domain
                                        │  (2-flop)     │
                                        └───────────────┘
                                                │
                 ┌─────────────────┐            ▼
   rclk ───────► │  rptr_handler   │◄── used for empty flag
                 │ (read pointer,  │
                 │  empty flag gen)│
                 └─────────────────┘

   Both wptr and rptr also cross in the opposite direction
   (rptr → synchronizer → wclk domain, for full flag generation)

                 ┌─────────────────┐
                 │   fifo_mem      │
                 │ (dual-port RAM, │
                 │  DEPTH x WIDTH) │
                 └─────────────────┘
```

**Data flow:**
1. Writes happen on `wclk` when `w_en` is high and `full` is low; `data_in` is stored at `fifo_mem[wr_ptr]`
2. Reads happen on `rclk` when `r_en` is high and `empty` is low; `data_out` reflects `fifo_mem[rd_ptr]` combinationally
3. Write pointer is synchronized into the read clock domain (and vice versa) using gray code + 2-flop synchronizers, so each side can safely compare pointers to generate `full`/`empty` without directly touching the other domain's raw counter

## Repository Structure

```
async-fifo-verilog/
│
├── README.md
│
├── rtl/
│   ├── asynchronous_fifo.v      # top-level module
│   ├── fifo_mem.v                # dual-port memory
│   ├── wptr_handler.v            # write pointer + gray code logic
│   ├── rptr_handler.v            # read pointer + gray code logic
│   └── synchronizer.v            # 2-flop CDC synchronizer
│
├── tb/
│   └── tb_afifo.v                # self-checking testbench
│
└── docs/
    ├── Screenshot 2026-07-16 131057.png   # waveform (write→full→read→empty, errors=0)
    ├── Screenshot 2026-07-16 131457.png   # Schematic
    ├── Screenshot 2026-07-16 132923.png   # supporting waveform detail
    └── asynchronous-fifo-768x434.gif      # Block diagram
```

## Module Descriptions

| Module | Responsibility |
|---|---|
| `asynchronous_fifo.v` | Top-level wrapper instantiating memory, pointer handlers, and synchronizers; exposes `full`/`empty`/`data_out` |
| `fifo_mem.v` | Dual-port RAM array (`DEPTH x DATA_WIDTH`); synchronous write on `wclk`, combinational read |
| `wptr_handler.v` | Generates binary + gray-coded write pointer, increments on `w_en & !full`, generates `full` flag by comparing against synchronized read pointer |
| `rptr_handler.v` | Generates binary + gray-coded read pointer, increments on `r_en & !empty`, generates `empty` flag by comparing against synchronized write pointer |
| `synchronizer.v` | Generic 2-flop synchronizer used to safely pass gray-coded pointers across clock domains |
| `tb_afifo.v` | Testbench driving independent `wclk`/`rclk`, writing a known data sequence, reading it back, and self-checking every output against an `expected[]` array |

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `DEPTH` | 8 | Number of FIFO entries |
| `DATA_WIDTH` | 8 | Width of each data word |
| `PTR_WIDTH` | 3 | `log2(DEPTH)`, width of the pointer's address bits (pointers themselves are `PTR_WIDTH+1` bits for wraparound detection) |

All parameters are set at the top-level and passed down, so the FIFO depth/width can be changed without touching internal logic.

## Simulation Results

![Async FIFO Simulation Waveform](./docs/Screenshot%202026-07-16%20131057.png)

The waveform above shows a complete write → full → read → empty cycle:

- **Write burst**: 8 words (`a0`–`a7`) written sequentially on `wclk`, one `w_en` pulse per write
- **Full flag**: asserts correctly immediately after the 8th write and remains high until a read frees a slot
- **Read burst**: all 8 words read back out on `rclk` in the same order they were written, confirming correct data integrity and ordering across the two clock domains
- **Empty flag**: starts high after reset, drops on the first write, and reasserts once every entry has been drained
- **Self-checking testbench**: the `errors` counter stays at `00000000` for the entire simulation — every value read out was compared against an expected value in real time, with zero mismatches

This confirms correct dual-clock (CDC) behavior: pointer synchronization, flag generation, and data integrity all hold up under back-to-back write and read bursts.

## How to Run

This project was built and simulated in **Xilinx Vivado** (Behavioral Simulation).

1. Create a new Vivado project (or open an existing one)
2. Add all files from `rtl/` as design sources
3. Add `tb/tb_afifo.v` as a simulation source
4. Set `tb_afifo` as the top module for simulation
5. Run Behavioral Simulation
6. Observe `data_out`, `full`, `empty`, and `errors` in the waveform viewer

> Note: this design uses only standard Verilog-2001 constructs and has no Vivado-specific dependencies, so it should also simulate correctly in Icarus Verilog / ModelSim with minor testbench adjustments (e.g. waveform dump commands).

## Key Design Decisions

- **Combinational read (`fifo_mem.v`)**: `data_out` is a continuous assignment (`assign data_out = fifo[rd_ptr]`), not registered. This gives zero-latency reads but means `data_out` is only valid/meaningful when `r_en` was asserted and `empty` was low — it is not held/qualified when idle. This is a deliberate design tradeoff; a registered variant would trade one cycle of latency for a stable output when idle.
- **Gray-code pointers over binary**: chosen specifically because only a single bit toggles per increment, which is what makes it safe to synchronize across clock domains without risk of the synchronizer capturing a pointer value that's off by more than one count.
- **2-flop synchronizers**: the standard minimum depth for resolving metastability with acceptably low failure probability at typical clock speeds; a 3-flop synchronizer could be substituted for higher-reliability applications at the cost of one extra cycle of latency.

---

