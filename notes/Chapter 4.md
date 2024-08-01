## RISC-V CPU Block Diagram Overview

![RISC-V Overview](https://courses.edx.org/asset-v1:LinuxFoundationX+LFD111x+1T2024+type@asset+block/RISC-V_CPU_Block_Diagram.png "RISC-V Overview")

1. **PC Logic** - 
This logic is responsible for the program counter (PC). 
The PC identifies the instruction our CPU will execute next. 
Most instructions execute sequentially, meaning the default behavior of the PC is to increment to the following instruction each clock cycle. Branch and jump instructions, 
however, are non-sequential. They specify a target instruction to execute next, and the PC logic must update the PC accordingly. 
2. **Fetch** - 
The instruction memory (IMem) holds the instructions to execute. To read the IMem, or "fetch", we simply pull out the instruction pointed to by the PC.
3. Decode Logic
Now that we have an instruction to execute, we must interpret, or decode, it. We must break it into fields based on its type. These fields would tell us which registers to read, which operation to perform, etc.
4. **Register File Read** - 
The register file is a small local storage of values the program is actively working with. We decoded the instruction to determine which registers we need to operate on. Now, we need to read those registers from the register file.
5. **Arithmetic Logic Unit (ALU)** - 
Now that we have the register values, it’s time to operate on them. This is the job of the ALU. It will add, subtract, multiply, shift, etc, based on the operation specified in the instruction.
6. **Register File Write** - 
Now the result value from the ALU can be written back to the destination register specified in the instruction.
7. **DMem** - 
Our test program executes entirely out of the register file and does not require a data memory (DMem). But no CPU is complete without one. The DMem is written to by store instructions and read from by load instructions.

In this course, we are focused on the CPU core only. We are ignoring all of the logic that would be necessary to interface with the surrounding system, such as input/output (I/O) controllers, interrupt logic, system timers, etc.

Notably, we are making simplifying assumptions about memory. A general-purpose CPU would typically have a large memory holding both instructions and data. 
At any reasonable clock speed, it would take many clock cycles to access memory. Caches would be used to hold recently-accessed memory data close to the CPU core. We are ignoring all of these sources of complexity. 
We are choosing to implement separate, and very small, instruction and data memories. It is typical to implement separate, single-cycle instruction and data caches, and our IMem and DMem are not unlike such caches.

## PC Logic
![pc](https://courses.edx.org/asset-v1:LinuxFoundationX+LFD111x+1T2024+type@asset+block/Implementing_PC_logic.png "PC Logic")

Initially, we will implement only sequential fetching, so the PC update will be, for now, simply a counter. Note that:
 - The PC is a byte address, meaning it references the first byte of an instruction in the IMem. Instructions are 4 bytes long, so, although the PC increment is depicted as "+1" (instruction), the actual increment must be by 4 (bytes). The lowest two PC bits must always be zero in normal operation.
 - Instruction fetching should start from address zero, so the first $pc value with $reset deasserted should be zero, as is implemented in the logic diagram below.
 - Unlike our earlier counter circuit, for readability, we use unique names for $pc and $next_pc, by assigning $pc to the previous $next_pc.
 
 ![init pc](https://courses.edx.org/asset-v1:LinuxFoundationX+LFD111x+1T2024+type@asset+block/Initial_PC_logic.png "Initial PC Logic")
 
 ## Instruction Memory
 ![IMEM](https://courses.edx.org/asset-v1:LinuxFoundationX+LFD111x+1T2024+type@asset+block/Implementing_instruction_memory.png "IMEM")
 
 We will implement our IMem by instantiating a Verilog macro. This macro accepts a byte address as input, and produces the 32-bit read data as output. The macro can be instantiated, for example, as:

**`READONLY_MEM($addr, $$read_data[31:0])**

Verilog macro instantiation is preceded by a back-tick (not to be confused with a single quote).

In expressions like this that do not syntactically differentiate assigned signals from consumed signals, it is necessary to identify assigned signals using a "$$" prefix. And, as always, an assigned signal declares its bit range. Thus, $$read_data[31:0] is used above.

This macro is simplified in several ways versus what you would typically see for an array macro:
 - There is no way to write to our array. The program specified in the template is magically populated into this array for you.
 - Typically, an array would have a read enable input as well. This read enable would indicate, each cycle, whether to perform a read. Our array will always read, and we are not concerned with the power savings a read enable could offer.
 - Typically, a memory structure like our IMem would be implemented using a physical structure called static random access memory, or SRAM. The address would be provided in one clock cycle, and the data would be read out in the next cycle. Our entire CPU, however, will execute within a single clock cycle. Our array provides its output data on the same clock cycle as the input address. Our macro would result in an implementation using flip-flops that would be far less optimal than SRAM.
 
 ![imh](https://courses.edx.org/asset-v1:LinuxFoundationX+LFD111x+1T2024+type@asset+block/Instruction_memory_hookup.png "Mem Hookup")