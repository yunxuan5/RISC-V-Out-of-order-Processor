/////////////////////////////////////////////////////////////
//  Maybe use some of your types from mp_pipeline here?    //
//    Note you may not need to use your stage structs      //
/////////////////////////////////////////////////////////////

package rv32i_types;

    localparam ROB_DEPTH = 32;
    localparam RF_DEPTH = 16;
    localparam TAG_LEN = $clog2(ROB_DEPTH) - 1;
    localparam RF_LEN = $clog2(RF_DEPTH);


    typedef enum logic [6:0] {
        op_b_lui   = 7'b0110111, // U load upper immediate 
        op_b_auipc = 7'b0010111, // U add upper immediate PC 
        op_b_jal   = 7'b1101111, // J jump and link 
        op_b_jalr  = 7'b1100111, // I jump and link register 
        op_b_br    = 7'b1100011, // B branch 
        op_b_load  = 7'b0000011, // I load 
        op_b_store = 7'b0100011, // S store 
        op_b_imm   = 7'b0010011, // I arith ops with register/immediate operands 
        op_b_reg   = 7'b0110011, // R arith ops with register operands 
        op_b_csr   = 7'b1110011  // I control and status register 
    } rv32i_op_b_t;

    // Add more things here . . .

    typedef enum logic {
        rs2_out = 1'b0
        ,i_imm = 1'b1
    } cmpmux_sel_t;

    typedef struct packed {
        logic [31:0] inst; // Fetched instruction
        logic [31:0] pc;   // Program counter at the time of instruction fetch
        logic [31:0] next_pc;
        logic valid;              // Indicates whether the instruction is valid and should be committed
        logic [63:0] order;       // Unique serial number for each instruction
        // You can add more fields if needed, such as for tracking purposes or for preliminary decoding signals
    } if_id_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic [31:0] next_pc;
        logic   [63:0]      order;
        logic valid;   
        logic prediction_taken;          

        // alu_m1_sel_t        alu_m1_sel;
        // Decoded instruction fields
        logic [6:0] opcode;    // Opcode of the current instruction
        logic [2:0] funct3;    // Function 3 field of the current instruction
        logic [6:0] funct7;    // Function 7 field of the current instruction
        logic [4:0]  rs1;        // Source register 1
        logic [4:0]  rs2;        // Source register 2
        logic [4:0]  rd;         // Destination register
        logic [31:0] imm;        // Immediate value, if applicable
        logic  [1:0]     rs_type; // 00 alu 01 mul 10 branch 11 ld st

        // Control signals
        logic [4:0]      aluop;     // ALU operation type, could be an enumerated type or a bit vector
        logic        reg_write;
    } id_dis_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic [31:0] next_pc;
        logic   [63:0]      order;
        logic valid;   
        logic load;
        logic store;             
        
        logic        reg_write;
        logic       cmp;
        logic  [1:0]     rs_type;

        // logic [31:0] mem_addr;
        logic [31:0] imm;
        logic [31:0] br_pc;
        logic prediction_taken;  
        logic [31:0] jal_val;
        // Decoded instruction fields
        logic [6:0] opcode;    // Opcode of the current instruction
        logic [2:0] funct3;    // Function 3 field of the current instruction
        // logic [6:0] funct7;    // Function 7 field of the current instruction
        logic [4:0]  rs1;        // Source register 1
        logic [4:0]  rs2;        // Source register 2
        logic rs1_rdy,rs2_rdy;
        logic [TAG_LEN:0]Qj,Qk;
        logic [4:0]  rd;         // Destination register
        logic [31:0] rs1_data, rs2_data;
        logic[TAG_LEN:0] rob_num; 
        logic [4:0]      aluop;     // ALU operation type, could be an enumerated type or a bit vector
        
    } dis_ex_t;

    typedef struct packed {
        logic ready; // Whether the result is ready
        logic [31:0] pc;
        logic [TAG_LEN:0] rob_tag;
        logic [31:0] value; // Computed value/result
        logic [4:0]  rd;
        logic [31:0] inst;
        logic [31:0] next_pc;
        logic [4:0]  rs1, rs2;
        logic [31:0] rs1_data, rs2_data;
        logic [31:0] mem_addr;
        logic [31:0] mem_wdata;
        logic [31:0] mem_rdata;
        logic [3:0]  mem_wmask;
        logic [3:0]  mem_rmask;
        logic valid;
        logic branch_mispredicted;
        logic        reg_write;
        logic [63:0] order;
    } rob_entry_t;


    typedef struct packed {
        logic [4:0]      aluop;   // Operation type
        logic[TAG_LEN:0] Qj;    // Tag of the first source operand
        logic[TAG_LEN:0] Qk;    // Tag of the second source operand
        logic[31:0] Vj;   // Value of the first source operand
        logic[31:0] Vk;   // Value of the second source operand
        logic op1_ready,op2_ready,cmp;
        logic busy;       // Indicates if the reservation station is in use
        logic[TAG_LEN:0] rob_num; 
    } reservation_station_t;

    typedef enum logic [1:0] {
        DIV_IDLE,
        DIV_STARTED,
        DIV_WAIT,
        DIV_COMPLETE
    } div_state_t;

    typedef struct {
        logic[31:0] val;   // Value of the first source operand
        logic[TAG_LEN:0]rob_num;    // Tag of the second source operand
        logic clean;  
        // logic [RF_LEN:0]head_ptr;
        // logic [RF_LEN:0]tail_ptr;

    } reg_t;

    typedef struct packed {
        logic valid;
        logic load;
        logic store;
        logic [31:0] mem_wdata;
        logic [31:0] mem_imm; 
        logic [31:0] addr;
        logic [31:0] mem_rdata;
        logic [3:0] mem_rmask;
        logic [3:0] mem_wmask;
        logic forward;
        logic [3:0]fwd_mask;
        logic [31:0]fwd_data;
        logic [2:0] funct3;
        logic [TAG_LEN:0] rob_tag;
        logic[TAG_LEN:0] Qj;    // Tag of the first source operand
        logic[TAG_LEN:0] Qk;    // Tag of the second source operand
        logic[31:0] Vj;   // Value of the first source operand
        logic[31:0] Vk;   // Value of the second source operand
        logic op1_ready,op2_ready;
    } lsq_entry_t;

    typedef struct packed {
        logic [TAG_LEN:0] rob_tag;      // Tag for the corresponding ROB entry
        logic [6:0] opcode;
        logic [4:0] aluop;
        logic [31:0] pc;
        logic valid;              // Valid bit for the entry
        logic[TAG_LEN:0] Qj;    // Tag of the first source operand
        logic[TAG_LEN:0] Qk;    // Tag of the second source operand
        logic[31:0] Vj;   // Value of the first source operand
        logic[31:0] Vk;   // Value of the second source operand
        logic op1_ready,op2_ready,cmp;
        logic [31:0] bp_pc;
        logic [31:0] jal_val;
        logic prediction_taken;  
    } control_entry_t;

    typedef struct packed {
        logic [TAG_LEN:0] rob_tag;      // Tag for the corresponding ROB entry
        logic valid;              // Valid bit for the entry
        logic [31:0] mem_wdata;
        logic [31:0] addr;
        logic [3:0] mem_wmask;
    } sb_entry_t;

    typedef struct packed {
        logic valid;              // Valid bit for the entry
        logic [31:0] mem_wdata;
        logic [31:0] addr;
        logic [3:0] mem_wmask;
    } mq_entry_t;

    typedef enum bit [4:0] {
        alu_add   = 5'b00000,
        alu_sll   = 5'b00001,
        alu_sra   = 5'b00010,
        alu_sub   = 5'b00011,
        alu_xor   = 5'b00100,
        alu_srl   = 5'b00101,
        alu_or    = 5'b00110,
        alu_and   = 5'b00111,
        alu_mul   = 5'b01000,  // Multiply signed-signed
        alu_mulh  = 5'b01001,  // Multiply high signed-signed
        alu_mulhsu= 5'b01010,  // Multiply high signed-unsigned
        alu_mulhu = 5'b01011,   // Multiply high unsigned-unsigned
        alu_slt= 5'b01100,  // Multiply high signed-unsigned
        alu_sltu = 5'b01101,   // Multiply high unsigned-unsigned
        alu_div = 5'b01110,
        alu_divu = 5'b01111,
        alu_rem = 5'b10000,
        alu_remu = 5'b10001
        // You can add more operations if needed, up to 4'b1111
    } alu_ops;


    typedef enum bit [2:0] {
        beq  = 3'b000,
        bne  = 3'b001,
        blt  = 3'b100,
        bge  = 3'b101,
        bltu = 3'b110,
        bgeu = 3'b111
    } branch_funct3_t;

    typedef enum bit [2:0] {
        lb  = 3'b000,
        lh  = 3'b001,
        lw  = 3'b010,
        lbu = 3'b100,
        lhu = 3'b101
    } load_funct3_t;

    typedef enum bit [2:0] {
        sb = 3'b000,
        sh = 3'b001,
        sw = 3'b010
    } store_funct3_t;

    typedef enum bit [2:0] {
        add  = 3'b000, //check bit 30 for sub if op_reg opcode
        sll  = 3'b001,
        slt  = 3'b010,
        sltu = 3'b011,
        axor = 3'b100,
        sr   = 3'b101, //check bit 30 for logical/arithmetic
        aor  = 3'b110,
        aand = 3'b111
    } arith_funct3_t;

endpackage