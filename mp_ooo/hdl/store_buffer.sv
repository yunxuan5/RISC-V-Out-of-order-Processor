module store_buffer
import rv32i_types::*;
#(
    parameter WIDTH = 32,
    parameter DEPTH = 16,
    parameter PTR_LEN = $clog2(DEPTH) + 1,
    parameter ROB_DEPTH = 32,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1
)
(
    input logic rst,
    input logic clk,
    input logic [WIDTH-1:0] addr,
    input logic [WIDTH-1:0] mem_wdata,
    input logic [3:0] mem_wmask,
    input logic [TAG_LEN:0] rob_tag,
    input logic sb_enqueue,
    input rob_entry_t rob_entry_out,
    input logic [31:0]load_addr,
    input logic branch_mispredicted,
    input logic load_forwarding,
    output logic [WIDTH-1:0] forwarding_data,
    output logic forwarding_succeed,
    output logic [3:0] forwarding_wmask,
    output logic [WIDTH-1:0] deq_wdata,
    output logic [WIDTH-1:0] deq_addr,
    output logic [3:0] deq_wmask,
    output logic mem_write
);

    sb_entry_t sb[DEPTH];
    logic sb_full, sb_empty;
    logic [PTR_LEN-1:0] head_ptr;
    logic [PTR_LEN-1:0] tail_ptr;

    assign sb_full = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) && (head_ptr[PTR_LEN-1] != tail_ptr[PTR_LEN-1]));

    assign sb_empty = ((head_ptr[PTR_LEN-2:0] == tail_ptr[PTR_LEN-2:0]) && (head_ptr[PTR_LEN-1] == tail_ptr[PTR_LEN-1]));

    always_ff @( posedge clk ) begin
        if(rst||branch_mispredicted)begin
            head_ptr <= '0;
            tail_ptr <= '0;
            for (int i = 0; i < DEPTH; i++) begin
                sb[i] <= '0;
            end
        end

        else begin
            if(sb_enqueue && !sb_full) begin
                if(!branch_mispredicted)begin
                    sb[tail_ptr[PTR_LEN-2:0]].addr <= addr;
                    sb[tail_ptr[PTR_LEN-2:0]].mem_wdata <= mem_wdata;
                    sb[tail_ptr[PTR_LEN-2:0]].rob_tag <= rob_tag;
                    sb[tail_ptr[PTR_LEN-2:0]].mem_wmask <= mem_wmask;
                    sb[tail_ptr[PTR_LEN-2:0]].valid <= 1'b1;
                    tail_ptr <= tail_ptr + 1'b1;
                end
                // else begin
                //     if(mis_tag_start<=mis_tag_end)begin
                //         if(!(rob_tag>=mis_tag_start && rob_tag<=mis_tag_end))begin
                //             sb[tail_ptr[PTR_LEN-2:0]].addr <= addr;
                //             sb[tail_ptr[PTR_LEN-2:0]].mem_wdata <= mem_wdata;
                //             sb[tail_ptr[PTR_LEN-2:0]].rob_tag <= rob_tag;
                //             sb[tail_ptr[PTR_LEN-2:0]].mem_wmask <= mem_wmask;
                //             sb[tail_ptr[PTR_LEN-2:0]].valid <= 1'b1;
                //             tail_ptr <= tail_ptr + 1'b1;
                //         end
                //     end
                //     else begin
                //         if(!(rob_tag>=mis_tag_start || rob_tag<=mis_tag_end))begin
                //             sb[tail_ptr[PTR_LEN-2:0]].addr <= addr;
                //             sb[tail_ptr[PTR_LEN-2:0]].mem_wdata <= mem_wdata;
                //             sb[tail_ptr[PTR_LEN-2:0]].rob_tag <= rob_tag;
                //             sb[tail_ptr[PTR_LEN-2:0]].mem_wmask <= mem_wmask;
                //             sb[tail_ptr[PTR_LEN-2:0]].valid <= 1'b1;
                //             tail_ptr <= tail_ptr + 1'b1;
                //         end
                //     end
                // end
            end

            if(rob_entry_out.ready && rob_entry_out.rob_tag == sb[head_ptr[PTR_LEN-2:0]].rob_tag && !sb_empty && sb[head_ptr[PTR_LEN-2:0]].valid) begin
                head_ptr <= head_ptr + 1'b1;
                sb[head_ptr[PTR_LEN-2:0]] <= '0;
            end


            // if(branch_mispredicted)begin
            //    for (int j = 0; j < DEPTH; j++) begin
            //         automatic logic[31:0] idx = tail_ptr + unsigned'(DEPTH*2 - 1 - j);
            //         if (idx[PTR_LEN-1:0] == head_ptr) begin
            //             break;
            //         end
            //         if(sb[idx%DEPTH].valid)begin
            //             if(mis_tag_start<=mis_tag_end)begin
            //                 if(sb[idx%DEPTH].rob_tag>=mis_tag_start && sb[idx%DEPTH].rob_tag<=mis_tag_end)begin
            //                     sb[idx%DEPTH]<= '0;
            //                     tail_ptr <= idx[PTR_LEN-1:0];
            //                 end
            //                 else begin
            //                     break;
            //                 end
            //             end
            //             else begin
            //                 if(sb[idx%DEPTH].rob_tag>=mis_tag_start || sb[idx%DEPTH].rob_tag<=mis_tag_end)begin
            //                     sb[idx%DEPTH]<= '0;
            //                     tail_ptr <= idx[PTR_LEN-1:0];
            //                 end
            //                 else begin
            //                     break;
            //                 end
            //             end
            //         end
            //     end
            //     if(!mem_write)begin
            //         if(sb[head_ptr[PTR_LEN-2:0]].valid)begin
            //             if(mis_tag_start<=mis_tag_end)begin
            //                 if(sb[head_ptr[PTR_LEN-2:0]].rob_tag>=mis_tag_start && sb[head_ptr[PTR_LEN-2:0]].rob_tag<=mis_tag_end)begin
            //                     sb[head_ptr[PTR_LEN-2:0]]<= '0;
            //                     tail_ptr <= head_ptr;
            //                 end
            //             end
            //             else begin
            //                 if(sb[head_ptr[PTR_LEN-2:0]].rob_tag>=mis_tag_start || sb[head_ptr[PTR_LEN-2:0]].rob_tag<=mis_tag_end)begin
            //                     sb[head_ptr[PTR_LEN-2:0]]<= '0;
            //                     tail_ptr <= head_ptr;
            //                 end
            //             end
            //         end
            //     end
            // end
        end
    end

    always_comb begin
        deq_wdata = '0;
        deq_addr = '0;
        deq_wmask = '0;
        forwarding_data = '0;
        forwarding_succeed = '0;
        forwarding_wmask = '0;
        mem_write = 1'b0;

        if(load_forwarding) begin
            for (int i = 0; i < DEPTH; i++) begin
                if (sb[i].addr == load_addr) begin
                    for (int j = 0; j < 4; j++) begin // Assuming 32 bits/8 bits per byte = 4
                        if (sb[i].mem_wmask[j]) begin
                            forwarding_data[j*8 +: 8] = sb[i].mem_wdata[j*8 +: 8];
                            forwarding_wmask[j] = 1'b1;
                            forwarding_succeed = 1'b1;
                        end
                    end
                end
            end
        end

        if(rob_entry_out.ready && rob_entry_out.rob_tag == sb[head_ptr[PTR_LEN-2:0]].rob_tag && !sb_empty && sb[head_ptr[PTR_LEN-2:0]].valid) begin
            deq_wdata = sb[head_ptr[PTR_LEN-2:0]].mem_wdata;
            deq_addr = sb[head_ptr[PTR_LEN-2:0]].addr;
            deq_wmask = sb[head_ptr[PTR_LEN-2:0]].mem_wmask;
            mem_write = 1'b1;
        end
    end

endmodule : store_buffer