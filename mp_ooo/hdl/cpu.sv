module cpu
import rv32i_types::*;
#(
    parameter ROB_DEPTH = 32,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1
)
(
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input   logic           clk,
    input   logic           rst,

    // output  logic   [31:0]  imem_addr,
    // output  logic   [3:0]   imem_rmask,
    // input   logic   [31:0]  imem_rdata,
    // input   logic           imem_resp,

    // output  logic   [31:0]  dmem_addr,
    // output  logic   [3:0]   dmem_rmask,
    // output  logic   [3:0]   dmem_wmask,
    // input   logic   [31:0]  dmem_rdata,
    // output  logic   [31:0]  dmem_wdata,
    // input   logic           dmem_resp

    // Single memory port connection when caches are integrated into design (CP3 and after)

    output logic   [31:0]      bmem_addr,
    output logic               bmem_read,
    output logic               bmem_write,
    output logic   [63:0]      bmem_wdata,
    input logic               bmem_ready,

    input logic   [31:0]      bmem_raddr,
    input logic   [63:0]      bmem_rdata,
    input logic               bmem_rvalid

);

logic enqueue, dequeue, full, empty;

logic enqueue_rob, rob_full, reg_full;
rob_entry_t rob_entry_out;
logic update_alu, update_mul,update_bp;
logic [TAG_LEN:0] update_alu_index, update_mul_index;
logic [31:0] update_alu_value, update_mul_value,rs1m,rs1a,rs2m,rs2a;

logic [31:0] pc_next;
logic [63:0] order,bp_order; // Serial number counter for each instruction
logic [31:0] enqueue_wdata, dequeue_rdata, enqueue_pc, dequeue_pc;

logic [255:0] data_out;    // Output data to cache
logic [31:0] data_out_addr;// Address for the output data
logic data_out_valid;   
logic [255:0] i_data_out,d_data_out;
logic [31:0] i_addr,d_addr;
logic    i_read,i_write,d_read,d_write;
logic   [255:0] i_rdata,d_rdata,d_wdata;
logic   i_resp,d_resp;

logic   [31:0]  imem_addr;
logic   [3:0]   imem_rmask;
logic   [31:0]  imem_rdata;
logic           imem_resp;

logic   [31:0]  dmem_addr;
logic   [3:0]   dmem_rmask;
logic   [3:0]   dmem_wmask;
logic   [31:0]  dmem_rdata;
logic   [31:0]  dmem_wdata;
logic           dmem_resp;

logic   [4:0]   rs1_s;
logic   [4:0]   rs2_s;
logic   [4:0]   rs1;
logic   [4:0]   rs2;
logic   [4:0]   rd_s1, rd_s2;

logic    [1:0]       regf_we;
logic   [31:0]  rs1_v;
logic   [31:0]  rs2_v;
logic   [31:0]  rd_v;
logic   [TAG_LEN:0]  rob_tag1, rob_tag2, mis_tag_start,mis_tag_end;
logic rob_flag_1,rob_flag_2;
logic add_full, mul_full, lsq_full,control_full;

logic mem_read, mem_write, mem_ready, lsq_valid;
logic [31:0] mem_addr, mem_wdata, mem_rdata;
logic [3:0] mem_rmask, mem_wmask;
logic [TAG_LEN:0] lsq_rob_tag;
logic [31:0] lsq_rs1, lsq_rs2;
logic [31:0] lsq_data, lsq_mem_wdata, lsq_mem_addr, lsq_mem_rdata, fwd_data, sb_addr, sb_wdata;
logic [3:0] lsq_mem_rmask, lsq_mem_wmask, fwd_mask, sb_wmask;
logic read_store_buf, forward, store_buf,mem_free;

logic bp_valid,bp_mispredict;
logic [31:0] bp_data, bp_pc;
logic [TAG_LEN:0] bp_rob_tag;
logic [31:0] bp_rs1, bp_rs2;

