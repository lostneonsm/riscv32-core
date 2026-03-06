# Pipelined RISC-V CPU

This repository documents my in-depth implementation of a 5-stage pipelined RISC-V core, presented as two independent, original datapath designs built completely from scratch and not based on any other existing core. I designed it as both an engineering proof-of-concept and a teaching artifact: every major datapath decision, control signal, and hazard mechanism is exposed explicitly in RTL so the architecture can be studied stage by stage.

Verified test assets live under:
- `tb/test_programs/test_alu_mem.s` and `tb/test_programs/test_alu_mem.hex`
- `tb/test_programs/test_branch_jump.s` and `tb/test_programs/test_branch_jump.hex`
- `tb/test_programs/test_load_use.s` and `tb/test_programs/test_load_use.hex`

![Final complete datapath.](./figures/pipelined_datapath.png)

## Table of Contents
- [Overview](#overview)
- [Building a Single-Cycle CPU](#building-a-single-cycle-cpu)
	- [Instruction Set Coverage](#instruction-set-coverage)
	- [ISA Decode and Bit Fields](#isa-decode-and-bit-fields)
	- [Register-Register Operations](#register-register-operations)
	- [Register-Immediate Operations](#register-immediate-operations)
	- [Loads and Stores](#loads-and-stores)
	- [Branches and Jumps](#branches-and-jumps)
- [Pipelined CPU](#pipelined-cpu)
	- [Five-Stage Pipeline](#five-stage-pipeline)
	- [Control Hazards](#control-hazards)
	- [Data Hazards and Resolution Units](#data-hazards-and-resolution-units)
- [Verification and Waveform Analysis](#verification-and-waveform-analysis)
- [Future Engineering Milestones](#future-engineering-milestones)

## Overview

My core is a synchronous 5-stage pipeline with the classic IF, ID, EX, MEM, and WB stages. It implements a 37/40 instruction subset of the RV32I base integer ISA. The three excluded instructions are FENCE, EBREAK, and ECALL.

The design is fully hardware-interlocked. I resolve hazards with data forwarding, pipeline stalling, register-file write-through, and branch/jump control flushes. In practice, this means the pipeline does not rely on software scheduling or delay slots; the RTL itself detects and resolves the hazards at runtime.

Verification was performed with Icarus Verilog and VVP simulation, isolated testbenches, and GTKWave waveform analysis. The current top-level verification entry points are [`tb/tb_cpu_top.v`](../tb/tb_cpu_top.v) for the single-cycle core and [`tb/tb_cpu_top_pipelined.v`](../tb/tb_cpu_top_pipelined.v) for the pipelined core.

I keep the implementation intentionally modular. The key RTL blocks are:

| Module | Role |
| --- | --- |
| [`rtl/core/cpu_top.v`](../rtl/core/cpu_top.v) | Single-cycle top-level integration |
| [`rtl/pipeline/cpu_top_pipelined.v`](../rtl/pipeline/cpu_top_pipelined.v) | 5-stage pipelined top-level integration |
| [`rtl/core/control_unit.v`](../rtl/core/control_unit.v) | Main opcode decode and control signal generation |
| [`rtl/core/imm_gen.v`](../rtl/core/imm_gen.v) | Immediate extraction and sign extension |
| [`rtl/core/alu_control.v`](../rtl/core/alu_control.v) | ALU operation selection |
| [`rtl/core/alu.v`](../rtl/core/alu.v) | Combinational ALU and zero flag generation |
| [`rtl/core/reg_file.v`](../rtl/core/reg_file.v) | 32-word register file with write-through reads |
| [`rtl/core/data_mem.v`](../rtl/core/data_mem.v) | Byte-addressable data memory |
| [`rtl/core/instr_mem.v`](../rtl/core/instr_mem.v) | Instruction memory initialized from HEX test images |
| [`rtl/core/pc.v`](../rtl/core/pc.v) | Stall-aware program counter |
| [`rtl/pipeline/if_id_reg.v`](../rtl/pipeline/if_id_reg.v) | IF/ID pipeline register |
| [`rtl/pipeline/id_ex_reg.v`](../rtl/pipeline/id_ex_reg.v) | ID/EX pipeline register |
| [`rtl/pipeline/ex_mem_reg.v`](../rtl/pipeline/ex_mem_reg.v) | EX/MEM pipeline register |
| [`rtl/pipeline/mem_wb_reg.v`](../rtl/pipeline/mem_wb_reg.v) | MEM/WB pipeline register |
| [`rtl/pipeline/forwarding_unit.v`](../rtl/pipeline/forwarding_unit.v) | RAW forwarding selection logic |
| [`rtl/pipeline/hazard_unit.v`](../rtl/pipeline/hazard_unit.v) | Load-use stall detection |

## Building a Single-Cycle CPU

### Part 1: Architectural Evolution - The Single-Cycle Foundation

Before I introduced parallelism, I built a single-cycle RISC-V core as the architectural baseline. My design process started by reading Chapter 2 of the RISC-V Unprivileged Architecture Manual and translating each specification constraint into concrete Verilog structures: opcode decode, immediate generation, register-file access, ALU selection, memory access, and next-PC selection.

That foundation gave me a complete, working reference model for correctness. Once the single-cycle path matched the ISA behavior I wanted, I could pipeline it with confidence and reason about each hazard in isolation.

### Instruction Set Coverage

The implementation covers the main RV32I instruction families shown below.

| Group | Instructions |
| --- | --- |
| Register-Register | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| Register-Immediate | ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI |
| Loads | LB, LH, LW, LBU, LHU |
| Stores | SB, SH, SW |
| Branches | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jumps | JAL, JALR |
| Upper Immediates | LUI, AUIPC |

### ISA Decode and Bit Fields

The main decode path is built around the standard RV32I bit fields: opcode in `instr[6:0]`, `rd` in `instr[11:7]`, `funct3` in `instr[14:12]`, `rs1` in `instr[19:15]`, `rs2` in `instr[24:20]`, and `funct7[5]` in `instr[30]`.

The following table summarizes the encoding choices I use in the control path.

| Instruction class | Format | Opcode | funct3 usage | funct7 / selector usage |
| --- | --- | --- | --- | --- |
| R-type ALU | R | 0110011 | ADD/SUB = 000, SLL = 001, SLT = 010, SLTU = 011, XOR = 100, SRL/SRA = 101, OR = 110, AND = 111 | `funct7[5]` selects SUB over ADD and SRA over SRL |
| I-type ALU | I | 0010011 | Same funct3 map as R-type, but the immediate is used as operand B | `funct7[5]` selects SRAI over SRLI |
| Loads | I | 0000011 | LB = 000, LH = 001, LW = 010, LBU = 100, LHU = 101 | No funct7 dependency |
| Stores | S | 0100011 | SB = 000, SH = 001, SW = 010 | Immediate is split across `instr[31:25]` and `instr[11:7]` |
| Branches | B | 1100011 | BEQ = 000, BNE = 001, BLT = 100, BGE = 101, BLTU = 110, BGEU = 111 | Branch target uses the B-type scrambled offset |
| JALR | I | 1100111 | funct3 fixed at 000 | Jump target comes from `rs1 + imm` |
| LUI | U | 0110111 | funct3 unused | Upper 20-bit immediate is shifted left by 12 |
| AUIPC | U | 0010111 | funct3 unused | Upper 20-bit immediate is added to PC |
| JAL | J | 1101111 | funct3 unused | J-type scrambled offset and implicit low zero bit |

To keep the datapath explicit, I also use a few custom control encodings:

| Signal | Encoding | Meaning |
| --- | --- | --- |
| `alu_op` | `00` | ADD-style address calculation for loads/stores and JAL/JALR setup |
| `alu_op` | `01` | Branch compare class |
| `alu_op` | `10` | Full ALU decode through `funct3` and `funct7[5]` |
| `alu_src_a` | `00` | Use `rs1` |
| `alu_src_a` | `01` | Use PC |
| `alu_src_a` | `10` | Use zero |
| `mem_to_reg` | `00` | Write back ALU result |
| `mem_to_reg` | `01` | Write back data memory output |
| `mem_to_reg` | `10` | Write back PC + 4 |

### Register-Register Operations

The register-register class is driven by `control_unit.v`, `alu_control.v`, and `alu.v`. The control unit asserts `reg_write`, selects the R-type ALU path with `alu_op = 2'b10`, and marks the instruction as `is_rtype` so the ALU controller can use `funct7[5]` when it matters.

My ALU control map is a compact 4-bit encoding:

| `alu_ctrl` | Operation |
| --- | --- |
| `0000` | ADD |
| `0001` | SUB |
| `0010` | AND |
| `0011` | OR |
| `0100` | XOR |
| `0101` | SLL |
| `0110` | SRL |
| `0111` | SRA |
| `1000` | SLT |
| `1001` | SLTU |

The ALU itself is purely combinational. It accepts `operand_a`, `operand_b`, and `alu_ctrl`, and emits both the arithmetic result and a `zero` flag. For shifts, the lower 5 bits of `operand_b` define the shift amount, which is the correct RV32 shift width.

The register file is a 32-word multi-port structure with two combinational read ports and one synchronous write port. In `reg_file.v`, reads are written through in the same cycle if the destination register matches either source address and `reg_write` is asserted. That preserves architectural correctness on read/write collisions and prevents stale data from leaking into the execute stage.

I also keep x0 hardwired to zero on read, so the architectural zero register remains stable regardless of any writeback activity elsewhere in the machine.

### Register-Immediate Operations

The immediate generator, `imm_gen.v`, is responsible for extracting and sign-extending all architectural immediate formats:

- I-type immediates come from `instr[31:20]`
- S-type immediates are split across `instr[31:25]` and `instr[11:7]`
- B-type branch offsets are reassembled from the scrambled bit layout and forced to a zero low bit
- U-type immediates place `instr[31:12]` in the upper 20 bits and fill the low 12 bits with zero
- J-type offsets are reconstructed from the JAL encoding and also force bit 0 to zero

This matters because the immediate generator handles only the structural bit layout and sign extension. The actual meaning of the immediate is selected later by control. For example, ADDI, ANDI, SLTI, shifts, and the other I-type ALU operations all share the same immediate extraction path, while `alu_control.v` resolves which arithmetic or logical operation should happen once the operand reaches EX.

### Loads and Stores

I chose a Harvard architecture: instruction fetch and data access use separate memories. The instruction memory is read-only and combinational, while the data memory is a separate byte-addressable array. This keeps fetch independent from data access and avoids structural contention between IF and MEM.

The data memory in `data_mem.v` is organized as 4 KB of 32-bit words, indexed by `addr[31:2]`. The lower two address bits are used as a byte offset within the selected word. That arrangement gives me byte-addressable behavior while still storing data in word granularity.

The memory layout is little-endian. Byte address 0 maps to the least significant byte of the selected word, and higher byte addresses map upward through the word. Halfword accesses follow the same convention, and sign extension is applied for LB and LH while LBU and LHU zero-extend the fetched value.

Aligned word stores write the full 32-bit word. Byte stores update a single byte lane, and halfword stores update one aligned halfword lane. Unaligned halfword writes are intentionally ignored, which keeps the memory model simple and deterministic for this proof-of-concept.

### Branches and Jumps

Branches and jumps are resolved around the program counter plus an immediate offset. For a taken branch, the next PC is `PC + imm`. For JAL, the next PC is also `PC + imm`. For JALR, the target comes from the ALU result, which is `rs1 + imm`.

The actual branch decision is made dynamically in the EX stage. I do not pre-resolve branches in ID. Instead, the ALU produces the comparison result, and `branch_taken` is derived from `funct3` plus the ALU flags or comparison bit:

- BEQ and BNE use the ALU zero flag
- BLT, BGE, BLTU, and BGEU use the ALU comparison result in `alu_result[0]`

This keeps the decode path simple and shifts the control decision to the stage where the operands are already available.

For JAL and JALR, I preserve `PC + 4` on the write-back data bus. In the single-cycle design, that value is selected directly by `mem_to_reg`. In the pipelined design, the value is carried through `pc_plus4_ex`, `pc_plus4_ex_mem`, and `pc_plus4_mem_wb` so the link register sees the correct return address at WB.

## Pipelined CPU

### Part 2: Pipelining the Core & Moving to Parallelism

The pipeline is the physical realization of the same single-cycle behavior, but split across five stages so multiple instructions can be in flight at once. I inserted four intermediate pipeline registers - IF/ID, ID/EX, EX/MEM, and MEM/WB - and then threaded the control and data bundles through them so each stage sees only the information it needs.

The goal was not to invent a new ISA machine. It was to preserve the single-cycle semantics while increasing throughput through parallel stage execution.

### Five-Stage Pipeline

The stage boundaries in `cpu_top_pipelined.v` are explicit:

- IF fetches the instruction using `pc_current`
- ID decodes the opcode, register specifiers, immediate, and control signals
- EX performs ALU work, branch evaluation, and forwarding selection
- MEM accesses `data_mem`
- WB selects between ALU result, memory data, and PC + 4

The pipeline registers carry both control and data. For example, `id_ex_reg.v` latches `reg_write`, `alu_src`, `alu_src_a`, `mem_read`, `mem_write`, `branch`, `jump`, `jump_src`, `mem_to_reg`, `alu_op`, `is_rtype`, `pc`, `rs1_data`, `rs2_data`, `imm`, `rd_addr`, `rs1_addr`, `rs2_addr`, `funct3`, and `funct7_bit5`. That makes the EX stage self-sufficient when it finally executes.

### Control Hazards

My control-hazard policy is a simple predict-not-taken scheme. The fetch path always assumes the next instruction is `pc_current + 4` unless the EX stage later proves that a branch or jump must redirect control flow.

The redirect path is driven by `pc_redirect_ex = jump_id_ex || branch_taken_ex`. If a redirect occurs, `pc_redirect_target` is selected as either the ALU result for JALR or `pc_id_ex + imm_id_ex` for JAL and branches. Once that redirect is asserted, I flush the younger instructions sitting in IF/ID and ID/EX so they cannot commit incorrect side effects.

This is the key control-hazard mechanism in the design: the branch or jump resolves in EX, the new target is applied immediately to the PC, and the stale instructions in the front of the pipe are converted into bubbles.

### Data Hazards and Resolution Units

#### Data Forwarding

Most RAW hazards are handled without stalling by the forwarding unit in `forwarding_unit.v`. The bypass logic checks whether the EX-stage instruction is waiting on a destination register that already exists in either EX/MEM or MEM/WB.

The selection encoding is:

| Forward select | Meaning |
| --- | --- |
| `00` | Use the original register-file operand |
| `01` | Forward from EX/MEM (`alu_result_ex_mem`) |
| `10` | Forward from MEM/WB (`rd_data_wb`) |

The matching logic compares `rs1_addr_id_ex` and `rs2_addr_id_ex` against the downstream destination registers `rd_addr_ex_mem` and `rd_addr_mem_wb`. EX/MEM has priority because it is the newer result. That priority matters when two in-flight instructions write the same architectural register and the youngest value must win.

Once the select lines are generated, the EX stage chooses `rs1_forwarded` and `rs2_forwarded`, and those values feed the ALU or the store-data path.

#### Load-Use Stalls

Forwarding cannot solve the classic load-use hazard because the loaded data does not exist soon enough for the very next EX stage. In my design, `hazard_unit.v` detects exactly that one case.

The stall condition is asserted when:

- the instruction currently in EX is a load (`mem_read_id_ex` is high)
- the destination register is not x0
- `rd_addr_id_ex` matches either `rs1_addr` or `rs2_addr` from the instruction in ID

When `stall` is asserted, the PC and IF/ID register hold their current values, and the ID/EX register is synchronously flushed so it injects a NOP bubble. The IF/ID stage therefore preserves the dependent instruction for one cycle while the load completes, and the bubble gives the memory system time to produce the data before the dependent ALU operation reaches EX.

This is hardware interlocking in its cleanest form: the dependency is detected automatically, the pipeline pauses for exactly one cycle, and then execution resumes with correct data.

#### Write-Through

The register file handles same-cycle read/write collisions through write-through bypassing. If the current writeback destination matches `rs1_addr` or `rs2_addr`, the read port returns `rd_data` instead of the older stored array value.

That behavior is important for two reasons. First, it eliminates a common read-after-write race when an instruction reads a register in the same cycle another instruction writes it back. Second, it keeps the architectural view of the register file consistent with the programmer's expectation that WB has already produced the newest value.

## Verification and Waveform Analysis

I validated the design with targeted assembly programs in `tb/test_programs/` and watched the results in GTKWave.

The current test cases cover three distinct stress patterns:

- `test_alu_mem.s` / `test_alu_mem.hex` exercises the ALU, immediate decode, byte and halfword memory behavior, and sign/zero extension
- `test_branch_jump.s` / `test_branch_jump.hex` stresses taken branches, JAL, JALR, AUIPC, and LUI
- `test_load_use.s` / `test_load_use.hex` is the hazard test that demonstrates the load-use stall path

The pipeline testbench in `tb/tb_cpu_top_pipelined.v` runs long enough for the machine to drain after the last instruction is fetched, then prints all 31 writable architectural registers for inspection. The single-cycle testbench in `tb/tb_cpu_top.v` uses the same style of final register dump so I can compare the reference behavior against the pipelined implementation.

The instruction memory currently loads `tb/test_programs/test_load_use.hex` by default, which makes the load-use sequence the out-of-the-box smoke test for the pipelined core.

### Hazard Verification Narrative

A correct waveform trace tells a very specific story.

First, the load-use program places `lw x3, 0(x1)` immediately before `add x4, x3, x3`. When the load is in EX, the dependent add is still in ID. At that point `hazard_unit.v` sees `mem_read_id_ex = 1`, `rd_addr_id_ex = 3`, and a matching source register in ID. `stall` rises.

On the next clock edge, the PC and IF/ID register freeze, so the dependent add does not advance. The ID/EX register is flushed to a NOP bubble, which gives the load one more cycle to complete the MEM stage. In GTKWave, that shows up as a one-cycle pause in fetch/decode while the younger instruction is held back.

One cycle later, the loaded word is available in MEM/WB and the forwarding muxes can safely select the freshly produced value. In this case, the forwarding controls transition to the MEM/WB path, so the dependent add receives the correct operand without needing any manual intervention. The pipeline then resumes steady-state execution with the correct architectural result preserved.

The branch and jump test verifies the complementary control path. When a branch resolves taken or a jump is asserted, `pc_redirect_ex` goes high, the target is computed from the EX-stage operands, and the younger instructions in IF/ID and ID/EX are flushed. In the waveform, this appears as a clean control redirect with no stale instruction committing after the taken branch.

Taken together, the cycle timing, opcode progression, stall pulse, and forwarding select lines prove that the pipeline behaves correctly under stress rather than only in the straight-line case.

## Future Engineering Milestones

My next milestones for this project are straightforward:

1. Synthesize the core onto a physical FPGA development board and validate timing on real hardware.
2. Add memory-mapped I/O peripherals such as UART and GPIO so the CPU can interact with the outside world.
3. Add a custom MAC instruction through RISC-V's reserved `custom-0` opcode space, extending the ALU and control unit as a first step toward matrix-multiply-heavy acceleration.
4. Develop a separate AI accelerator core that builds on this CPU, likely as the scalar and control unit, to target basic neural network inference primitives.

