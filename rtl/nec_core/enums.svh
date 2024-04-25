// Auto-generated from {input_nane} by {sys.argv[0]}
// DO NOT EDIT

typedef enum bit [1:0] {
    DS1 = 2'b00,
    PS  = 2'b01,
    SS  = 2'b10,
    DS0 = 2'b11
} sreg_index_e /* verilator public */;

typedef enum bit [2:0] {
    AL = 3'b000,
    CL = 3'b001,
    DL = 3'b010,
    BL = 3'b011,
    AH = 3'b100,
    CH = 3'b101,
    DH = 3'b110,
    BH = 3'b111
} reg8_index_e /* verilator public */;

typedef enum bit [2:0] {
    AW = 3'b000,
    CW = 3'b001,
    DW = 3'b010,
    BW = 3'b011,
    SP = 3'b100,
    BP = 3'b101,
    IX = 3'b110,
    IY = 3'b111
} reg16_index_e /* verilator public */;

typedef enum bit [1:0] {
    ALU    = 2'b00,
    BLOCK  = 2'b01,
    BRANCH = 2'b10,
    MISC   = 2'b11
} opclass_e /* verilator public */;

typedef enum bit [5:0] {
    OP_INVALID       = 6'b000000,
    OP_NOP           = 6'b000001,
    OP_ALU           = 6'b000010,
    OP_MOV           = 6'b000011,
    OP_MOV_SEG       = 6'b000100,
    OP_MOV_AH_PSW    = 6'b000101,
    OP_MOV_PSW_AH    = 6'b000110,
    OP_XCH           = 6'b000111,
    OP_B_COND        = 6'b001000,
    OP_B_CW_COND     = 6'b001001,
    OP_BR_REL        = 6'b001010,
    OP_BR_ABS        = 6'b001011,
    OP_CALL_REL      = 6'b001100,
    OP_CALL_ABS      = 6'b001101,
    OP_RET           = 6'b001110,
    OP_RET_POP_VALUE = 6'b001111,
    OP_STM           = 6'b010000,
    OP_LDM           = 6'b010001,
    OP_MOVBK         = 6'b010010,
    OP_CMPBK         = 6'b010011,
    OP_CMPM          = 6'b010100,
    OP_INM           = 6'b010101,
    OP_OUTM          = 6'b010110,
    OP_NOT1_CY       = 6'b010111,
    OP_CLR1_CY       = 6'b011000,
    OP_SET1_CY       = 6'b011001,
    OP_DI            = 6'b011010,
    OP_EI            = 6'b011011,
    OP_CLR1_DIR      = 6'b011100,
    OP_SET1_DIR      = 6'b011101,
    OP_HALT          = 6'b011110,
    OP_SHIFT         = 6'b011111,
    OP_SHIFT1        = 6'b100000,
    OP_LDEA          = 6'b100001,
    OP_CVTDB         = 6'b100010,
    OP_CVTBD         = 6'b100011,
    OP_CVTBW         = 6'b100100,
    OP_CVTWL         = 6'b100101,
    OP_DIV           = 6'b100110,
    OP_DIVU          = 6'b100111,
    OP_MUL           = 6'b101000,
    OP_MULU          = 6'b101001,
    OP_PREPARE       = 6'b101010,
    OP_DISPOSE       = 6'b101011,
    OP_CHKIND        = 6'b101100,
    OP_TRANS         = 6'b101101,
    OP_BRK3          = 6'b101110,
    OP_BRK           = 6'b101111,
    OP_BRKV          = 6'b110000,
    OP_ADD4S         = 6'b110001,
    OP_SUB4S         = 6'b110010,
    OP_CMP4S         = 6'b110011,
    OP_ROR4          = 6'b110100,
    OP_ROL4          = 6'b110101,
    OP_PUSH          = 6'b110110,
    OP_PUSHR         = 6'b110111,
    OP_POP           = 6'b111000,
    OP_POPR          = 6'b111001
} opcode_e /* verilator public */;