logic jump, stall,jalr_stall,jal_stall,bp_stall,flush_ins, ld_stall,branch_mispredicted;
logic [31:0] jal_pc, jalr_pc, br_pc,jalr_pc2;
logic rob_stall, rs_stall;
logic grant_i_cache, grant_d_cache;  
logic req_d_cache, req_i_cache;


logic prediction_result, prediction_valid, request_prediction, prediction;
logic [31:0] req_pc,prediction_pc;


if_id_t if_id_reg, if_id_reg_next;
id_dis_t id_dis_reg, id_dis_reg_next;
dis_ex_t dis_ex_reg,dis_ex_reg_next;

always_ff @(posedge clk) begin
    if (rst || branch_mispredicted) begin
        // Reset pipeline registers on reset
        if_id_reg <= '0;
        id_dis_reg <= '0;
        dis_ex_reg <= '0;
    end 
    else if(rs_stall) begin
        if (regf_we[1] && dis_ex_reg.Qj == rob_tag1 && dis_ex_reg.rs1_rdy == '0) begin
            dis_ex_reg.rs1_data <= rd_v;  
            dis_ex_reg.rs1_rdy <= 1;    
            dis_ex_reg.Qj <= 0;                
        end
        if (regf_we[1] && dis_ex_reg.Qk == rob_tag1 && dis_ex_reg.rs2_rdy == '0) begin
            dis_ex_reg.rs2_data <= rd_v;  
            dis_ex_reg.rs2_rdy <= 1;    
            dis_ex_reg.Qk <= 0;                
        end
    end
    else if(rob_stall )begin
        dis_ex_reg <= dis_ex_reg_next;
    end
    else begin
        // Update pipeline registers with next stage's data on each clock cycle
        if_id_reg <= if_id_reg_next;
        id_dis_reg <= id_dis_reg_next;
        dis_ex_reg <= dis_ex_reg_next;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        imem_addr <= 32'h60000000; 
        pc_next <= 32'h60000004; 
    end 
    else if (branch_mispredicted) begin
        if(imem_resp)begin
            imem_addr <= rob_entry_out.next_pc; 
            pc_next <= rob_entry_out.next_pc + 4;
        end
        else begin
            pc_next <= rob_entry_out.next_pc;
        end
    end
    else if (jalr_pc != '0) begin
        if(imem_resp)begin
            imem_addr <= jalr_pc; 
            pc_next <= jalr_pc + 4;
        end
        else begin
            pc_next <= jalr_pc;
        end
    end
        
    else if (jump && !stall) begin
        if(imem_resp)begin
            imem_addr <= jal_pc; 
            pc_next <= jal_pc + 4;
        end
        else begin
            pc_next <= jal_pc;
        end
    end
    else if(full) begin

    end
    else if(imem_resp) begin
        imem_addr <= pc_next; 
        pc_next <= pc_next + 4;
    end
    
end


always_comb begin
    imem_rmask = '1;
    req_d_cache = d_read || d_write;
    req_i_cache = i_read;
end

always_comb begin
    flush_ins = '0;
    branch_mispredicted = rob_entry_out.branch_mispredicted;
    br_pc = rob_entry_out.next_pc;
    if(jump || branch_mispredicted)begin
        flush_ins = 1'b1;
    end
end

always_comb begin
    enqueue_wdata = '0;
    enqueue = '0;
    dequeue = '0;
    enqueue_pc = '0;
    if(imem_resp && !full && !jal_stall && !jalr_stall && !bp_stall)begin
        enqueue_wdata = imem_rdata;
        enqueue = 1'b1;
        enqueue_pc = imem_addr;
    end 

    if(!empty && !rob_stall && !rs_stall && !stall && !jalr_stall  && !flush_ins && !branch_mispredicted)begin
        dequeue = 1'b1;
    end 
end

always_comb begin
    if_id_reg_next.inst = 32'b0; // Default to a NOP or invalid instruction
    if_id_reg_next.pc = imem_addr; // Keep tracking the PC value
    if_id_reg_next.next_pc = pc_next; 
    if_id_reg_next.valid = 1'b0; // Assume instruction is not valid by default
    if_id_reg_next.order = order; // Keep the current order, but it will be valid only if there's a new instruction
    if (dequeue) begin
      if_id_reg_next.inst = dequeue_rdata; // Fetch instruction from instruction memory
      if_id_reg_next.pc = dequeue_pc; // Include the current PC value if you're tracking it
      if_id_reg_next.next_pc = dequeue_pc + 4; 
      if_id_reg_next.valid = 1'b1;
    end
end



always_ff @(posedge clk) begin
    if (rst) begin
        order <= 64'd0; // Reset order on reset
    end 
    else if(branch_mispredicted) begin
        order <= rob_entry_out.order + 64'd1;
    end
    else if (dequeue) begin
        order <= order + 64'd1; 
    end
    
end


always_ff @(posedge clk) begin
    if (rst || branch_mispredicted) begin
        jal_stall <= 1'b0; // Reset order on reset
    end 
    else if (jump && ! stall && !imem_resp) begin
        jal_stall <= 1'b1; 
    end
    else if (imem_resp)begin
        jal_stall <= 1'b0; 
    end
end

always_ff @(posedge clk) begin
    if (rst || branch_mispredicted) begin
        jalr_stall <= 1'b0; // Reset order on reset
        jalr_pc2 <= '0;
    end 
    else if (stall) begin
        jalr_stall <= 1'b1; 
    end
    else if (jalr_pc != '0)begin
        if(imem_resp)        jalr_stall <= 1'b0; 
        else jalr_pc2 <= jalr_pc;
    end
    else if(imem_resp && pc_next == jalr_pc2)begin
        jalr_stall <= 1'b0; 
        jalr_pc2 <= '0;
    end
end
always_ff @(posedge clk) begin
    if (rst) begin
        bp_stall <= 1'b0; // Reset order on reset
    end 
    else if (branch_mispredicted && !imem_resp) begin
        bp_stall <= 1'b1; 
    end
    else if (imem_resp)begin
        bp_stall <= 1'b0; 
    end
end

always_comb begin
    rs1_s = rs1;
    rs2_s = rs2;
    if(rob_stall || rs_stall )begin
        rs1_s = id_dis_reg.rs1;
        rs2_s = id_dis_reg.rs2;
    end
    
end

 queue #(
        .width(32),  
        .depth(64)
 ) InstrQueue (
        .rst(rst),
        .flush_ins(flush_ins),
        .clk(clk),
        .enqueue(enqueue),
        .enqueue_wdata(enqueue_wdata),
        .dequeue(dequeue),
        .full(full),
        .empty(empty),
        .dequeue_rdata(dequeue_rdata)
    );

queue #(
        .width(32), 
        .depth(64)
 ) PcQueue (
        .rst(rst),
        .flush_ins(flush_ins),
        .clk(clk),
        .enqueue(enqueue),
        .enqueue_wdata(enqueue_pc),
        .dequeue(dequeue),
        .dequeue_rdata(dequeue_pc)
    );

id_stage id_stage_i (
    .if_id_reg(if_id_reg),
    .id_dis_reg_next(id_dis_reg_next),
    .rs1(rs1),
    .rs2(rs2),
    .jump(jump),
    .stall(stall),
    .jal_pc(jal_pc),
    .request_prediction(request_prediction),              
    .req_pc(req_pc), 
    .prediction(prediction),
    .rob_stall(rob_stall),
    // .reg_full(reg_full),
    .rs_stall(rs_stall) 
);

dis_stage dis_stage_i (
    .id_dis_reg(id_dis_reg),
    .rob_flag_1(rob_flag_1),
    .rob_flag_2(rob_flag_2),
    .add_full(add_full),
    .mul_full(mul_full),
    .rob_full(rob_full),
    .lsq_full(lsq_full),
    .control_full(control_full),
    // .reg_full(reg_full),  
    .rs1_v(rs1_v),
    .rs2_v(rs2_v),
    .rob_num(rob_tag2),
    .enqueue_rob(enqueue_rob),
    .dis_ex_reg_next(dis_ex_reg_next),
    .rob_stall(rob_stall),
    .rs_stall(rs_stall),
    .cdb_tag1(rob_tag1),
    .cdb_result1(rd_v),
    .update_rob(regf_we[1])
);

rs_add rs_add_i (
    .clk(clk),
    .rst(rst),
    .branch_mispredicted(branch_mispredicted),
    .update_rob(regf_we[1]),
    .update_mul(update_mul),
    .update_lsq(lsq_valid),
    .update_bp(bp_valid),
    .cdb_tag1(rob_tag1),
    .cdb_tag2(update_mul_index),
    .cdb_tag3(lsq_rob_tag),
    .cdb_tag4(bp_rob_tag),
    .cdb_result1(rd_v),
    .cdb_result2(update_mul_value),
    .cdb_result3(lsq_data),
    .cdb_result4(bp_data),
    .dis_ex_reg(dis_ex_reg),
    .add_rdy(update_alu),
    .add_full(add_full),
    .rob_num_add(update_alu_index),
    .result_add(update_alu_value),
    .rs1a(rs1a),
    .rs2a(rs2a)
    // .mis_tag_start(mis_tag_start),
    // .mis_tag_end(mis_tag_end)
);

rs_mul rs_mul_i (
    .clk(clk),
    .rst(rst),
    .branch_mispredicted(branch_mispredicted),
    .update_rob(regf_we[1]),
    .update_add(update_alu),
    .update_lsq(lsq_valid),
    .update_bp(bp_valid),
    .cdb_tag1(rob_tag1),
    .cdb_tag2(update_alu_index),
    .cdb_tag3(lsq_rob_tag),
    .cdb_tag4(bp_rob_tag),
    .cdb_result1(rd_v),
    .cdb_result2(update_alu_value),
    .cdb_result3(lsq_data),
    .cdb_result4(bp_data),
    .dis_ex_reg(dis_ex_reg),
    .mul_rdy(update_mul),
    .mul_full(mul_full),
    .rob_num_mul(update_mul_index),
    .result_mul(update_mul_value),
    .rs1m(rs1m),
    .rs2m(rs2m)
    // .mis_tag_start(mis_tag_start),
    // .mis_tag_end(mis_tag_end)
);



regfile rf(
    .clk(clk),
    .rst(rst),
    .branch_mispredicted(branch_mispredicted),
    .regf_we(regf_we),  //1:commit 0: new tag
    .rd_v(rd_v),
    .rs1_s(rs1_s),
    .rs2_s(rs2_s),
    .rd_s1(rd_s1),
    .rd_s2(rd_s2), 
    .rs1_v(rs1_v),
    .rs2_v(rs2_v),
    .rob_tag1(rob_tag1),  // commit tag
    .rob_tag2(rob_tag2),  // new tag
    .rob_flag_1(rob_flag_1), 
    .rob_flag_2(rob_flag_2)
    // .mis_tag_start(mis_tag_start),
    // .mis_tag_end(mis_tag_end),
    // .reg_full(reg_full)  
);



rob rob_inst (
    .rst(rst),
    .clk(clk),
    .branch_mispredicted(branch_mispredicted),
    .enqueue(enqueue_rob),
    .id_dis_reg_in(id_dis_reg),
    .update_alu(update_alu),
    .update_alu_value(update_alu_value),
    .update_alu_index(update_alu_index),
    .update_mul(update_mul),
    .update_mul_value(update_mul_value),
    .update_mul_index(update_mul_index),
    .full(rob_full),
    .regf_we(regf_we),
    .rd_s1(rd_s1),
    .rd_s2(rd_s2),
    .rd_v(rd_v),
    .rob_entry_out(rob_entry_out),
    .rob_tag1(rob_tag1),  //commit rob tag
    .rob_tag2(rob_tag2),
    .rs1a(rs1a),
    .rs2a(rs2a),
    .rs1m(rs1m),
    .rs2m(rs2m),
    .lsq_valid(lsq_valid),
    .lsq_rob_tag(lsq_rob_tag),
    .lsq_rs1(lsq_rs1),
    .lsq_rs2(lsq_rs2),
    .lsq_data(lsq_data),
    .lsq_mem_wdata(lsq_mem_wdata),
    .lsq_mem_rdata(lsq_mem_rdata),
    .lsq_mem_addr(lsq_mem_addr),
    .lsq_mem_rmask(lsq_mem_rmask),
    .lsq_mem_wmask(lsq_mem_wmask),
    .bp_valid(bp_valid),
    .bp_mispredict(bp_mispredict),
    .bp_pc(bp_pc),
    .bp_data(bp_data),
    .bp_rob_tag(bp_rob_tag),
    .bp_rs1(bp_rs1), 
    .bp_rs2(bp_rs2)
    // .mis_tag_start(mis_tag_start),
    // .mis_tag_end(mis_tag_end),
    // .bp_order(bp_order)
);

control_buffer control_buffer_inst (
    .clk(clk),
    .rst(rst),
    .branch_mispredicted(branch_mispredicted),
    .dis_ex_reg(dis_ex_reg),
    .cdb_tag1(update_alu_index),
    .cdb_tag2(update_mul_index),
    .cdb_tag3(rob_tag1),
    .cdb_tag4(lsq_rob_tag),
    .cdb_result1(update_alu_value),
    .cdb_result2(update_mul_value),
    .cdb_result3(rd_v),
    .cdb_result4(lsq_data),
    .update_add(update_alu), 
    .update_mul(update_mul),
    .update_rob(regf_we[1]),
    .update_lsq(lsq_valid),
    .bp_valid(bp_valid),
    .bp_rob_tag(bp_rob_tag),
    .bp_rs1(bp_rs1), 
    .bp_rs2(bp_rs2), 
    .bp_data(bp_data),
    .control_full(control_full),
    .bp_mispredict(bp_mispredict),
    .jalr_pc(jalr_pc),
    .bp_pc(bp_pc),
    // .mis_tag_start(mis_tag_start),
    // .mis_tag_end(mis_tag_end),
    .prediction_result(prediction_result), 
    .prediction_valid(prediction_valid), 
    .prediction_pc(prediction_pc) 
);



lsq lsq_inst (
    .rst(rst),
    .clk(clk),
    .branch_mispredicted(branch_mispredicted),
    .dis_ex_reg(dis_ex_reg),
    .lsq_full(lsq_full),
    .mem_read(mem_read),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_ready(mem_ready),
    .mem_rmask(mem_rmask),
    .mem_wmask(mem_wmask),
    .cdb_tag1(update_alu_index),
    .cdb_tag2(update_mul_index),
    .cdb_tag3(rob_tag1),
    .cdb_tag4(bp_rob_tag),
    .cdb_result1(update_alu_value),
    .cdb_result2(update_mul_value),
    .cdb_result3(rd_v),
    .cdb_result4(bp_data),
    .update_add(update_alu),
    .update_mul(update_mul),
    .update_rob(regf_we[1]),
    .update_bp(bp_valid),
    .lsq_valid(lsq_valid),
    .lsq_rob_tag(lsq_rob_tag),
    .lsq_rs1(lsq_rs1),
    .lsq_rs2(lsq_rs2),
    .lsq_data(lsq_data),
    .lsq_mem_rdata(lsq_mem_rdata),
    .lsq_mem_wdata(lsq_mem_wdata),
    .lsq_mem_addr(lsq_mem_addr),
    .lsq_mem_rmask(lsq_mem_rmask),
    .lsq_mem_wmask(lsq_mem_wmask),
    .forward(forward),
    .mem_free(mem_free),
    .store_buf(store_buf),
    .read_store_buf(read_store_buf),
    .fwd_data(fwd_data),
    .fwd_mask(fwd_mask)
    // .mis_tag_start(mis_tag_start),
    // .mis_tag_end(mis_tag_end)
);

memory_unit memory_unit_inst (
    .rst(rst),
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_addr(mem_addr),
    .mem_rmask(mem_rmask),
    .mem_rdata(mem_rdata),
    .mem_ready(mem_ready),
    .dmem_addr(dmem_addr),
    .dmem_rmask(dmem_rmask),
    .dmem_wmask(dmem_wmask),
    .dmem_rdata(dmem_rdata),
    .dmem_wdata(dmem_wdata),
    .dmem_resp(dmem_resp),
    .sb_wdata(sb_wdata),
    .sb_addr(sb_addr),
    .sb_wmask(sb_wmask),
    .mem_free(mem_free)
);
store_buffer sb_inst(
    .rst(rst),
    .clk(clk),
    .addr(lsq_mem_addr),
    .mem_wdata(lsq_mem_wdata),
    .mem_wmask(lsq_mem_wmask),
    .rob_tag(lsq_rob_tag),
    .sb_enqueue(store_buf),
    .rob_entry_out(rob_entry_out),
    .load_addr(mem_addr),
    .branch_mispredicted(branch_mispredicted),

    .forwarding_data(fwd_data),
    .load_forwarding(read_store_buf),
    .forwarding_succeed(forward),
    .forwarding_wmask(fwd_mask),
    .deq_wdata(sb_wdata),
    .deq_addr(sb_addr),
    .deq_wmask(sb_wmask),
    .mem_write(mem_write)
    // .mis_tag_start(mis_tag_start),
    // .mis_tag_end(mis_tag_end)
);
cache_line_adaptor adp(
    .rst(rst),
    .clk(clk),
    .data_in(bmem_rdata),       
    .read_addr(bmem_raddr),     // Address of the incoming data
    .data_valid(bmem_rvalid),           // Data valid signal from memory
    .data_out(data_out),    // Output data to cache
    .data_out_addr(data_out_addr),// Address for the output data
    .data_out_valid(data_out_valid)       // Data out valid signal to cache
);

arbiter abt(
    .rst(rst),
    .clk(clk),
    .req_i_cache(req_i_cache),         // Request from I-cache
    .addr_i_cache(i_addr), // Address from I-cache
    .req_d_cache(req_d_cache),         // Request from D-cache
    .addr_d_cache(d_addr), // Address from D-cache
    .raddr(data_out_addr),        // Read address from memory
    .data_valid(data_out_valid),              // Read valid from memory
    .mem_ready(bmem_ready),           // Memory ready to take more requests
    .data_in(data_out),
    .i_data_out(i_rdata),
    .d_data_out(d_rdata),
    .i_resp(i_resp),
    .d_resp(d_resp),
    .bmem_addr(bmem_addr),
    .bmem_read(bmem_read),
    .bmem_write(bmem_write),
    .bmem_wdata(bmem_wdata),
    .d_wdata(d_wdata),
    .d_write(d_write)    
);
cache i_cache(
    .rst(rst),
    .clk(clk),
    .ufp_addr(imem_addr),
    .ufp_rmask(imem_rmask),
    .ufp_wmask('0),
    .ufp_rdata(imem_rdata),
    .ufp_wdata('0),
    .ufp_resp(imem_resp),

    .dfp_addr(i_addr),
    .dfp_read(i_read),
    .dfp_rdata(i_rdata),
    .dfp_resp(i_resp)
);

cache d_cache(
    .rst(rst),
    .clk(clk),
    .ufp_addr(dmem_addr),
    .ufp_rmask(dmem_rmask),
    .ufp_wmask(dmem_wmask),
    .ufp_rdata(dmem_rdata),
    .ufp_wdata(dmem_wdata),
    .ufp_resp(dmem_resp),

    .dfp_addr(d_addr),
    .dfp_read(d_read),
    .dfp_write(d_write),
    .dfp_rdata(d_rdata),
    .dfp_wdata(d_wdata),
    .dfp_resp(d_resp)
);

gshare_branch_predictor gpd(
    .rst(rst),
    .clk(clk),
    .prediction_result(prediction_result), 
    .prediction_valid(prediction_valid), 
    .request_prediction(request_prediction),              
    // .pc(req_pc), 
    // .prediction_pc(prediction_pc),          
    .prediction(prediction)                   
);


endmodule : cpu
