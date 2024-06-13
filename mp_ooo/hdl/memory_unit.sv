module memory_unit 
import rv32i_types::*;
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 64,
    parameter PTR_LEN = $clog2(DEPTH) + 1
)(

    // LSQ interface
    input logic clk,
    input logic rst,
    input logic mem_read,
    input logic mem_write,
    input logic [ADDR_WIDTH-1:0] mem_addr,
    input logic [3:0] mem_rmask,

    input logic [DATA_WIDTH-1:0] sb_wdata,
    input logic [ADDR_WIDTH-1:0] sb_addr,
    input logic [3:0] sb_wmask,

    output logic [DATA_WIDTH-1:0] mem_rdata,
    output logic mem_ready,mem_free,

    // Data memory interface
    output logic [ADDR_WIDTH-1:0] dmem_addr,
    output logic [3:0] dmem_rmask,
    output logic [3:0] dmem_wmask,
    input logic [DATA_WIDTH-1:0] dmem_rdata,
    output logic [DATA_WIDTH-1:0] dmem_wdata,
    input logic dmem_resp
);

mq_entry_t memory_queue[DEPTH];
logic mq_empty, mq_full;
logic [PTR_LEN-1:0] head_ptr;
logic [PTR_LEN-1:0] tail_ptr;

assign mq_full = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) && (head_ptr[PTR_LEN-1] != tail_ptr[PTR_LEN-1]));

assign mq_empty = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) && (head_ptr[PTR_LEN-1] == tail_ptr[PTR_LEN-1]));

always_ff @( posedge clk ) begin
    if(rst)begin
        head_ptr <= '0;
        tail_ptr <= '0;
        dmem_wmask <= '0;
        for (int i = 0; i < DEPTH; i++) begin
            memory_queue[i] <= '0;
        end
    end

    else begin

        if(mem_write && !mq_full) begin
            memory_queue[tail_ptr[PTR_LEN-2:0]].addr <= sb_addr;
            memory_queue[tail_ptr[PTR_LEN-2:0]].mem_wdata <= sb_wdata;
            memory_queue[tail_ptr[PTR_LEN-2:0]].mem_wmask <= sb_wmask;
            memory_queue[tail_ptr[PTR_LEN-2:0]].valid <= 1'b1;
            tail_ptr <= tail_ptr + 1'b1;
        end

        if(dmem_wmask != '0)begin
            if(dmem_resp) begin
                head_ptr <= head_ptr + 1'b1;
                memory_queue[head_ptr[PTR_LEN-2:0]] <= '0;
                if( head_ptr + 1'b1 != tail_ptr)begin
                    dmem_addr <= memory_queue[(head_ptr + 1'b1)%DEPTH].addr;
                    dmem_wdata <= memory_queue[(head_ptr + 1'b1)%DEPTH].mem_wdata;
                    dmem_wmask <= memory_queue[(head_ptr + 1'b1)%DEPTH].mem_wmask;
                    dmem_rmask <= '0;
                end
                else begin
                    dmem_addr <= '0;
                    dmem_wdata <='0;
                    dmem_wmask <='0;
                    dmem_rmask <= '0;
                end
            end
        end
        else if(dmem_rmask != '0)begin
            if(dmem_resp)begin
                if(!mq_empty)begin
                    dmem_addr <= memory_queue[head_ptr[PTR_LEN-2:0]].addr;
                    dmem_wdata <= memory_queue[head_ptr[PTR_LEN-2:0]].mem_wdata;
                    dmem_wmask <= memory_queue[head_ptr[PTR_LEN-2:0]].mem_wmask;
                    dmem_rmask <= '0;
                end
                else begin
                    dmem_rmask <= '0;
                    dmem_addr <= '0;
                    dmem_wdata <= '0;
                    dmem_wmask <= '0;
                end
            end
        end
        else begin
            if(!mq_empty)begin
                dmem_addr <= memory_queue[head_ptr[PTR_LEN-2:0]].addr;
                dmem_wdata <= memory_queue[head_ptr[PTR_LEN-2:0]].mem_wdata;
                dmem_wmask <= memory_queue[head_ptr[PTR_LEN-2:0]].mem_wmask;
                dmem_rmask <= '0;
            end
            else if(mem_read)begin
                dmem_addr <= mem_addr;
                dmem_wdata <= '0;
                dmem_rmask <= mem_rmask;
                dmem_wmask <= '0;
            end
        end
    end
end

always_ff @( posedge clk ) begin
    if(rst)begin
        mem_free <= 1'b1;
    end
    else begin
        if(dmem_rmask != '0 && dmem_resp && !mq_empty)begin 
            mem_free <= 1'b0;
        end
        if(dmem_rmask == '0 && !mq_empty)begin
            mem_free <= 1'b0;
        end
        if(mq_empty)begin
            mem_free <= 1'b1;
        end
    end
end
// Memory read/write control
// assign dmem_addr = mem_addr;
// assign dmem_rmask = mem_rmask;
// assign mem_free = dmem_wmask == '0;
// assign dmem_wmask = mem_wmask;
// assign dmem_wdata = mem_wdata;

// LSQ interface control
always_comb begin
    mem_rdata = '0;
    mem_ready = 1'b0;

    if (mem_read) begin
        if (dmem_resp) begin
            if(dmem_addr == mem_addr)begin
                mem_rdata = dmem_rdata;
                mem_ready = 1'b1;
            end
        end
    end 
end

endmodule