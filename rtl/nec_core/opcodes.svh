task process_ROOT_00xxx00x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_ALU;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00xxx01x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_ALU;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_REG_0;
      d.source1 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1000000x(input bit [7:0] q);
  casex(q)
    8'bxx111xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_CMP;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.alu_operation <= alu_operation_e'(q[5:3]);
      d.opcode <= OP_ALU;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1000001x(input bit [7:0] q);
  casex(q)
    8'bxx111xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_CMP;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM_EXT;
      state <= TERMINAL;
    end
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.alu_operation <= alu_operation_e'(q[5:3]);
      d.opcode <= OP_ALU;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM_EXT;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1101000x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.shift <= shift_operation_e'(q[5:3]);
      d.opcode <= OP_SHIFT1;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1101001x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.shift <= shift_operation_e'(q[5:3]);
      d.opcode <= OP_SHIFT;
      d.reg1 <= CW;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_REG_1;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1100000x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.shift <= shift_operation_e'(q[5:3]);
      d.opcode <= OP_SHIFT;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM8;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_0011100x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_CMP;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_0011101x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_CMP;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_REG_0;
      d.source1 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_11111111(input bit [7:0] q);
  casex(q)
    8'bxx001xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_DEC;
      d.width <= WORD;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_INC;
      d.width <= WORD;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx100xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_BR_ABS;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx101xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_BR_ABS;
      d.opclass <= BRANCH;
      d.width <= DWORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx010xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_BR_ABS;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.push <= STACK_PC;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx011xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_BR_ABS;
      d.opclass <= BRANCH;
      d.width <= DWORD;
      d.push <= STACK_PC | STACK_PS;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx110xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_PUSH;
      d.width <= WORD;
      d.push <= STACK_OPERAND;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_11111110(input bit [7:0] q);
  casex(q)
    8'bxx001xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_DEC;
      d.width <= BYTE;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_INC;
      d.width <= BYTE;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1000010x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_AND;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_11110110(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_AND;
      d.width <= BYTE;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'bxx010xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_NOT;
      d.width <= BYTE;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx011xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_NEG;
      d.width <= BYTE;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx100xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_MULU;
      d.width <= BYTE;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_PRODUCT;
      d.source0 <= OPERAND_ACC;
      d.source1 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx101xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_MUL;
      d.width <= BYTE;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_PRODUCT;
      d.source0 <= OPERAND_ACC;
      d.source1 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx110xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_DIVU;
      d.width <= BYTE;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx111xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_DIV;
      d.width <= BYTE;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_11110111(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_AND;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'bxx010xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_NOT;
      d.width <= WORD;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx011xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_NEG;
      d.width <= WORD;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx100xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_MULU;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_PRODUCT;
      d.source0 <= OPERAND_ACC;
      d.source1 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx101xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_MUL;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_PRODUCT;
      d.source0 <= OPERAND_ACC;
      d.source1 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx110xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_DIVU;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'bxx111xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_DIV;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_01101011(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_MUL;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM_EXT;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_01101001(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_MUL;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_10001101(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_LDEA;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1000100x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_MOV;
      d.mem_write <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1000101x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_MOV;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1100011x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_MOV;
      d.mem_write <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_10001110(input bit [7:0] q);
  casex(q)
    8'bxx0xxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.sreg <= q[4:3];
      d.opcode <= OP_MOV;
      d.width <= WORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_SREG;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_10001100(input bit [7:0] q);
  casex(q)
    8'bxx0xxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.sreg <= q[4:3];
      d.opcode <= OP_MOV;
      d.width <= WORD;
      d.mem_write <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_SREG;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_11000101(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_MOV_SEG;
      d.sreg <= DS0;
      d.width <= DWORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_11000100(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_MOV_SEG;
      d.sreg <= DS1;
      d.width <= DWORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_1000011x(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_XCH;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_REG_0;
      d.source1 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_10001111(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_POP;
      d.width <= WORD;
      d.pop <= STACK_OPERAND;
      d.mem_write <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_01100010(input bit [7:0] q);
  casex(q)
    8'bxxxxxxxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.reg0 <= q[5:3];
      d.opcode <= OP_CHKIND;
      d.width <= DWORD;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_0001000x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_TEST1;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_CL;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_0001100x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_TEST1;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM8;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_0001001x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_CLR1;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_CL;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_0001101x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_CLR1;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM8;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_0001010x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_SET1;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_CL;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_0001110x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_SET1;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM8;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_0001011x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_NOT1;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_CL;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_0001111x(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_NOT1;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      d.source1 <= OPERAND_IMM8;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_00101010(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ROR4;
      d.width <= BYTE;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111_00101000(input bit [7:0] q);
  casex(q)
    8'bxx000xxx: begin
      d.mod <= q[7:6];
      d.rm <= q[2:0];
      d.opcode <= OP_ROL4;
      d.width <= BYTE;
      d.mem_write <= q[7:6] != 2'b11;
      d.mem_read <= q[7:6] != 2'b11;
      d.disp_size <= calc_disp_size(q[2:0], q[7:6]);
      d.segment <= d.segment_override ? d.segment : calc_seg(q[2:0], q[7:6]);;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT_00001111(input bit [7:0] q);
  casex(q)
    8'b00100000: begin
      d.opcode <= OP_ADD4S;
      state <= TERMINAL;
    end
    8'b00100010: begin
      d.opcode <= OP_SUB4S;
      state <= TERMINAL;
    end
    8'b00100110: begin
      d.opcode <= OP_CMP4S;
      state <= TERMINAL;
    end
    8'b00101010: begin
      state <= ROOT_00001111_00101010;
    end
    8'b00101000: begin
      state <= ROOT_00001111_00101000;
    end
    8'b0001000x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_00001111_0001000x;
    end
    8'b0001100x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_00001111_0001100x;
    end
    8'b0001001x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_00001111_0001001x;
    end
    8'b0001101x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_00001111_0001101x;
    end
    8'b0001010x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_00001111_0001010x;
    end
    8'b0001110x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_00001111_0001110x;
    end
    8'b0001011x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_00001111_0001011x;
    end
    8'b0001111x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_00001111_0001111x;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_ROOT(input bit [7:0] q);
  casex(q)
    8'b10010000: begin
      d.opcode <= OP_NOP;
      state <= TERMINAL;
    end
    8'b11111111: begin
      state <= ROOT_11111111;
    end
    8'b11111110: begin
      state <= ROOT_11111110;
    end
    8'b11110110: begin
      state <= ROOT_11110110;
    end
    8'b11110111: begin
      state <= ROOT_11110111;
    end
    8'b01101011: begin
      state <= ROOT_01101011;
    end
    8'b01101001: begin
      state <= ROOT_01101001;
    end
    8'b00100111: begin
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_ADJ4A;
      d.reg0 <= AW;
      d.width <= WORD;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    8'b00101111: begin
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_ADJ4S;
      d.reg0 <= AW;
      d.width <= WORD;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    8'b00110111: begin
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_ADJBA;
      d.reg0 <= AW;
      d.width <= WORD;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    8'b00111111: begin
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_ADJBS;
      d.reg0 <= AW;
      d.width <= WORD;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    8'b11010101: begin
      d.opcode <= OP_CVTDB;
      d.source0 <= OPERAND_IMM8;
      state <= TERMINAL;
    end
    8'b11010100: begin
      d.opcode <= OP_CVTBD;
      d.source0 <= OPERAND_IMM8;
      state <= TERMINAL;
    end
    8'b10011000: begin
      d.opcode <= OP_CVTBW;
      state <= TERMINAL;
    end
    8'b10011001: begin
      d.opcode <= OP_CVTWL;
      state <= TERMINAL;
    end
    8'b10001101: begin
      state <= ROOT_10001101;
    end
    8'b10001110: begin
      state <= ROOT_10001110;
    end
    8'b10001100: begin
      state <= ROOT_10001100;
    end
    8'b11000101: begin
      state <= ROOT_11000101;
    end
    8'b11000100: begin
      state <= ROOT_11000100;
    end
    8'b10011111: begin
      d.opcode <= OP_MOV_AH_PSW;
      state <= TERMINAL;
    end
    8'b10011110: begin
      d.opcode <= OP_MOV_PSW_AH;
      state <= TERMINAL;
    end
    8'b11101001: begin
      d.opcode <= OP_BR_REL;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b11101011: begin
      d.opcode <= OP_BR_REL;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.source0 <= OPERAND_IMM_EXT;
      state <= TERMINAL;
    end
    8'b11101010: begin
      d.opcode <= OP_BR_ABS;
      d.opclass <= BRANCH;
      d.width <= DWORD;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b11101000: begin
      d.opcode <= OP_BR_REL;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.push <= STACK_PC;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b10011010: begin
      d.opcode <= OP_BR_ABS;
      d.opclass <= BRANCH;
      d.width <= DWORD;
      d.push <= STACK_PC | STACK_PS;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b11000011: begin
      d.opcode <= OP_RET;
      d.opclass <= BRANCH;
      d.pop <= STACK_PC;
      state <= TERMINAL;
    end
    8'b11000010: begin
      d.opcode <= OP_RET_POP_VALUE;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.pop <= STACK_PC;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b11001011: begin
      d.opcode <= OP_RET;
      d.opclass <= BRANCH;
      d.pop <= STACK_PC | STACK_PS;
      state <= TERMINAL;
    end
    8'b11001010: begin
      d.opcode <= OP_RET_POP_VALUE;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.pop <= STACK_PC | STACK_PS;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b11001111: begin
      d.opcode <= OP_RET;
      d.opclass <= BRANCH;
      d.pop <= STACK_PC | STACK_PS | STACK_PSW;
      state <= TERMINAL;
    end
    8'b01010000: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_AW;
      state <= TERMINAL;
    end
    8'b01010001: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_CW;
      state <= TERMINAL;
    end
    8'b01010010: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_DW;
      state <= TERMINAL;
    end
    8'b01010011: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_BW;
      state <= TERMINAL;
    end
    8'b01010100: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_SP;
      state <= TERMINAL;
    end
    8'b01010101: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_BP;
      state <= TERMINAL;
    end
    8'b01010110: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_IX;
      state <= TERMINAL;
    end
    8'b01010111: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_IY;
      state <= TERMINAL;
    end
    8'b00000110: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_DS1;
      state <= TERMINAL;
    end
    8'b00001110: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_PS;
      state <= TERMINAL;
    end
    8'b00010110: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_SS;
      state <= TERMINAL;
    end
    8'b00011110: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_DS0;
      state <= TERMINAL;
    end
    8'b10011100: begin
      d.opcode <= OP_PUSH;
      d.push <= STACK_PSW;
      state <= TERMINAL;
    end
    8'b01100000: begin
      d.opcode <= OP_PUSHR;
      d.push <= STACK_AW | STACK_CW | STACK_DW | STACK_BW | STACK_SP | STACK_BP | STACK_IX | STACK_IY;
      state <= TERMINAL;
    end
    8'b01101010: begin
      d.opcode <= OP_PUSH;
      d.width <= BYTE;
      d.push <= STACK_OPERAND;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b01101000: begin
      d.opcode <= OP_PUSH;
      d.width <= WORD;
      d.push <= STACK_OPERAND;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b01011000: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_AW;
      state <= TERMINAL;
    end
    8'b01011001: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_CW;
      state <= TERMINAL;
    end
    8'b01011010: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_DW;
      state <= TERMINAL;
    end
    8'b01011011: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_BW;
      state <= TERMINAL;
    end
    8'b01011100: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_SP;
      state <= TERMINAL;
    end
    8'b01011101: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_BP;
      state <= TERMINAL;
    end
    8'b01011110: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_IX;
      state <= TERMINAL;
    end
    8'b01011111: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_IY;
      state <= TERMINAL;
    end
    8'b00000111: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_DS1;
      state <= TERMINAL;
    end
    8'b00010111: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_SS;
      state <= TERMINAL;
    end
    8'b00011111: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_DS0;
      state <= TERMINAL;
    end
    8'b10011101: begin
      d.opcode <= OP_POP;
      d.pop <= STACK_PSW;
      state <= TERMINAL;
    end
    8'b01100001: begin
      d.opcode <= OP_POPR;
      d.pop <= STACK_AW | STACK_CW | STACK_DW | STACK_BW | STACK_SKIP_SP | STACK_BP | STACK_IX | STACK_IY;
      state <= TERMINAL;
    end
    8'b10001111: begin
      state <= ROOT_10001111;
    end
    8'b11001000: begin
      d.opcode <= OP_PREPARE;
      d.width <= TRIPLE;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b11001001: begin
      d.opcode <= OP_DISPOSE;
      state <= TERMINAL;
    end
    8'b11110100: begin
      d.opcode <= OP_HALT;
      state <= TERMINAL;
    end
    8'b11110101: begin
      d.opcode <= OP_NOT1_CY;
      state <= TERMINAL;
    end
    8'b11111000: begin
      d.opcode <= OP_CLR1_CY;
      state <= TERMINAL;
    end
    8'b11111001: begin
      d.opcode <= OP_SET1_CY;
      state <= TERMINAL;
    end
    8'b11111010: begin
      d.opcode <= OP_DI;
      state <= TERMINAL;
    end
    8'b11111011: begin
      d.opcode <= OP_EI;
      state <= TERMINAL;
    end
    8'b11111100: begin
      d.opcode <= OP_CLR1_DIR;
      state <= TERMINAL;
    end
    8'b11111101: begin
      d.opcode <= OP_SET1_DIR;
      state <= TERMINAL;
    end
    8'b01100010: begin
      state <= ROOT_01100010;
    end
    8'b11001100: begin
      d.opcode <= OP_BRK3;
      state <= TERMINAL;
    end
    8'b11001101: begin
      d.opcode <= OP_BRK;
      d.width <= BYTE;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b11001110: begin
      d.opcode <= OP_BRKV;
      state <= TERMINAL;
    end
    8'b11010111: begin
      d.opcode <= OP_TRANS;
      state <= TERMINAL;
    end
    8'b00001111: begin
      state <= ROOT_00001111;
    end
    8'b00100110: begin
      d.segment <= DS1;
      d.segment_override <= 1;
      state <= PREFIX_CONTINUE;
    end
    8'b00101110: begin
      d.segment <= PS;
      d.segment_override <= 1;
      state <= PREFIX_CONTINUE;
    end
    8'b00110110: begin
      d.segment <= SS;
      d.segment_override <= 1;
      state <= PREFIX_CONTINUE;
    end
    8'b00111110: begin
      d.segment <= DS0;
      d.segment_override <= 1;
      state <= PREFIX_CONTINUE;
    end
    8'b11110000: begin
      d.buslock <= 1;
      state <= PREFIX_CONTINUE;
    end
    8'b11110011: begin
      d.rep <= REPEAT_Z;
      state <= PREFIX_CONTINUE;
    end
    8'b01100101: begin
      d.rep <= REPEAT_C;
      state <= PREFIX_CONTINUE;
    end
    8'b01100100: begin
      d.rep <= REPEAT_NC;
      state <= PREFIX_CONTINUE;
    end
    8'b11110010: begin
      d.rep <= REPEAT_NZ;
      state <= PREFIX_CONTINUE;
    end
    8'b1000000x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1000000x;
    end
    8'b1000001x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1000001x;
    end
    8'b1101000x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1101000x;
    end
    8'b1101001x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1101001x;
    end
    8'b1100000x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1100000x;
    end
    8'b0011100x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_0011100x;
    end
    8'b0011101x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_0011101x;
    end
    8'b0011110x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_CMP;
      d.source0 <= OPERAND_ACC;
      d.source1 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b1000010x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1000010x;
    end
    8'b1010100x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_AND;
      d.source0 <= OPERAND_ACC;
      d.source1 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b1000100x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1000100x;
    end
    8'b1000101x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1000101x;
    end
    8'b1100011x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1100011x;
    end
    8'b1010000x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_MOV;
      d.rm <= 3'b110;
      d.mod <= 2'b00;
      d.disp_size <= calc_disp_size(3'b110, 2'b00);
      d.mem_read <= 1;
      d.dest <= OPERAND_ACC;
      d.source0 <= OPERAND_MODRM;
      state <= TERMINAL;
    end
    8'b1010001x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_MOV;
      d.rm <= 3'b110;
      d.mod <= 2'b00;
      d.disp_size <= calc_disp_size(3'b110, 2'b00);
      d.mem_write <= 1;
      d.dest <= OPERAND_MODRM;
      d.source0 <= OPERAND_ACC;
      state <= TERMINAL;
    end
    8'b1000011x: begin
      d.width <= q[0] ? WORD : BYTE;
      state <= ROOT_1000011x;
    end
    8'b1110010x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_MOV;
      d.mem_read <= 1;
      d.io <= 1;
      d.disp_size <= 1;
      d.dest <= OPERAND_ACC;
      d.source0 <= OPERAND_IO_DIRECT;
      state <= TERMINAL;
    end
    8'b1110110x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_MOV;
      d.mem_read <= 1;
      d.io <= 1;
      d.dest <= OPERAND_ACC;
      d.source0 <= OPERAND_IO_INDIRECT;
      state <= TERMINAL;
    end
    8'b1110011x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_MOV;
      d.mem_write <= 1;
      d.io <= 1;
      d.disp_size <= 1;
      d.dest <= OPERAND_IO_DIRECT;
      d.source0 <= OPERAND_ACC;
      state <= TERMINAL;
    end
    8'b1110111x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_MOV;
      d.mem_write <= 1;
      d.io <= 1;
      d.dest <= OPERAND_IO_INDIRECT;
      d.source0 <= OPERAND_ACC;
      state <= TERMINAL;
    end
    8'b1010101x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_STM;
      state <= TERMINAL;
    end
    8'b1010011x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_CMPBK;
      state <= TERMINAL;
    end
    8'b1010111x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_CMPM;
      state <= TERMINAL;
    end
    8'b1010110x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_LDM;
      state <= TERMINAL;
    end
    8'b1010010x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_MOVBK;
      state <= TERMINAL;
    end
    8'b0110110x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.opcode <= OP_INM;
      state <= TERMINAL;
    end
    8'b011011xx: begin
      d.width <= q[1] ? WORD : BYTE;
      d.opcode <= OP_OUTM;
      state <= TERMINAL;
    end
    8'b01001xxx: begin
      d.reg0 <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_DEC;
      d.width <= WORD;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    8'b01000xxx: begin
      d.reg0 <= q[2:0];
      d.opcode <= OP_ALU;
      d.alu_operation <= ALU_OP_INC;
      d.width <= WORD;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_REG_0;
      state <= TERMINAL;
    end
    8'b10010xxx: begin
      d.reg0 <= q[2:0];
      d.opcode <= OP_XCH;
      d.reg1 <= AW;
      d.width <= WORD;
      d.dest <= OPERAND_REG_1;
      d.source0 <= OPERAND_REG_0;
      d.source1 <= OPERAND_REG_1;
      state <= TERMINAL;
    end
    8'b00xxx00x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.alu_operation <= alu_operation_e'(q[5:3]);
      state <= ROOT_00xxx00x;
    end
    8'b00xxx01x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.alu_operation <= alu_operation_e'(q[5:3]);
      state <= ROOT_00xxx01x;
    end
    8'b00xxx10x: begin
      d.width <= q[0] ? WORD : BYTE;
      d.alu_operation <= alu_operation_e'(q[5:3]);
      d.opcode <= OP_ALU;
      d.dest <= OPERAND_ACC;
      d.source0 <= OPERAND_ACC;
      d.source1 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b1011xxxx: begin
      d.reg0 <= q[2:0];
      d.width <= q[3] ? WORD : BYTE;
      d.opcode <= OP_MOV;
      d.dest <= OPERAND_REG_0;
      d.source0 <= OPERAND_IMM;
      state <= TERMINAL;
    end
    8'b0111xxxx: begin
      d.cond <= q[3:0];
      d.opcode <= OP_B_COND;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.source0 <= OPERAND_IMM_EXT;
      state <= TERMINAL;
    end
    8'b1110xxxx: begin
      d.cond <= q[3:0];
      d.opcode <= OP_B_CW_COND;
      d.opclass <= BRANCH;
      d.width <= WORD;
      d.source0 <= OPERAND_IMM_EXT;
      state <= TERMINAL;
    end
    default: begin
      state <= ILLEGAL;
    end
  endcase
endtask

task process_decode(input bit [7:0] q);
  case(state)
    ROOT_00xxx00x: process_ROOT_00xxx00x(q);
    ROOT_00xxx01x: process_ROOT_00xxx01x(q);
    ROOT_1000000x: process_ROOT_1000000x(q);
    ROOT_1000001x: process_ROOT_1000001x(q);
    ROOT_1101000x: process_ROOT_1101000x(q);
    ROOT_1101001x: process_ROOT_1101001x(q);
    ROOT_1100000x: process_ROOT_1100000x(q);
    ROOT_0011100x: process_ROOT_0011100x(q);
    ROOT_0011101x: process_ROOT_0011101x(q);
    ROOT_11111111: process_ROOT_11111111(q);
    ROOT_11111110: process_ROOT_11111110(q);
    ROOT_1000010x: process_ROOT_1000010x(q);
    ROOT_11110110: process_ROOT_11110110(q);
    ROOT_11110111: process_ROOT_11110111(q);
    ROOT_01101011: process_ROOT_01101011(q);
    ROOT_01101001: process_ROOT_01101001(q);
    ROOT_10001101: process_ROOT_10001101(q);
    ROOT_1000100x: process_ROOT_1000100x(q);
    ROOT_1000101x: process_ROOT_1000101x(q);
    ROOT_1100011x: process_ROOT_1100011x(q);
    ROOT_10001110: process_ROOT_10001110(q);
    ROOT_10001100: process_ROOT_10001100(q);
    ROOT_11000101: process_ROOT_11000101(q);
    ROOT_11000100: process_ROOT_11000100(q);
    ROOT_1000011x: process_ROOT_1000011x(q);
    ROOT_10001111: process_ROOT_10001111(q);
    ROOT_01100010: process_ROOT_01100010(q);
    ROOT_00001111_0001000x: process_ROOT_00001111_0001000x(q);
    ROOT_00001111_0001100x: process_ROOT_00001111_0001100x(q);
    ROOT_00001111_0001001x: process_ROOT_00001111_0001001x(q);
    ROOT_00001111_0001101x: process_ROOT_00001111_0001101x(q);
    ROOT_00001111_0001010x: process_ROOT_00001111_0001010x(q);
    ROOT_00001111_0001110x: process_ROOT_00001111_0001110x(q);
    ROOT_00001111_0001011x: process_ROOT_00001111_0001011x(q);
    ROOT_00001111_0001111x: process_ROOT_00001111_0001111x(q);
    ROOT_00001111_00101010: process_ROOT_00001111_00101010(q);
    ROOT_00001111_00101000: process_ROOT_00001111_00101000(q);
    ROOT_00001111: process_ROOT_00001111(q);
    default: process_ROOT(q);
  endcase
endtask

