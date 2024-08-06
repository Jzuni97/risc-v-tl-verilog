\m4_TLV_version 1d: tl-x.org
\SV
   // ===============
   // LINK: https://makerchip.com/sandbox/0ADf9hJjo/0VmhM0
   // ===============
   
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])



   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  x12 (a2): 10
   //  x13 (a3): 1..10
   //  x14 (a4): Sum
   // 
   m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0
   // Loop:
   m4_asm(ADD, x14, x13, x14)           // Incremental summation
   m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   // Test result value in x14, and set x31 to reflect pass/fail.
   m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end()
   m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------



\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 0 : 
      $taken_br ? $br_tgt_pc : 
      $pc + 4; // although the PC increment is depicted as "+1" (instruction), the actual increment must be by 4 (bytes)
   
   // instantiate IMEM
   `READONLY_MEM($pc, $$instr[31:0]);
   
   // instruction decoding
   $opc[4:0] = $instr[6:2];
   $is_u_instr = $opc ==? 5'b0x101;
   $is_s_instr = $opc ==? 5'b0100x;
   $is_j_instr = $opc == 5'b11011;
   $is_b_instr = $opc == 5'b11000;
   $is_i_instr = $opc == 5'b00000 | $opc == 5'b00001 | $opc == 5'b00100 | $opc == 5'b00110 | $opc == 5'b11001;
   $is_r_instr = $opc == 5'b01011 | $opc == 5'b01100 | $opc == 5'b01110;
   
   // further instruction decoding
   $rs1[4:0] = $instr[19:15];
   $rs2[4:0] = $instr[24:20];
   $rd[5:0] = $instr[11:7];
   $funct3[2:0] = $instr[14:12];
   $funct7[6:0] = $instr[31:25];
   $opcode[6:0] = $instr[6:0];
   $imm[31:0] = $is_i_instr ? {  {21{$instr[31]}},  $instr[30:20]  } :
      $is_s_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[11:7] } :
      $is_b_instr ? { {20{$instr[31]}}, $instr[31], $instr[7], $instr[30:25], $instr[11:8] } :
      $is_u_instr ? { $instr[31:12], {12{$instr[11]}} } :
      $is_j_instr ? { {12{$instr[31]}}, $instr[31], $instr[19:12], $instr[20], $instr[30:21] } : 32'b0;
   
   // checking validity depending on instruction type
   $imm_valid = !$is_r_instr;
   $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
   $rd_valid = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   
   // instruction decoding
   $dec_bits[10:0] = {$instr[30],$funct3,$opcode};
   $is_beq = $dec_bits ==? 11'bx_000_1100011; // note the x in first bit
   $is_bne = $dec_bits ==? 11'bx_001_1100011;
   $is_blt = $dec_bits ==? 11'bx_100_1100011;
   $is_bge = $dec_bits ==? 11'bx_101_1100011;
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;
   $is_addi = $dec_bits ==? 11'bx_000_0010011;
   $is_add = $dec_bits ==? 11'b0_000_0110011;
   
   // ALU
   $result[31:0] = $is_addi ? $src1_value + $imm :
      $is_add ? $src1_value + $src2_value :
      32'b0;
      
   // branching
   $br_tgt_pc[31:0] = $pc + $imm;
   $taken_br = $is_beq ? $src1_value == $src2_value :
      $is_bne ? $src1_value != $src2_value : 
      $is_blt ? ($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31]) : 
      $is_bge ? ($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31]) : 
      $is_bltu ? $src1_value < $src2_value : 
      $is_bgeu ? $src1_value >= $src2_value : 0;
   
   // warning suppression
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid 
    $funct3 $funct3_valid $imm $imm_valid $dec_bits $is_beq $is_bne 
    $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add);
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = 1'b0;
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   m4+rf(32, 32, $reset, $rd_valid, $rd[4:0], $result[31:0], $rs1_valid, $rs1[4:0], $src1_value, $rs2_valid, $rs2[4:0], $src2_value)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+cpu_viz()
\SV
   endmodule
