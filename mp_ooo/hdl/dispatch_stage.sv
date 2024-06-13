module dis_stage import rv32i_types::*;
#(
    parameter ROB_DEPTH = 32,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1
)
(
    input  id_dis_t                   id_dis_reg,
    input logic rob_flag_1,rob_flag_2,add_full,mul_full,rob_full, lsq_full,control_full,
    input  logic   [31:0]  rs1_v, rs2_v,
    input logic [TAG_LEN:0] rob_num,
    input logic [TAG_LEN:0] cdb_tag1, //cdb1 rob cdb2 mul
    input logic [31:0] cdb_result1,
    input logic update_rob,
    output logic                      enqueue_rob,
    output dis_ex_t                   dis_ex_reg_next,
    output logic rob_stall,rs_stall

);
// Dispatch logic
always_comb begin
    enqueue_rob = '0;
    dis_ex_reg_next = '0;
    rob_stall = '0;
    rs_stall = '0;
    if(add_full || mul_full || lsq_full || control_full)begin
        rs_stall = 1'b1;
    end
    else if(rob_full )begin
        rob_stall = 1'b1;
    end
    else if(id_dis_reg.valid) begin
        enqueue_rob = 1'b1;
        case (id_dis_reg.opcode)
                op_b_imm: begin
                    if(rob_flag_1)begin
                        if(update_rob && cdb_tag1 == rs1_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs1_data = cdb_result1;
                            dis_ex_reg_next.rs1_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qj = rs1_v[TAG_LEN:0];
                            dis_ex_reg_next.rs1_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs1_rdy = 1'b1;
                        dis_ex_reg_next.rs1_data = rs1_v;
                    end
                    dis_ex_reg_next.rs2_rdy = 1'b1;
                    dis_ex_reg_next.rs2_data = id_dis_reg.imm; 
                    dis_ex_reg_next.aluop = id_dis_reg.aluop;
                    case (id_dis_reg.funct3)
                        3'b010: begin // SLT
                            dis_ex_reg_next.cmp =1'b1;
                            dis_ex_reg_next.aluop = blt; // SLT operation
                        end
                        3'b011: begin // SLTU     
                            dis_ex_reg_next.cmp =1'b1;                    
                            dis_ex_reg_next.aluop = bltu; // SLTU operation
                        end
                    endcase
                    
                end
                op_b_reg: begin
                    if(rob_flag_1)begin
                        if(update_rob && cdb_tag1 == rs1_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs1_data = cdb_result1;
                            dis_ex_reg_next.rs1_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qj = rs1_v[TAG_LEN:0];
                            dis_ex_reg_next.rs1_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs1_rdy = 1'b1;
                        dis_ex_reg_next.rs1_data = rs1_v;
                    end
                    if(rob_flag_2)begin
                        if(update_rob && cdb_tag1 == rs2_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs2_data = cdb_result1;
                            dis_ex_reg_next.rs2_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qk = rs2_v[TAG_LEN:0];
                            dis_ex_reg_next.rs2_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs2_rdy = 1'b1;
                        dis_ex_reg_next.rs2_data = rs2_v;
                    end
                    dis_ex_reg_next.aluop = id_dis_reg.aluop;

                    case (id_dis_reg.funct3)
                        3'b010: begin // SLT
                            if (!id_dis_reg.funct7[0]) begin
                                dis_ex_reg_next.cmp =1'b1;
                                dis_ex_reg_next.aluop = blt; // SLT operation
                            end
                        end
                        3'b011: begin // SLTU     
                            if (!id_dis_reg.funct7[0]) begin        
                                dis_ex_reg_next.cmp =1'b1;           
                                dis_ex_reg_next.aluop = bltu; // SLTU operation
                            end
                        end
                    endcase
                end

                op_b_load: begin
                    if(rob_flag_1)begin
                        if(update_rob && cdb_tag1 == rs1_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs1_data = cdb_result1;
                            dis_ex_reg_next.rs1_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qj = rs1_v[TAG_LEN:0];
                            dis_ex_reg_next.rs1_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs1_rdy = 1'b1;
                        dis_ex_reg_next.rs1_data = rs1_v;
                    end
                    if(rob_flag_2)begin
                        if(update_rob && cdb_tag1 == rs2_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs2_data = cdb_result1;
                            dis_ex_reg_next.rs2_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qk = rs2_v[TAG_LEN:0];
                            dis_ex_reg_next.rs2_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs2_rdy = 1'b1;
                        dis_ex_reg_next.rs2_data = rs2_v;
                    end
                    dis_ex_reg_next.aluop = '0;
                    dis_ex_reg_next.cmp = '0;
                    dis_ex_reg_next.load = 1'b1;
                    dis_ex_reg_next.store = 1'b0;
                    dis_ex_reg_next.imm = id_dis_reg.imm;
                    // dis_ex_reg_next.mem_addr = id_dis_reg.rs1_v + id_dis_reg.imm;
                    // dis_ex_reg_next.mem_wdata = '0;
                end

                op_b_store: begin
                    if(rob_flag_1)begin
                        if(update_rob && cdb_tag1 == rs1_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs1_data = cdb_result1;
                            dis_ex_reg_next.rs1_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qj = rs1_v[TAG_LEN:0];
                            dis_ex_reg_next.rs1_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs1_rdy = 1'b1;
                        dis_ex_reg_next.rs1_data = rs1_v;
                    end
                    if(rob_flag_2)begin
                        if(update_rob && cdb_tag1 == rs2_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs2_data = cdb_result1;
                            dis_ex_reg_next.rs2_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qk = rs2_v[TAG_LEN:0];
                            dis_ex_reg_next.rs2_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs2_rdy = 1'b1;
                        dis_ex_reg_next.rs2_data = rs2_v;
                    end
                    dis_ex_reg_next.aluop = '0;
                    dis_ex_reg_next.cmp = '0;
                    dis_ex_reg_next.load = 1'b0;
                    dis_ex_reg_next.store = 1'b1;
                    dis_ex_reg_next.imm = id_dis_reg.imm;
                    // dis_ex_reg_next.mem_addr = id_dis_reg.rs1_v + id_dis_reg.imm;
                    // dis_ex_reg_next.mem_wdata = id_dis_reg.rs2_v;
                end

                op_b_lui: begin
                    dis_ex_reg_next.rs1_rdy = 1'b1;
                    dis_ex_reg_next.rs1_data = id_dis_reg.imm;
                    dis_ex_reg_next.rs2_rdy = 1'b1;
                    dis_ex_reg_next.rs2_data = '0;
                    dis_ex_reg_next.aluop = alu_add;
                end
                op_b_auipc: begin
                    dis_ex_reg_next.rs1_rdy = 1'b1;
                    dis_ex_reg_next.rs1_data = id_dis_reg.pc;
                    dis_ex_reg_next.rs2_rdy = 1'b1;
                    dis_ex_reg_next.rs2_data = id_dis_reg.imm; 
                    dis_ex_reg_next.aluop = alu_add;
                end

                op_b_br: begin
                    if(rob_flag_1)begin
                        if(update_rob && cdb_tag1 == rs1_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs1_data = cdb_result1;
                            dis_ex_reg_next.rs1_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qj = rs1_v[TAG_LEN:0];
                            dis_ex_reg_next.rs1_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs1_rdy = 1'b1;
                        dis_ex_reg_next.rs1_data = rs1_v;
                    end
                    if(rob_flag_2)begin
                        if(update_rob && cdb_tag1 == rs2_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs2_data = cdb_result1;
                            dis_ex_reg_next.rs2_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qk = rs2_v[TAG_LEN:0];
                            dis_ex_reg_next.rs2_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs2_rdy = 1'b1;
                        dis_ex_reg_next.rs2_data = rs2_v;
                    end
                    dis_ex_reg_next.imm = id_dis_reg.imm; 
                    dis_ex_reg_next.br_pc = id_dis_reg.pc + id_dis_reg.imm;
                    dis_ex_reg_next.cmp = 1'b1;
                    dis_ex_reg_next.aluop = id_dis_reg.funct3;
                end

                op_b_jal: begin
                    dis_ex_reg_next.rs1_rdy = 1'b1;
                    dis_ex_reg_next.rs1_data = id_dis_reg.pc;
                    dis_ex_reg_next.rs2_rdy = 1'b1;
                    dis_ex_reg_next.rs2_data = 'd4; 
                    dis_ex_reg_next.aluop = alu_add;
                end

                op_b_jalr: begin
                    if(rob_flag_1)begin
                        if(update_rob && cdb_tag1 == rs1_v[TAG_LEN:0])begin
                            dis_ex_reg_next.rs1_data = cdb_result1;
                            dis_ex_reg_next.rs1_rdy = 1'b1;
                        end
                        else begin
                            dis_ex_reg_next.Qj = rs1_v[TAG_LEN:0];
                            dis_ex_reg_next.rs1_rdy = 1'b0;
                        end
                    end
                    else begin
                        dis_ex_reg_next.rs1_rdy = 1'b1;
                        dis_ex_reg_next.rs1_data = rs1_v;
                    end
                    dis_ex_reg_next.rs2_rdy = 1'b1;
                    dis_ex_reg_next.rs2_data = id_dis_reg.imm; 
                    dis_ex_reg_next.jal_val = id_dis_reg.pc + 'd4;
                    dis_ex_reg_next.aluop = alu_add;
                end
        endcase        
        
        dis_ex_reg_next.rs1 = id_dis_reg.rs1;
        dis_ex_reg_next.rs2 = id_dis_reg.rs2;
        dis_ex_reg_next.reg_write = id_dis_reg.reg_write;
        dis_ex_reg_next.rob_num = rob_num;
        dis_ex_reg_next.rd = id_dis_reg.rd;
        dis_ex_reg_next.opcode = id_dis_reg.opcode;
        dis_ex_reg_next.inst = id_dis_reg.inst;
        dis_ex_reg_next.funct3 = id_dis_reg.funct3;
        dis_ex_reg_next.pc = id_dis_reg.pc;
        dis_ex_reg_next.next_pc = id_dis_reg.next_pc;
        dis_ex_reg_next.valid = id_dis_reg.valid;
        dis_ex_reg_next.order = id_dis_reg.order;
        dis_ex_reg_next.rs_type = id_dis_reg.rs_type;
        dis_ex_reg_next.prediction_taken = id_dis_reg.prediction_taken;
    end
end

endmodule
