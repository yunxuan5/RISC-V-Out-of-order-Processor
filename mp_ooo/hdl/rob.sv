module rob
import rv32i_types::*;
#(
    parameter ROB_WIDTH = 46,
    parameter ROB_DEPTH = 32,
    parameter PTR_LEN = $clog2(ROB_DEPTH) + 1,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1
)
(
    input logic rst,branch_mispredicted,
    input logic clk,
    input logic enqueue,
    input id_dis_t id_dis_reg_in,
    input logic update_alu,
    input logic [31:0] update_alu_value,    // from cdb
    input logic [TAG_LEN:0] update_alu_index,update_mul_index,lsq_rob_tag,bp_rob_tag,
    input logic update_mul,
    input logic [31:0] update_mul_value,    // from cdb
    input  logic [31:0] rs1a,rs2a,rs1m,rs2m,  //add mul

    input logic lsq_valid,
    input logic [31:0] lsq_data,
    input logic [31:0] lsq_rs1, lsq_rs2,
    input logic [31:0] lsq_mem_addr, lsq_mem_wdata,lsq_mem_rdata,
    input logic [3:0] lsq_mem_wmask, lsq_mem_rmask,

    input logic bp_valid,bp_mispredict,
    input logic [31:0] bp_data,bp_pc,
    input logic [31:0] bp_rs1, bp_rs2,


    output logic full,
    output logic [1:0] regf_we,
    output rob_entry_t rob_entry_out,
    output logic [4:0] rd_s1, rd_s2,
    output logic [31:0] rd_v,
    output logic [TAG_LEN:0] rob_tag1, rob_tag2,
    output logic [63:0] bp_order
);

    rob_entry_t rob_entry_reg;

    logic [PTR_LEN-1:0] head_ptr;
    logic [PTR_LEN-1:0] tail_ptr;

    logic empty;

    assign full = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) && (head_ptr[PTR_LEN-1] != tail_ptr[PTR_LEN-1]));
    assign empty = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) && (head_ptr[PTR_LEN-1] == tail_ptr[PTR_LEN-1]));

    rob_entry_t rob_queue[ROB_DEPTH];

    always_comb begin
        rob_entry_reg = '0;
        regf_we = '0;
        rob_tag1 = '0;
        rob_tag2 = '0;
        rd_s1 = '0;
        rd_s2 = '0;
        rd_v = '0;
        // mis_tag_start = '0;
        // mis_tag_end = '0;
        bp_order = '0;

        if(enqueue) begin
            rob_entry_reg.inst = id_dis_reg_in.inst;
            rob_entry_reg.pc = id_dis_reg_in.pc;
            rob_entry_reg.next_pc = id_dis_reg_in.next_pc;
            rob_entry_reg.order = id_dis_reg_in.order;
            rob_entry_reg.valid = id_dis_reg_in.valid;
            rob_entry_reg.rs1 = id_dis_reg_in.rs1;
            rob_entry_reg.rs2 = id_dis_reg_in.rs2;
            rob_entry_reg.rs1_data = '0;
            rob_entry_reg.rs2_data = '0;
            rob_entry_reg.mem_addr = '0;
            rob_entry_reg.mem_wdata = '0;
            rob_entry_reg.mem_rdata = '0;
            rob_entry_reg.mem_wmask = '0;
            rob_entry_reg.mem_rmask = '0;
            rob_entry_reg.reg_write = id_dis_reg_in.reg_write;

            rob_entry_reg.ready = '0;
            // rob_entry_reg.alu_op = id_dis_reg_in.aluop;
            rob_entry_reg.rd = id_dis_reg_in.rd;
            rd_s2 = rob_entry_reg.rd;
            rob_entry_reg.rob_tag = tail_ptr[PTR_LEN-2:0];
            rob_tag2 = tail_ptr[PTR_LEN-2:0];

            regf_we[0] = id_dis_reg_in.reg_write;
        end
        
        rob_entry_out = '0;
        if(!empty && rob_queue[head_ptr[PTR_LEN-2 : 0]].ready) begin
            rob_entry_out = rob_queue[head_ptr[PTR_LEN-2 : 0]];
            regf_we[1] = rob_entry_out.reg_write;
            rd_s1 = rob_entry_out.rd;
            rd_v = rob_entry_out.value;
            rob_tag1 = rob_entry_out.rob_tag;
        end

        // if(bp_mispredict)begin
        //     bp_order = rob_queue[bp_rob_tag].order;
        //     mis_tag_start = (bp_rob_tag +1'b1);
        //     if({1'b0,(bp_rob_tag +1'b1)} != tail_ptr%5'd16)begin
        //         mis_tag_end = (tail_ptr[TAG_LEN:0] - 1'b1);
        //     end
        //     else begin
        //         mis_tag_end = tail_ptr[TAG_LEN:0];
        //     end
        // end

    end

    

    always_ff @(posedge clk) begin
        if (rst ||branch_mispredicted) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            for (int i = 0; i < ROB_DEPTH; i++) begin
                rob_queue[i] <= '0;
            end
        end 
        else begin
            if (!bp_mispredict && enqueue && !full) begin
                rob_queue[tail_ptr[PTR_LEN-2 : 0]] <= rob_entry_reg;
                tail_ptr <= tail_ptr + 1'b1;
            end

            if(!empty && rob_queue[head_ptr[PTR_LEN-2 : 0]].ready) begin
                head_ptr <= head_ptr + 1'b1;
                rob_queue[head_ptr[PTR_LEN-2 : 0]] <= '0;
            end

            if (update_alu) begin
                rob_queue[update_alu_index].value <= update_alu_value;
                rob_queue[update_alu_index].ready <= 1'b1;
                rob_queue[update_alu_index].rs1_data <= rs1a;
                rob_queue[update_alu_index].rs2_data <= rs2a;
            end

            if (update_mul) begin
                rob_queue[update_mul_index].value <= update_mul_value;
                rob_queue[update_mul_index].ready <= 1'b1;
                rob_queue[update_mul_index].rs1_data <= rs1m;
                rob_queue[update_mul_index].rs2_data <= rs2m;
            end

            if (lsq_valid) begin
                rob_queue[lsq_rob_tag].value <= lsq_data;
                rob_queue[lsq_rob_tag].mem_addr <= lsq_mem_addr;
                rob_queue[lsq_rob_tag].mem_wmask <= lsq_mem_wmask;
                rob_queue[lsq_rob_tag].mem_rmask <= lsq_mem_rmask;
                rob_queue[lsq_rob_tag].mem_wdata <= lsq_mem_wdata;
                rob_queue[lsq_rob_tag].mem_rdata <= lsq_mem_rdata;
                rob_queue[lsq_rob_tag].ready <= 1'b1;
                rob_queue[lsq_rob_tag].rs1_data <= lsq_rs1;
                rob_queue[lsq_rob_tag].rs2_data <= lsq_rs2;
            end

            if (bp_valid) begin
                rob_queue[bp_rob_tag].value <= bp_data;
                rob_queue[bp_rob_tag].ready <= 1'b1;
                rob_queue[bp_rob_tag].rs1_data <= bp_rs1;
                rob_queue[bp_rob_tag].rs2_data <= bp_rs2;
                rob_queue[bp_rob_tag].branch_mispredicted <= bp_mispredict;
                if(bp_mispredict || rob_queue[bp_rob_tag].inst[6:0] == 7'b1100111 )rob_queue[bp_rob_tag].next_pc <= bp_pc;
                // if(bp_mispredict)begin
                //     for (int j = 0; j < ROB_DEPTH; j++) begin
                //         automatic logic[31:0] idx = tail_ptr + unsigned'(ROB_DEPTH*2 - 1 - j);
                //         if (idx[TAG_LEN:0] == bp_rob_tag) begin
                //             break;
                //         end
                //         rob_queue[idx[TAG_LEN:0]] <= '0;
                //         tail_ptr <= idx[PTR_LEN-1:0];
                //     end
                    
                // end



            end
        end
    end

endmodule : rob