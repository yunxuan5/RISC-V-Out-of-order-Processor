module control_buffer 
import rv32i_types::*;
#(
    parameter BUFFER_SIZE = 8,
    parameter PTR_LEN = $clog2(BUFFER_SIZE) + 1,
    parameter ROB_DEPTH = 32,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1

)(
    input logic clk,
    input logic rst,
    input logic branch_mispredicted,

    // Dispatch interface
    input dis_ex_t dis_ex_reg,

    // CDB interface (for handling dependencies)
    input logic [TAG_LEN:0] cdb_tag1,cdb_tag2,cdb_tag3,cdb_tag4,
    input logic [31:0] cdb_result1,cdb_result2,cdb_result3,cdb_result4,
    input logic update_add, update_mul,update_rob, update_lsq,

    // Signals interacting with ROB
    output logic bp_valid,prediction_result,prediction_valid,
    output logic [TAG_LEN:0] bp_rob_tag,
    output logic [31:0] bp_rs1, bp_rs2, bp_data,prediction_pc,

    output logic control_full,
    output logic bp_mispredict,
    output logic [31:0] jalr_pc, // jal result
    output logic [31:0] bp_pc
);

    control_entry_t buffer [BUFFER_SIZE];
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] f;
    logic p;

    logic [4:0] aluop;
    logic [PTR_LEN-1:0] head_ptr, tail_ptr;

    logic control_empty;
    assign control_full = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) &&
                    (head_ptr[PTR_LEN-1] != tail_ptr[PTR_LEN-1]));
    assign control_empty = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) &&
                        (head_ptr[PTR_LEN-1] == tail_ptr[PTR_LEN-1]));

    // FIFO queue logic
    always_ff @(posedge clk) begin
        if (rst || branch_mispredicted) begin
            head_ptr <= '0;
            tail_ptr <= '0;

            for (int i = 0; i < BUFFER_SIZE; i++) begin
                buffer[i] <= '0;
            end
        end 
        
        else begin
            for (int i = 0; i < BUFFER_SIZE; i++) begin
                if(buffer[i].valid)begin
                    if(update_add) begin
                        if (!buffer[i].op1_ready && buffer[i].Qj == cdb_tag1) begin
                            buffer[i].Vj <= cdb_result1;  
                            buffer[i].op1_ready <= 1;    
                            buffer[i].Qj <= 0;                
                        end
                        if (!buffer[i].op2_ready && buffer[i].Qk == cdb_tag1) begin
                            buffer[i].Vk <= cdb_result1;
                            buffer[i].op2_ready <= 1;
                            buffer[i].Qk <= 0;
                        end
                    end
                    if(update_mul) begin
                        if (!buffer[i].op1_ready && buffer[i].Qj == cdb_tag2) begin
                            buffer[i].Vj <= cdb_result2;  
                            buffer[i].op1_ready <= 1;    
                            buffer[i].Qj <= 0;                
                        end                    
                        if (!buffer[i].op2_ready && buffer[i].Qk == cdb_tag2) begin
                            buffer[i].Vk <= cdb_result2;
                            buffer[i].op2_ready <= 1;
                            buffer[i].Qk <= 0;                
                        end
                    end
                    if(update_rob) begin
                        if (!buffer[i].op1_ready && buffer[i].Qj == cdb_tag3) begin
                            buffer[i].Vj <= cdb_result3;  
                            buffer[i].op1_ready <= 1;    
                            buffer[i].Qj <= 0;                
                        end                    
                        if (!buffer[i].op2_ready && buffer[i].Qk == cdb_tag3) begin
                            buffer[i].Vk <= cdb_result3;
                            buffer[i].op2_ready <= 1;
                            buffer[i].Qk <= 0;                
                        end
                    end
                    if(update_lsq) begin
                        if (!buffer[i].op1_ready && buffer[i].Qj == cdb_tag4) begin
                            buffer[i].Vj <= cdb_result4;  
                            buffer[i].op1_ready <= 1;    
                            buffer[i].Qj <= 0;                
                        end                    
                        if (!buffer[i].op2_ready && buffer[i].Qk == cdb_tag4) begin
                            buffer[i].Vk <= cdb_result4;
                            buffer[i].op2_ready <= 1;
                            buffer[i].Qk <= 0;                
                        end
                    end
                end
            end

            if (!bp_mispredict && dis_ex_reg.valid && dis_ex_reg.rs_type == 2'b11) begin
                buffer[tail_ptr[PTR_LEN-2:0]].valid <= 1'b1;
                buffer[tail_ptr[PTR_LEN-2:0]].rob_tag <= dis_ex_reg.rob_num;
                buffer[tail_ptr[PTR_LEN-2:0]].pc <= dis_ex_reg.pc;
                buffer[tail_ptr[PTR_LEN-2:0]].opcode <= dis_ex_reg.opcode;
                buffer[tail_ptr[PTR_LEN-2:0]].aluop <= dis_ex_reg.aluop;
                buffer[tail_ptr[PTR_LEN-2:0]].bp_pc <= dis_ex_reg.br_pc;
                buffer[tail_ptr[PTR_LEN-2:0]].jal_val <= dis_ex_reg.jal_val;
                buffer[tail_ptr[PTR_LEN-2:0]].prediction_taken <= dis_ex_reg.prediction_taken;
                // buffer[tail_ptr[PTR_LEN-2:0]].ready <= (target_tag == '0);

                if(!dis_ex_reg.rs1_rdy)begin
                    if (update_add && dis_ex_reg.Qj == cdb_tag1) begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Vj <= cdb_result1;  
                        buffer[tail_ptr[PTR_LEN-2:0]].op1_ready <= 1;    
                        buffer[tail_ptr[PTR_LEN-2:0]].Qj <= 0;                
                    end
                    else if (update_mul && dis_ex_reg.Qj == cdb_tag2) begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Vj <= cdb_result2;  
                        buffer[tail_ptr[PTR_LEN-2:0]].op1_ready <= 1;    
                        buffer[tail_ptr[PTR_LEN-2:0]].Qj <= 0;                
                    end
                    else if (update_rob && dis_ex_reg.Qj == cdb_tag3) begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Vj <= cdb_result3;  
                        buffer[tail_ptr[PTR_LEN-2:0]].op1_ready <= 1;    
                        buffer[tail_ptr[PTR_LEN-2:0]].Qj <= 0;                
                    end
                    else if (update_lsq && dis_ex_reg.Qj == cdb_tag4) begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Vj <= cdb_result4;  
                        buffer[tail_ptr[PTR_LEN-2:0]].op1_ready <= 1;    
                        buffer[tail_ptr[PTR_LEN-2:0]].Qj <= 0;                
                    end
                    else begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Qj <= dis_ex_reg.Qj;
                        buffer[tail_ptr[PTR_LEN-2:0]].op1_ready <= dis_ex_reg.rs1_rdy;
                        buffer[tail_ptr[PTR_LEN-2:0]].Vj <= dis_ex_reg.rs1_data;
                    end

                end
                else begin
                    buffer[tail_ptr[PTR_LEN-2:0]].Qj <= dis_ex_reg.Qj;
                    buffer[tail_ptr[PTR_LEN-2:0]].op1_ready <= dis_ex_reg.rs1_rdy;
                    buffer[tail_ptr[PTR_LEN-2:0]].Vj <= dis_ex_reg.rs1_data;
                end
                
                if(!dis_ex_reg.rs2_rdy)begin
                    if (update_add && dis_ex_reg.Qk == cdb_tag1) begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Vk <= cdb_result1;
                        buffer[tail_ptr[PTR_LEN-2:0]].op2_ready <= 1;
                        buffer[tail_ptr[PTR_LEN-2:0]].Qk <= 0;                
                    end
                    else if (update_mul && dis_ex_reg.Qk == cdb_tag2) begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Vk <= cdb_result2;
                        buffer[tail_ptr[PTR_LEN-2:0]].op2_ready <= 1;
                        buffer[tail_ptr[PTR_LEN-2:0]].Qk <= 0;                
                    end
                    else if (update_rob  && dis_ex_reg.Qk == cdb_tag3) begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Vk <= cdb_result3;
                        buffer[tail_ptr[PTR_LEN-2:0]].op2_ready <= 1;
                        buffer[tail_ptr[PTR_LEN-2:0]].Qk <= 0;                
                    end
                    else if (update_lsq  && dis_ex_reg.Qk == cdb_tag4) begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Vk <= cdb_result4;
                        buffer[tail_ptr[PTR_LEN-2:0]].op2_ready <= 1;
                        buffer[tail_ptr[PTR_LEN-2:0]].Qk <= 0;                
                    end
                    else begin
                        buffer[tail_ptr[PTR_LEN-2:0]].Qk <= dis_ex_reg.Qk;
                        buffer[tail_ptr[PTR_LEN-2:0]].Vk <= dis_ex_reg.rs2_data;
                        buffer[tail_ptr[PTR_LEN-2:0]].op2_ready <= dis_ex_reg.rs2_rdy;
                    end
                end
                else begin
                    buffer[tail_ptr[PTR_LEN-2:0]].Qk <= dis_ex_reg.Qk;
                    buffer[tail_ptr[PTR_LEN-2:0]].Vk <= dis_ex_reg.rs2_data;
                    buffer[tail_ptr[PTR_LEN-2:0]].op2_ready <= dis_ex_reg.rs2_rdy;
                end
                tail_ptr <= tail_ptr + 1'b1;
            end

            if (buffer[head_ptr[PTR_LEN-2:0]].valid && buffer[head_ptr[PTR_LEN-2:0]].op1_ready && buffer[head_ptr[PTR_LEN-2:0]].op2_ready)begin
                buffer[head_ptr[PTR_LEN-2:0]]<= '0;
                head_ptr <= head_ptr + 1'b1;
            end

            // if(branch_mispredicted)begin
            //      for (int j = 0; j < BUFFER_SIZE; j++) begin
            //         automatic logic[31:0] idx = tail_ptr + unsigned'(BUFFER_SIZE*2 - 1 - j);
            //         if (idx[PTR_LEN-1:0] == head_ptr) begin
            //             break;
            //         end
            //         if(buffer[idx%BUFFER_SIZE].valid)begin
            //             if(mis_tag_start<=mis_tag_end)begin
            //                 if(buffer[idx%BUFFER_SIZE].rob_tag>=mis_tag_start && buffer[idx%BUFFER_SIZE].rob_tag<=mis_tag_end)begin
            //                     buffer[idx%BUFFER_SIZE]<= '0;
            //                     tail_ptr <= idx[PTR_LEN-1:0];
            //                 end
            //                 else begin
            //                     break;
            //                 end
            //             end
            //             else begin
            //                 if(buffer[idx%BUFFER_SIZE].rob_tag>=mis_tag_start || buffer[idx%BUFFER_SIZE].rob_tag<=mis_tag_end)begin
            //                     buffer[idx%BUFFER_SIZE]<= '0;
            //                     tail_ptr <= idx[PTR_LEN-1:0];
            //                 end
            //                 else begin
            //                     break;
            //                 end
            //             end
            //         end
            //     end
            //     if(!bp_valid)begin
            //         if(buffer[head_ptr[PTR_LEN-2:0]].valid)begin
            //             if(mis_tag_start<=mis_tag_end)begin
            //                 if(buffer[head_ptr[PTR_LEN-2:0]].rob_tag>=mis_tag_start && buffer[head_ptr[PTR_LEN-2:0]].rob_tag<=mis_tag_end)begin
            //                     buffer[head_ptr[PTR_LEN-2:0]]<= '0;
            //                     tail_ptr <= head_ptr;
            //                 end
            //             end
            //             else begin
            //                 if(buffer[head_ptr[PTR_LEN-2:0]].rob_tag>=mis_tag_start || buffer[head_ptr[PTR_LEN-2:0]].rob_tag<=mis_tag_end)begin
            //                     buffer[head_ptr[PTR_LEN-2:0]]<= '0;
            //                     tail_ptr <= head_ptr;
            //                 end
            //             end
            //         end
            //     end
            // end
        end
    end

    always_comb begin
        aluop = '0;
        a = '0;
        b = '0;
        bp_rs1 = '0;
        bp_rs2 = '0;
        bp_rob_tag = '0;
        bp_valid = '0;
        jalr_pc = '0;
        bp_pc = '0;
        bp_mispredict = '0;
        bp_data = '0;
        prediction_valid = '0;
        prediction_result = '0;
        prediction_pc = buffer[head_ptr[PTR_LEN-2:0]].pc;

        if (buffer[head_ptr[PTR_LEN-2:0]].valid && buffer[head_ptr[PTR_LEN-2:0]].op1_ready && buffer[head_ptr[PTR_LEN-2:0]].op2_ready) begin

            aluop = {2'b0, buffer[head_ptr[PTR_LEN-2:0]].aluop[2:0]};
            a = buffer[head_ptr[PTR_LEN-2:0]].Vj;
            b = buffer[head_ptr[PTR_LEN-2:0]].Vk; 

            bp_rs1 = buffer[head_ptr[PTR_LEN-2:0]].Vj;
            bp_rs2 = buffer[head_ptr[PTR_LEN-2:0]].Vk;
            bp_valid = 1'b1;
            bp_rob_tag = buffer[head_ptr[PTR_LEN-2:0]].rob_tag;
            if(buffer[head_ptr[PTR_LEN-2:0]].opcode == 7'b1100011)begin //branch
                prediction_valid = 1'b1;
                prediction_result = p;
                if(p != buffer[head_ptr[PTR_LEN-2:0]].prediction_taken)begin
                    bp_mispredict = 1'b1;
                    if(p)begin
                        bp_pc = buffer[head_ptr[PTR_LEN-2:0]].bp_pc;
                    end
                    else begin
                        bp_pc = buffer[head_ptr[PTR_LEN-2:0]].pc + 'd4;
                    end
                end
            end
            else begin
                jalr_pc = f & 32'hfffffffe;
                bp_data = buffer[head_ptr[PTR_LEN-2:0]].jal_val;
                bp_pc = jalr_pc;
            end
        end

    end
alu alu_unit (
    .aluop(aluop),
    .a(a),
    .b(b),
    .f(f)
);
cmp my_comp (
    .a(a),
    .b(b),
    .cmpop(aluop[2:0]),
    .br_en(p)
);
endmodule
