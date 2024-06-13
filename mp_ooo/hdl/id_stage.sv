module id_stage import rv32i_types::*;
(
    input  if_id_t                   if_id_reg,
    input logic prediction,rob_stall,rs_stall,
    output id_dis_t                   id_dis_reg_next,
    output logic   [4:0]   rs1, rs2,
    output logic jump,stall,request_prediction,
    output logic [31:0] jal_pc,req_pc
);

// Decode the instruction
logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic [4:0] rd;
logic [31:0] imm;

// Extract fields from the instruction
always_comb begin
    opcode = if_id_reg.inst[6:0];
    funct3 = if_id_reg.inst[14:12];
    funct7 = if_id_reg.inst[31:25];
    rs1 = if_id_reg.inst[19:15];
    rs2 = if_id_reg.inst[24:20];
    rd = if_id_reg.inst[11:7];
    imm = '0; 
    jump = '0;
    jal_pc = '0;
    stall = '0;
    id_dis_reg_next = '0; 
    id_dis_reg_next.next_pc = if_id_reg.next_pc;
    id_dis_reg_next.rs_type = 2'b00;
    request_prediction = '0;
    req_pc = if_id_reg.pc;
    if(!rob_stall &&  !rs_stall)begin
        case (opcode)
            // R-Type
            op_b_reg: begin
                id_dis_reg_next.reg_write = 1'b1;
                case (funct3)
                    sr: begin
                            if (funct7[5]) begin
                                id_dis_reg_next.aluop = alu_sra;
                            end 
                            else if(funct7[0]) begin
                                id_dis_reg_next.aluop = alu_divu;
                                id_dis_reg_next.rs_type = 2'b01;
                            end
                            else begin
                                id_dis_reg_next.aluop = alu_srl;
                            end
                    end
                    add: begin
                        if (funct7[5]) begin
                            id_dis_reg_next.aluop = alu_sub;
                        end 
                        else if (funct7[0]) begin
                            id_dis_reg_next.aluop = alu_mul;
                            id_dis_reg_next.rs_type = 2'b01;
                        end
                        else begin
                            id_dis_reg_next.aluop = alu_add;
                        end
                    end
                    sll: begin
                            if (funct7[0]) begin
                                id_dis_reg_next.aluop = alu_mulh;
                                id_dis_reg_next.rs_type = 2'b01;
                            end else begin
                                id_dis_reg_next.aluop = alu_sll;
                            end
                    end
                    slt: begin
                            if (funct7[0]) begin
                                id_dis_reg_next.aluop = alu_mulhsu;
                                id_dis_reg_next.rs_type = 2'b01;
                            end else begin
                                id_dis_reg_next.aluop = alu_slt;
                            end
                    end
                    sltu: begin
                            if (funct7[0]) begin
                                id_dis_reg_next.aluop = alu_mulhu;
                                id_dis_reg_next.rs_type = 2'b01;
                            end else begin
                                id_dis_reg_next.aluop = alu_sltu;
                            end
                    end
                    axor: begin
                        if(funct7[0]) begin
                            id_dis_reg_next.aluop = alu_div;
                            id_dis_reg_next.rs_type = 2'b01;
                        end
                        else begin
                            id_dis_reg_next.aluop = alu_xor;
                        end
                    end
                    aor: begin
                        if(funct7[0]) begin
                            id_dis_reg_next.aluop = alu_rem;
                            id_dis_reg_next.rs_type = 2'b01;
                        end
                        else begin
                            id_dis_reg_next.aluop = alu_or;
                        end
                    end
                    aand: begin
                        if(funct7[0]) begin
                            id_dis_reg_next.aluop = alu_remu;
                            id_dis_reg_next.rs_type = 2'b01;
                        end
                        else begin
                            id_dis_reg_next.aluop = alu_and;
                            // id_dis_reg_next.rs_type = 2'b01;
                        end
                    end
                    default: begin
                            id_dis_reg_next.aluop = {2'b0,funct3};
                    end
                endcase
            end

            // I-Type
            op_b_imm: begin
                imm = {{20{if_id_reg.inst[31]}}, if_id_reg.inst[31:20]};
                rs2 = '0;
                id_dis_reg_next.reg_write = 1'b1;
                unique case (funct3)
                        sr: begin
                            if (funct7[5]) begin
                                id_dis_reg_next.aluop = alu_sra;
                            end else begin
                                id_dis_reg_next.aluop = alu_srl;
                            end
                        end
                        sll: begin
                            id_dis_reg_next.aluop = alu_sll;
                        end
                        default: begin
                            id_dis_reg_next.aluop = funct3;
                        end
                endcase
            end
            op_b_load: begin
                id_dis_reg_next.rs_type = 2'b10;
                id_dis_reg_next.reg_write = 1'b1;
                rs2 = '0;
                imm = {{20{if_id_reg.inst[31]}}, if_id_reg.inst[31:20]};
            end

            op_b_jalr: begin
                id_dis_reg_next.rs_type = 2'b11;
                id_dis_reg_next.reg_write = 1'b1;
                rs2 = '0;
                imm = {{20{if_id_reg.inst[31]}}, if_id_reg.inst[31:20]};
                jump = '1;
                stall = '1;
            end

            // S-Type
            op_b_store: begin
                id_dis_reg_next.rs_type = 2'b10;
                rd = '0;
                imm = {{20{if_id_reg.inst[31]}}, if_id_reg.inst[31:25], if_id_reg.inst[11:7]};
            end
            // B-Type
            op_b_br: begin
                id_dis_reg_next.rs_type = 2'b11;
                rd = '0;
                imm = {{20{if_id_reg.inst[31]}}, if_id_reg.inst[7], if_id_reg.inst[30:25], if_id_reg.inst[11:8], 1'b0};
                request_prediction = 1'b1;
                if(prediction)begin
                    id_dis_reg_next.prediction_taken = 1'b1;
                    jump = '1;
                    jal_pc = if_id_reg.pc + imm;
                    id_dis_reg_next.next_pc = jal_pc;
                end

            end
            // U-Type
            op_b_lui, op_b_auipc: begin
                id_dis_reg_next.reg_write = 1'b1;
                rs1 = '0;
                rs2 = '0;
                imm = {if_id_reg.inst[31:12], 12'b0};
            end
            // J-Type
            op_b_jal: begin
                id_dis_reg_next.rs_type = 2'b00;
                id_dis_reg_next.reg_write = 1'b1;
                rs1 = '0;
                rs2 = '0;
                imm = {{12{if_id_reg.inst[31]}}, if_id_reg.inst[19:12], if_id_reg.inst[20], if_id_reg.inst[30:21], 1'b0};
                jump = '1;
                jal_pc = if_id_reg.pc + imm;
                id_dis_reg_next.next_pc = jal_pc;
            end
            default: begin
            // Handle unexpected opcodes or place a default operation like NOP
                rs1 = '0;
                rs2 = '0;
                rd = '0;
                imm = '0; // NOP has no immediate
            end
        endcase
    end

    // Update id_dis_reg_next based on decoded instruction
    id_dis_reg_next.pc = if_id_reg.pc;

    id_dis_reg_next.inst = if_id_reg.inst;
    id_dis_reg_next.valid = if_id_reg.valid;
    id_dis_reg_next.order = if_id_reg.order;
    id_dis_reg_next.opcode = opcode;
    id_dis_reg_next.funct3 = funct3;
    id_dis_reg_next.funct7 = funct7;
    id_dis_reg_next.rs1 = rs1;
    id_dis_reg_next.rs2 = rs2;
    id_dis_reg_next.rd = rd;
    id_dis_reg_next.imm = imm;
end

endmodule
