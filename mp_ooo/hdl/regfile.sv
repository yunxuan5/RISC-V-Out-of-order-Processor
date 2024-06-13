
module regfile import rv32i_types::*;
#(
    parameter DEPTH = 16,
    parameter ROB_DEPTH = 32,
    parameter PTR_LEN = $clog2(DEPTH) + 1,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1
)
(
    input   logic           clk,
    input   logic           rst,branch_mispredicted,
    input   logic    [1:0]       regf_we,
    input   logic   [31:0]  rd_v,
    input   logic   [TAG_LEN:0]  rob_tag1,rob_tag2,
    input   logic   [4:0]   rs1_s, rs2_s, rd_s1,rd_s2,
    output logic rob_flag_1,rob_flag_2,
    output  logic   [31:0]  rs1_v, rs2_v
);
 reg_t data [32];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                data[i].val <= '0;
                data[i].clean <= 1'b1;
                data[i].rob_num <= '0;
            end
        end 
        else if(branch_mispredicted)begin
            for (int i = 0; i < 32; i++) begin
                data[i].clean <= 1'b1;
                data[i].rob_num <= '0;
            end
        end
        else begin
            if (regf_we[1] == 1'b1 && (rd_s1 != 5'd0)) begin
                data[rd_s1].val <= rd_v;
                if(data[rd_s1].rob_num == rob_tag1)data[rd_s1].clean <= 1'b1;
            end
            if (regf_we[0] == 1'b1 && (rd_s2 != 5'd0)) begin
                data[rd_s2].rob_num <= rob_tag2;
                data[rd_s2].clean <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rs1_v <= 'x;
            rs2_v <= 'x;
            rob_flag_1 <= 1'b0;
            rob_flag_2 <= 1'b0;
        end else begin
            if (regf_we[0] == 1'b1 && (rd_s2 != 5'd0)&& rs1_s == rd_s2 ) begin
                rs1_v <= {27'b0, rob_tag2};
                rob_flag_1 <= 1'b1;
            end
            else if(regf_we[1] == 1'b1 && (rd_s1 != 5'd0) && rs1_s == rd_s1 && data[rd_s1].rob_num == rob_tag1)begin
                rs1_v <= rd_v;
                rob_flag_1 <= 1'b0;
            end
            else begin
                rs1_v <= (rs1_s != 5'd0) ? (data[rs1_s].clean? data[rs1_s].val:data[rs1_s].rob_num) : '0;
                rob_flag_1 <= !data[rs1_s].clean;
            end

            if (regf_we[0] == 1'b1 && (rd_s2 != 5'd0)&& rs2_s == rd_s2 ) begin
                rs2_v <= {27'b0, rob_tag2};
                rob_flag_2 <= 1'b1;
            end
            else if(regf_we[1] == 1'b1 && (rd_s1 != 5'd0) && rs2_s == rd_s1 && data[rd_s1].rob_num == rob_tag1)begin
                rs2_v <= rd_v;
                rob_flag_2 <= 1'b0;
            end
            else begin
                rs2_v <= (rs2_s != 5'd0) ? (data[rs2_s].clean? data[rs2_s].val:data[rs2_s].rob_num) : '0;
                rob_flag_2 <= !data[rs2_s].clean;
            end

        end
    end

endmodule : regfile