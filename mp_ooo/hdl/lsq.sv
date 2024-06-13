module lsq 
import rv32i_types::*;
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LSQ_DEPTH = 16,
    parameter PTR_LEN = $clog2(LSQ_DEPTH) + 1,
    parameter ROB_DEPTH = 32,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1
)(
    input logic clk,
    input logic rst,branch_mispredicted,

    // Dispatch interface
    input dis_ex_t dis_ex_reg,
    output logic lsq_full,

    // Memory unit interface
    output logic mem_read,
    output logic [ADDR_WIDTH-1:0] mem_addr,
    output logic [DATA_WIDTH-1:0] mem_wdata,
    input logic [DATA_WIDTH-1:0] mem_rdata,
    input logic mem_ready,

    input logic [TAG_LEN:0] cdb_tag1,cdb_tag2,cdb_tag3,cdb_tag4, //add,mul,rob,bp
    input logic [31:0] cdb_result1,cdb_result2,cdb_result3,cdb_result4,
    input logic update_add, update_mul,update_rob,update_bp,

    input logic forward,mem_free,
    input logic [3:0]fwd_mask,
    input logic [31:0]fwd_data,
    

    // Signals interacting with ROB
    output logic lsq_valid,store_buf,read_store_buf,
    output logic [TAG_LEN:0] lsq_rob_tag,
    output logic [31:0] lsq_rs1, lsq_rs2,
    output logic [DATA_WIDTH-1:0] lsq_data,
    output logic [3:0] mem_wmask, mem_rmask,
    output logic [31:0] lsq_mem_addr, lsq_mem_wdata,lsq_mem_rdata,
    output logic [3:0] lsq_mem_wmask, lsq_mem_rmask
);
    lsq_entry_t lsq[LSQ_DEPTH];
    logic [PTR_LEN-1:0]head_ptr,tail_ptr;
    logic [31:0]alu_result,temp_data;


    // FIFO queue status signals
    logic lsq_empty;
    assign lsq_full = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) &&
                    (head_ptr[PTR_LEN-1] != tail_ptr[PTR_LEN-1]));
    assign lsq_empty = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) &&
                        (head_ptr[PTR_LEN-1] == tail_ptr[PTR_LEN-1]));

    // FIFO queue logic
    always_ff @(posedge clk) begin
        if (rst|| branch_mispredicted) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            for (int i = 0; i < LSQ_DEPTH; i++) begin
                lsq[i] <= '0;
            end
        end 
        
        else begin
            
            for (int i = 0; i < LSQ_DEPTH; i++) begin
                if (lsq[i].op1_ready && lsq[i].op2_ready) begin

                    if(lsq[i].store && lsq[i].op1_ready && lsq[i].op2_ready && lsq[i].addr == '0) begin
                        lsq[i].addr <= lsq[i].Vj + lsq[i].mem_imm & 32'hFFFFFFFC;
                        unique case (lsq[i].funct3)
                            sb: begin   
                                lsq[i].mem_wmask <= 4'b0001 << ((lsq[i].Vj + lsq[i].mem_imm) & 2'b11);
                                lsq[i].mem_wdata <= lsq[i].Vk[7:0] << 8 * ((lsq[i].Vj + lsq[i].mem_imm) & 2'b11);
                            end
                            sh: begin   
                                lsq[i].mem_wmask <= 4'b0011 << ((lsq[i].Vj + lsq[i].mem_imm) & 2'b11);
                                lsq[i].mem_wdata <= lsq[i].Vk[15:0] << 16 * (((lsq[i].Vj + lsq[i].mem_imm) & 2'b10)>>1);
                            end
                            sw: begin   
                                lsq[i].mem_wmask <= 4'b1111;
                                lsq[i].mem_wdata <= lsq[i].Vk;
                            end
                            default: lsq[i].mem_wmask <= '0;
                        endcase
                    end

                    if(lsq[i].load && lsq[i].op1_ready && lsq[i].addr == '0)  begin
                        lsq[i].addr <= lsq[i].Vj + lsq[i].mem_imm & 32'hFFFFFFFC;
                        unique case (lsq[i].funct3)
                            lb, lbu: lsq[i].mem_rmask <= 4'b0001 << ((lsq[i].Vj + lsq[i].mem_imm) & 2'b11);
                            lh, lhu: lsq[i].mem_rmask <= 4'b0011 << ((lsq[i].Vj + lsq[i].mem_imm) & 2'b11);
                            lw:      lsq[i].mem_rmask <= 4'b1111;
                            default: lsq[i].mem_rmask <= '0;
                        endcase
                    end
                end
            end

            for (int i = 0; i < LSQ_DEPTH; i++) begin
                if(lsq[i].valid)begin
                    if(update_add) begin
                        if (!lsq[i].op1_ready && lsq[i].Qj == cdb_tag1) begin
                            lsq[i].Vj <= cdb_result1;  
                            lsq[i].op1_ready <= 1;    
                            lsq[i].Qj <= 0;                
                        end
                        if (!lsq[i].op2_ready && lsq[i].Qk == cdb_tag1) begin
                            lsq[i].Vk <= cdb_result1;
                            lsq[i].op2_ready <= 1;
                            lsq[i].Qk <= 0;
                        end
                    end
                    if(update_mul) begin
                        if (!lsq[i].op1_ready && lsq[i].Qj == cdb_tag2) begin
                            lsq[i].Vj <= cdb_result2;  
                            lsq[i].op1_ready <= 1;    
                            lsq[i].Qj <= 0;                
                        end                    
                        if (!lsq[i].op2_ready && lsq[i].Qk == cdb_tag2) begin
                            lsq[i].Vk <= cdb_result2;
                            lsq[i].op2_ready <= 1;
                            lsq[i].Qk <= 0;                
                        end
                    end
                    if(update_rob) begin
                        if (!lsq[i].op1_ready && lsq[i].Qj == cdb_tag3) begin
                            lsq[i].Vj <= cdb_result3;  
                            lsq[i].op1_ready <= 1;    
                            lsq[i].Qj <= 0;                
                        end                    
                        if (!lsq[i].op2_ready && lsq[i].Qk == cdb_tag3) begin
                            lsq[i].Vk <= cdb_result3;
                            lsq[i].op2_ready <= 1;
                            lsq[i].Qk <= 0;                
                        end
                    end
                    if(update_bp) begin
                        if (!lsq[i].op1_ready && lsq[i].Qj == cdb_tag4) begin
                            lsq[i].Vj <= cdb_result4;  
                            lsq[i].op1_ready <= 1;    
                            lsq[i].Qj <= 0;                
                        end                    
                        if (!lsq[i].op2_ready && lsq[i].Qk == cdb_tag4) begin
                            lsq[i].Vk <= cdb_result4;
                            lsq[i].op2_ready <= 1;
                            lsq[i].Qk <= 0;                
                        end
                    end
                end
            end

            if (!branch_mispredicted && (dis_ex_reg.load || dis_ex_reg.store) && !lsq_full) begin
                lsq[tail_ptr[PTR_LEN-2:0]].valid <= 1'b1;
                lsq[tail_ptr[PTR_LEN-2:0]].load <= dis_ex_reg.load;
                lsq[tail_ptr[PTR_LEN-2:0]].store <= dis_ex_reg.store;
                lsq[tail_ptr[PTR_LEN-2:0]].funct3 <= dis_ex_reg.funct3;
                lsq[tail_ptr[PTR_LEN-2:0]].rob_tag <= dis_ex_reg.rob_num;
                lsq[tail_ptr[PTR_LEN-2:0]].mem_imm <= dis_ex_reg.imm;
                if(!dis_ex_reg.rs1_rdy)begin

                    if (update_add && dis_ex_reg.Qj == cdb_tag1) begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Vj <= cdb_result1;  
                        lsq[tail_ptr[PTR_LEN-2:0]].op1_ready <= 1;    
                        lsq[tail_ptr[PTR_LEN-2:0]].Qj <= 0;                
                    end
                    else if (update_mul && dis_ex_reg.Qj == cdb_tag2) begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Vj <= cdb_result2;  
                        lsq[tail_ptr[PTR_LEN-2:0]].op1_ready <= 1;    
                        lsq[tail_ptr[PTR_LEN-2:0]].Qj <= 0;                
                    end
                    else if (update_rob && dis_ex_reg.Qj == cdb_tag3) begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Vj <= cdb_result3;  
                        lsq[tail_ptr[PTR_LEN-2:0]].op1_ready <= 1;    
                        lsq[tail_ptr[PTR_LEN-2:0]].Qj <= 0;                
                    end
                    else if (update_bp && dis_ex_reg.Qj == cdb_tag4) begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Vj <= cdb_result4;  
                        lsq[tail_ptr[PTR_LEN-2:0]].op1_ready <= 1;    
                        lsq[tail_ptr[PTR_LEN-2:0]].Qj <= 0;                
                    end
                    else begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Qj <= dis_ex_reg.Qj;
                        lsq[tail_ptr[PTR_LEN-2:0]].op1_ready <= dis_ex_reg.rs1_rdy;
                        lsq[tail_ptr[PTR_LEN-2:0]].Vj <= dis_ex_reg.rs1_data;
                    end

                end
                else begin
                    lsq[tail_ptr[PTR_LEN-2:0]].Qj <= dis_ex_reg.Qj;
                    lsq[tail_ptr[PTR_LEN-2:0]].op1_ready <= dis_ex_reg.rs1_rdy;
                    lsq[tail_ptr[PTR_LEN-2:0]].Vj <= dis_ex_reg.rs1_data;
                end
                
                if(!dis_ex_reg.rs2_rdy)begin
                    if (update_add && dis_ex_reg.Qk == cdb_tag1) begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Vk <= cdb_result1;
                        lsq[tail_ptr[PTR_LEN-2:0]].op2_ready <= 1;
                        lsq[tail_ptr[PTR_LEN-2:0]].Qk <= 0;                
                    end
                    else if (update_mul && dis_ex_reg.Qk == cdb_tag2) begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Vk <= cdb_result2;
                        lsq[tail_ptr[PTR_LEN-2:0]].op2_ready <= 1;
                        lsq[tail_ptr[PTR_LEN-2:0]].Qk <= 0;                
                    end
                    else if (update_rob  && dis_ex_reg.Qk == cdb_tag3) begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Vk <= cdb_result3;
                        lsq[tail_ptr[PTR_LEN-2:0]].op2_ready <= 1;
                        lsq[tail_ptr[PTR_LEN-2:0]].Qk <= 0;                
                    end
                    else if (update_bp  && dis_ex_reg.Qk == cdb_tag4) begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Vk <= cdb_result4;
                        lsq[tail_ptr[PTR_LEN-2:0]].op2_ready <= 1;
                        lsq[tail_ptr[PTR_LEN-2:0]].Qk <= 0;                
                    end
                    else begin
                        lsq[tail_ptr[PTR_LEN-2:0]].Qk <= dis_ex_reg.Qk;
                        lsq[tail_ptr[PTR_LEN-2:0]].Vk <= dis_ex_reg.rs2_data;
                        lsq[tail_ptr[PTR_LEN-2:0]].op2_ready <= dis_ex_reg.rs2_rdy;
                    end
                end
                else begin
                    lsq[tail_ptr[PTR_LEN-2:0]].Qk <= dis_ex_reg.Qk;
                    lsq[tail_ptr[PTR_LEN-2:0]].Vk <= dis_ex_reg.rs2_data;
                    lsq[tail_ptr[PTR_LEN-2:0]].op2_ready <= dis_ex_reg.rs2_rdy;
                end


                tail_ptr <= tail_ptr + 1'b1;
            end
            if(forward && ((lsq[head_ptr[PTR_LEN-2:0]].mem_rmask & fwd_mask) != lsq[head_ptr[PTR_LEN-2:0]].mem_rmask))begin
                    lsq[head_ptr[PTR_LEN-2:0]].forward <= 1'b1;
                    lsq[head_ptr[PTR_LEN-2:0]].fwd_mask <= fwd_mask;
                    lsq[head_ptr[PTR_LEN-2:0]].fwd_data <= fwd_data;
            end

            if (!lsq_empty && ((lsq[head_ptr[PTR_LEN-2:0]].store && lsq[head_ptr[PTR_LEN-2:0]].mem_wmask!='0) || (forward && ((lsq[head_ptr[PTR_LEN-2:0]].mem_rmask & fwd_mask) == lsq[head_ptr[PTR_LEN-2:0]].mem_rmask)) ||mem_ready) ) begin
                head_ptr <= head_ptr + 1'b1;
                lsq[head_ptr[PTR_LEN-2:0]]<= '0;
            end

            // if(branch_mispredicted)begin
            //     for (int j = 0; j < LSQ_DEPTH; j++) begin
            //         automatic logic[31:0] idx = tail_ptr + unsigned'(LSQ_DEPTH*2 - 1 - j); 
            //         if (idx[PTR_LEN-1:0] == head_ptr) begin
            //             break;
            //         end
            //         if(lsq[idx%LSQ_DEPTH].valid)begin
            //             if(mis_tag_start<=mis_tag_end)begin
            //                 if(lsq[idx%LSQ_DEPTH].rob_tag>=mis_tag_start && lsq[idx%LSQ_DEPTH].rob_tag<=mis_tag_end)begin
            //                     lsq[idx%LSQ_DEPTH]<= '0;
            //                     tail_ptr <= idx[PTR_LEN-1:0];
            //                 end
            //                 else begin
            //                     break;
            //                 end
            //             end
            //             else begin
            //                 if(lsq[idx%LSQ_DEPTH].rob_tag>=mis_tag_start || lsq[idx%LSQ_DEPTH].rob_tag<=mis_tag_end)begin
            //                     lsq[idx%LSQ_DEPTH]<= '0;
            //                     tail_ptr <= idx[PTR_LEN-1:0];
            //                 end
            //                 else begin
            //                     break;
            //                 end
            //             end
            //         end
            //     end
            //     if(!lsq_valid)begin
            //         if(lsq[head_ptr[PTR_LEN-2:0]].valid)begin
            //             if(mis_tag_start<=mis_tag_end)begin
            //                 if(lsq[head_ptr[PTR_LEN-2:0]].rob_tag>=mis_tag_start && lsq[head_ptr[PTR_LEN-2:0]].rob_tag<=mis_tag_end)begin
            //                     lsq[head_ptr[PTR_LEN-2:0]]<= '0;
            //                     tail_ptr <= head_ptr;
            //                 end
            //             end
            //             else begin
            //                 if(lsq[head_ptr[PTR_LEN-2:0]].rob_tag>=mis_tag_start || lsq[head_ptr[PTR_LEN-2:0]].rob_tag<=mis_tag_end)begin
            //                     lsq[head_ptr[PTR_LEN-2:0]]<= '0;
            //                     tail_ptr <= head_ptr;
            //                 end
            //             end
            //         end
            //     end
            // end
        end
    end

    // Memory unit interface logic
    always_comb begin
        mem_read = 1'b0;
        mem_addr = '0;
        mem_wdata = '0;
        lsq_valid = 1'b0;
        lsq_data = '0;
        mem_rmask = '0;
        mem_wmask = '0;
        lsq_rob_tag = lsq[head_ptr[PTR_LEN-2:0]].rob_tag;
        lsq_rs1 = lsq[head_ptr[PTR_LEN-2:0]].Vj;
        lsq_rs2 = lsq[head_ptr[PTR_LEN-2:0]].Vk;
        lsq_mem_addr = '0;
        lsq_mem_rmask = '0;
        lsq_mem_wmask = '0;
        lsq_mem_wdata = '0;
        lsq_mem_rdata = '0;
        alu_result = '0;
        store_buf = '0;
        read_store_buf = '0;

        if (!lsq_empty && lsq[head_ptr[PTR_LEN-2:0]].valid) begin
            if (lsq[head_ptr[PTR_LEN-2:0]].load && lsq[head_ptr[PTR_LEN-2:0]].mem_rmask!='0)begin

                mem_addr = lsq[head_ptr[PTR_LEN-2:0]].addr;
                mem_rmask = lsq[head_ptr[PTR_LEN-2:0]].mem_rmask;
                if(!lsq[head_ptr[PTR_LEN-2:0]].forward)begin
                    read_store_buf = 1'b1;
                end
                if(forward && ((lsq[head_ptr[PTR_LEN-2:0]].mem_rmask & fwd_mask) == lsq[head_ptr[PTR_LEN-2:0]].mem_rmask))begin
                    temp_data = fwd_data;
                    alu_result = lsq[head_ptr[PTR_LEN-2:0]].Vj + lsq[head_ptr[PTR_LEN-2:0]].mem_imm;
                    unique case (lsq[head_ptr[PTR_LEN-2:0]].funct3)
                        lb : lsq_data = {{24{temp_data[7 +8 *alu_result[1:0]]}}, temp_data[8 *alu_result[1:0] +: 8 ]};
                        lbu: lsq_data = {{24{1'b0}}                          , temp_data[8 *alu_result[1:0] +: 8 ]};
                        lh : lsq_data = {{16{temp_data[15+16*alu_result[1]  ]}}, temp_data[16*alu_result[1]   +: 16]};
                        lhu: lsq_data = {{16{1'b0}}                          , temp_data[16*alu_result[1]   +: 16]};
                        lw : lsq_data = temp_data;
                        default: lsq_data = '0;
                    endcase
                    lsq_mem_rdata = temp_data;
                    lsq_valid = 1'b1;
                    lsq_mem_addr = lsq[head_ptr[PTR_LEN-2:0]].addr;
                    lsq_mem_rmask = lsq[head_ptr[PTR_LEN-2:0]].mem_rmask;
                end
                else begin
                    if(mem_free)mem_read = 1'b1;
                end
                if(mem_ready) begin
                    temp_data = mem_rdata;
                    if(lsq[head_ptr[PTR_LEN-2:0]].forward)begin
                        if(lsq[head_ptr[PTR_LEN-2:0]].fwd_mask[3])temp_data[31:24] = lsq[head_ptr[PTR_LEN-2:0]].fwd_data[31:24];
                        if(lsq[head_ptr[PTR_LEN-2:0]].fwd_mask[2])temp_data[23:16] = lsq[head_ptr[PTR_LEN-2:0]].fwd_data[23:16];
                        if(lsq[head_ptr[PTR_LEN-2:0]].fwd_mask[1])temp_data[15:8] = lsq[head_ptr[PTR_LEN-2:0]].fwd_data[15:8];
                        if(lsq[head_ptr[PTR_LEN-2:0]].fwd_mask[0])temp_data[7:0] = lsq[head_ptr[PTR_LEN-2:0]].fwd_data[7:0];
                    end
                    alu_result = lsq[head_ptr[PTR_LEN-2:0]].Vj + lsq[head_ptr[PTR_LEN-2:0]].mem_imm;
                    unique case (lsq[head_ptr[PTR_LEN-2:0]].funct3)
                        lb : lsq_data = {{24{temp_data[7 +8 *alu_result[1:0]]}}, temp_data[8 *alu_result[1:0] +: 8 ]};
                        lbu: lsq_data = {{24{1'b0}}                          , temp_data[8 *alu_result[1:0] +: 8 ]};
                        lh : lsq_data = {{16{temp_data[15+16*alu_result[1]  ]}}, temp_data[16*alu_result[1]   +: 16]};
                        lhu: lsq_data = {{16{1'b0}}                          , temp_data[16*alu_result[1]   +: 16]};
                        lw : lsq_data = temp_data;
                        default: lsq_data = '0;
                    endcase
                    lsq_mem_rdata = temp_data;
                    lsq_valid = 1'b1;
                    lsq_mem_addr = lsq[head_ptr[PTR_LEN-2:0]].addr;
                    lsq_mem_rmask = lsq[head_ptr[PTR_LEN-2:0]].mem_rmask;
                end
            end
            
            else if (lsq[head_ptr[PTR_LEN-2:0]].store && lsq[head_ptr[PTR_LEN-2:0]].mem_wmask!='0) begin
                lsq_valid = 1'b1;
                lsq_mem_addr = lsq[head_ptr[PTR_LEN-2:0]].addr ;
                lsq_mem_wmask = lsq[head_ptr[PTR_LEN-2:0]].mem_wmask;
                lsq_mem_wdata = lsq[head_ptr[PTR_LEN-2:0]].mem_wdata; 
                store_buf = 1'b1;   
            end
        end
    end
endmodule