typedef enum bit [4:0] {
    ALU_OP_ADD   = 5'b00000,
    ALU_OP_OR    = 5'b00001,
    ALU_OP_ADDC  = 5'b00010,
    ALU_OP_SUBC  = 5'b00011,
    ALU_OP_AND   = 5'b00100,
    ALU_OP_SUB   = 5'b00101,
    ALU_OP_XOR   = 5'b00110,
    ALU_OP_CMP   = 5'b00111,
    ALU_OP_NOT   = 5'b01000,
    ALU_OP_NEG   = 5'b01001,
    ALU_OP_INC   = 5'b01010,
    ALU_OP_DEC   = 5'b01011,
    ALU_OP_ADJ4S = 5'b01100,
    ALU_OP_ADJ4A = 5'b01101,
    ALU_OP_ADJBS = 5'b01110,
    ALU_OP_ADJBA = 5'b01111,
    ALU_OP_SET1  = 5'b10000,
    ALU_OP_CLR1  = 5'b10001,
    ALU_OP_TEST1 = 5'b10010,
    ALU_OP_NOT1  = 5'b10011,
    ALU_OP_NONE  = 5'b10100
} alu_operation_e /* verilator public */;

typedef enum bit [2:0] {
    SHIFT_OP_ROL  = 3'b000,
    SHIFT_OP_ROR  = 3'b001,
    SHIFT_OP_ROLC = 3'b010,
    SHIFT_OP_RORC = 3'b011,
    SHIFT_OP_SHL  = 3'b100,
    SHIFT_OP_SHR  = 3'b101,
    SHIFT_OP_NONE = 3'b110,
    SHIFT_OP_SHRA = 3'b111
} shift_operation_e /* verilator public */;

typedef enum bit [3:0] {
    OPERAND_NONE        = 4'b0000,
    OPERAND_ACC         = 4'b0001,
    OPERAND_IMM         = 4'b0010,
    OPERAND_IMM8        = 4'b0011,
    OPERAND_IMM_EXT     = 4'b0100,
    OPERAND_MODRM       = 4'b0101,
    OPERAND_REG_0       = 4'b0110,
    OPERAND_REG_1       = 4'b0111,
    OPERAND_SREG        = 4'b1000,
    OPERAND_PRODUCT     = 4'b1001,
    OPERAND_CL          = 4'b1010,
    OPERAND_IO_DIRECT   = 4'b1011,
    OPERAND_IO_INDIRECT = 4'b1100
} operand_e /* verilator public */;

typedef enum bit [1:0] {
    BYTE = 2'b00,
    WORD = 2'b01,
    TRIPLE = 2'b10,
    DWORD = 2'b11
} width_e /* verilator public */;

typedef enum bit [4:0] {
    IDLE            = 5'b00000,
    BRANCHING       = 5'b00001,
    FETCH_OPERAND   = 5'b00010,
    FETCH_OPERAND1  = 5'b00011,
    WAIT_OPERAND1   = 5'b00100,
    WAIT_OPERAND2   = 5'b00101,
    PUSH            = 5'b00110,
    PUSH_WRITE      = 5'b00111,
    POP             = 5'b01000,
    POP_WAIT        = 5'b01001,
    POP_STORE       = 5'b01010,
    POP_CHECK       = 5'b01011,
    POP_STALL       = 5'b01100,
    EXECUTE_STALL   = 5'b01101,
    EXECUTE         = 5'b01110,
    STORE_DELAY     = 5'b01111,
    STORE_REGISTER  = 5'b10000,
    STORE_MEMORY    = 5'b10001,
    INT_ACK_WAIT    = 5'b10010,
    INT_INITIATE    = 5'b10011,
    INT_FETCH_VEC   = 5'b10100,
    INT_FETCH_WAIT1 = 5'b10101,
    INT_FETCH_WAIT2 = 5'b10110
} cpu_state_e /* verilator public */;

typedef enum bit [3:0] {
    INVALID       = 4'b0000,
    OPCODE_STALL  = 4'b0001,
    OPCODE_FIRST  = 4'b0010,
    OPCODE        = 4'b0011,
    IMMEDIATES    = 4'b0100,
    DECODED       = 4'b0101,
    DECODED1      = 4'b0110,
    OPCODE_STALL0 = 4'b0111,
    OPCODE_STALL1 = 4'b1000,
    OPCODE_STALL2 = 4'b1001,
    OPCODE_STALL3 = 4'b1010
} decode_stage_e /* verilator public */;

typedef enum bit [2:0] {
    REPEAT_NONE = 3'b000,
    REPEAT_C    = 3'b001,
    REPEAT_NC   = 3'b010,
    REPEAT_Z    = 3'b011,
    REPEAT_NZ   = 3'b100
} repeat_e /* verilator public */;

typedef enum bit [1:0] {
    T_1    = 2'b00,
    T_2    = 2'b01,
    T_IDLE = 2'b10
} bcu_t_state_e /* verilator public */;

typedef enum bit [2:0] {
    INT_ACK1  = 3'b000,
    INT_ACK2  = 3'b001,
    IO_READ   = 3'b010,
    IO_WRITE  = 3'b011,
    HALT_ACK  = 3'b100,
    IPQ_FETCH = 3'b101,
    MEM_READ  = 3'b110,
    MEM_WRITE = 3'b111
} bcu_cycle_type_e /* verilator public */;

typedef enum bit [5:0] {
    INITIAL                = 6'b000000,
    TERMINAL               = 6'b000001,
    DELAY_1                = 6'b000010,
    DELAY_2                = 6'b000011,
    DELAY_3                = 6'b000100,
    DELAY_4                = 6'b000101,
    PREFIX_CONTINUE        = 6'b000110,
    ILLEGAL                = 6'b000111,
    ROOT_00xxx00x          = 6'b001000,
    ROOT_00xxx01x          = 6'b001001,
    ROOT_1000000x          = 6'b001010,
    ROOT_1000001x          = 6'b001011,
    ROOT_1101000x          = 6'b001100,
    ROOT_1101001x          = 6'b001101,
    ROOT_1100000x          = 6'b001110,
    ROOT_0011100x          = 6'b001111,
    ROOT_0011101x          = 6'b010000,
    ROOT_11111111          = 6'b010001,
    ROOT_11111110          = 6'b010010,
    ROOT_1000010x          = 6'b010011,
    ROOT_11110110          = 6'b010100,
    ROOT_11110111          = 6'b010101,
    ROOT_01101011          = 6'b010110,
    ROOT_01101001          = 6'b010111,
    ROOT_10001101          = 6'b011000,
    ROOT_1000100x          = 6'b011001,
    ROOT_1000101x          = 6'b011010,
    ROOT_1100011x          = 6'b011011,
    ROOT_10001110          = 6'b011100,
    ROOT_10001100          = 6'b011101,
    ROOT_11000101          = 6'b011110,
    ROOT_11000100          = 6'b011111,
    ROOT_1000011x          = 6'b100000,
    ROOT_10001111          = 6'b100001,
    ROOT_01100010          = 6'b100010,
    ROOT_00001111_0001000x = 6'b100011,
    ROOT_00001111_0001100x = 6'b100100,
    ROOT_00001111_0001001x = 6'b100101,
    ROOT_00001111_0001101x = 6'b100110,
    ROOT_00001111_0001010x = 6'b100111,
    ROOT_00001111_0001110x = 6'b101000,
    ROOT_00001111_0001011x = 6'b101001,
    ROOT_00001111_0001111x = 6'b101010,
    ROOT_00001111_00101010 = 6'b101011,
    ROOT_00001111_00101000 = 6'b101100,
    ROOT_00001111          = 6'b101101
} decode_state_e /* verilator public */;

