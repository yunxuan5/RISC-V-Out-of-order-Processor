module rs_mul 
import rv32i_types::*;
#(
    parameter int RS_COUNT = 8,  // Number of reservation stations
    parameter ROB_DEPTH = 32,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1
)(
    input logic clk,
    input logic rst,branch_mispredicted,
    input logic [TAG_LEN:0] cdb_tag1,cdb_tag2, cdb_tag3,cdb_tag4,//cdb1 rob cdb2 add lsq bp
    input logic [31:0] cdb_result1,cdb_result2,cdb_result3,cdb_result4,
    input logic update_add,update_rob,update_lsq,update_bp,
    // Additional inputs/outputs for managing reservation stations could be added here
    input dis_ex_t                   dis_ex_reg,


    // Outputs for monitoring, debugging, or further processing
    output logic mul_rdy,mul_full,
    output logic [TAG_LEN:0] rob_num_mul,
    output  logic [31:0] rs1m,rs2m,
    output logic [31:0] result_mul
);



// Array of reservation stations
reservation_station_t rs[RS_COUNT];
logic start[RS_COUNT];
logic done[RS_COUNT];
logic divider_start[RS_COUNT];
logic [31:0] quotient[RS_COUNT];
logic [31:0] remainder[RS_COUNT];
logic divide_by_0[RS_COUNT];
logic divide_done[RS_COUNT];
logic div_hold[RS_COUNT];

logic [31:0] a[RS_COUNT];
logic [31:0] b[RS_COUNT];

logic [1:0] mul_type[RS_COUNT];
logic bp_mis[RS_COUNT];
logic [63:0] p[RS_COUNT];



// Logic to manage reservation stations, such as allocation and release
always_ff @(posedge clk) begin
    if (rst||branch_mispredicted) begin
        for (int i = 0; i < RS_COUNT; i++) begin
            rs[i] <= '0;
            // Initialize other fields as necessary
        end
    end
    else begin
        // Example logic to process reservation station entries
        for (int i = 0; i < RS_COUNT; i++) begin
            if (rs[i].busy) begin
                if (!rs[i].op1_ready && mul_rdy && rs[i].Qj == rob_num_mul) begin
                    rs[i].Vj <= result_mul;  
                    rs[i].op1_ready <= 1;    
                    rs[i].Qj <= 0;                
                end
                if (!rs[i].op1_ready && update_rob && rs[i].Qj == cdb_tag1) begin
                    rs[i].Vj <= cdb_result1;  
                    rs[i].op1_ready <= 1;    
                    rs[i].Qj <= 0;                
                end
                if (!rs[i].op1_ready && update_add && rs[i].Qj == cdb_tag2) begin
                    rs[i].Vj <= cdb_result2;  
                    rs[i].op1_ready <= 1;    
                    rs[i].Qj <= 0;                
                end
                if (!rs[i].op1_ready && update_lsq && rs[i].Qj == cdb_tag3) begin
                    rs[i].Vj <= cdb_result3;  
                    rs[i].op1_ready <= 1;    
                    rs[i].Qj <= 0;                
                end
                if (!rs[i].op1_ready && update_bp && rs[i].Qj == cdb_tag4) begin
                    rs[i].Vj <= cdb_result4;  
                    rs[i].op1_ready <= 1;    
                    rs[i].Qj <= 0;                
                end
                // Similarly, check and update for Qk
                if (!rs[i].op2_ready && mul_rdy  && rs[i].Qk == rob_num_mul) begin
                    rs[i].Vk <= result_mul;
                    rs[i].op2_ready <= 1;
                    rs[i].Qk <= 0;                
                end
                if (!rs[i].op2_ready && update_rob && rs[i].Qk == cdb_tag1) begin
                    rs[i].Vk <= cdb_result1;
                    rs[i].op2_ready <= 1;
                    rs[i].Qk <= 0;                
                end
                if (!rs[i].op2_ready && update_add && rs[i].Qk == cdb_tag2) begin
                    rs[i].Vk <= cdb_result2;
                    rs[i].op2_ready <= 1;
                    rs[i].Qk <= 0;                
                end
                if (!rs[i].op2_ready && update_lsq && rs[i].Qk == cdb_tag3) begin
                    rs[i].Vk <= cdb_result3;
                    rs[i].op2_ready <= 1;
                    rs[i].Qk <= 0;                
                end
                if (!rs[i].op2_ready && update_bp && rs[i].Qk == cdb_tag4) begin
                    rs[i].Vk <= cdb_result4;
                    rs[i].op2_ready <= 1;
                    rs[i].Qk <= 0;                
                end
            end
        end

        if (!branch_mispredicted && dis_ex_reg.valid && dis_ex_reg.rs_type == 2'b01) begin
            for (int i = 0; i < RS_COUNT; i++) begin
                if (!rs[i].busy) begin
                    rs[i].busy <= 1'b1;
                    if(!dis_ex_reg.rs1_rdy)begin
                        if (mul_rdy && dis_ex_reg.Qj == rob_num_mul) begin
                            rs[i].Vj <= result_mul;  
                            rs[i].op1_ready <= 1;    
                            rs[i].Qj <= 0;                
                        end
                        else if (update_rob && dis_ex_reg.Qj == cdb_tag1) begin
                            rs[i].Vj <= cdb_result1;  
                            rs[i].op1_ready <= 1;    
                            rs[i].Qj <= 0;                
                        end
                        else if (update_add && dis_ex_reg.Qj == cdb_tag2) begin
                            rs[i].Vj <= cdb_result2;  
                            rs[i].op1_ready <= 1;    
                            rs[i].Qj <= 0;                
                        end
                        else if (update_lsq && dis_ex_reg.Qj == cdb_tag3) begin
                            rs[i].Vj <= cdb_result3;  
                            rs[i].op1_ready <= 1;    
                            rs[i].Qj <= 0;                
                        end
                        else if (update_bp && dis_ex_reg.Qj == cdb_tag4) begin
                            rs[i].Vj <= cdb_result4;  
                            rs[i].op1_ready <= 1;    
                            rs[i].Qj <= 0;                
                        end
                        else begin
                            rs[i].Qj <= dis_ex_reg.Qj;
                            rs[i].op1_ready <= dis_ex_reg.rs1_rdy;
                            rs[i].Vj <= dis_ex_reg.rs1_data;
                        end
                    end
                    else begin
                        rs[i].Qj <= dis_ex_reg.Qj;
                        rs[i].op1_ready <= dis_ex_reg.rs1_rdy;
                        rs[i].Vj <= dis_ex_reg.rs1_data;
                    end

                    if(!dis_ex_reg.rs2_rdy)begin
                        if (mul_rdy  && dis_ex_reg.Qk == rob_num_mul) begin
                            rs[i].Vk <= result_mul;
                            rs[i].op2_ready <= 1;
                            rs[i].Qk <= 0;                
                        end
                        else if (update_rob && dis_ex_reg.Qk == cdb_tag1) begin
                            rs[i].Vk <= cdb_result1;
                            rs[i].op2_ready <= 1;
                            rs[i].Qk <= 0;                
                        end
                        else if (update_add && dis_ex_reg.Qk == cdb_tag2) begin
                            rs[i].Vk <= cdb_result2;
                            rs[i].op2_ready <= 1;
                            rs[i].Qk <= 0;                
                        end
                        else if (update_lsq && dis_ex_reg.Qk == cdb_tag3) begin
                            rs[i].Vk <= cdb_result3;
                            rs[i].op2_ready <= 1;
                            rs[i].Qk <= 0;                
                        end
                        else if (update_bp && dis_ex_reg.Qk == cdb_tag4) begin
                            rs[i].Vk <= cdb_result4;
                            rs[i].op2_ready <= 1;
                            rs[i].Qk <= 0;                
                        end
                        else begin
                            rs[i].Qk <= dis_ex_reg.Qk;
                            rs[i].Vk <= dis_ex_reg.rs2_data;
                            rs[i].op2_ready <= dis_ex_reg.rs2_rdy;
                        end
                    end
                    else begin
                        rs[i].Qk <= dis_ex_reg.Qk;
                        rs[i].Vk <= dis_ex_reg.rs2_data;
                        rs[i].op2_ready <= dis_ex_reg.rs2_rdy;
                    end

                    rs[i].aluop <= dis_ex_reg.aluop;
                    rs[i].rob_num <= dis_ex_reg.rob_num;
                    rs[i].cmp <= dis_ex_reg.cmp;
                    break;
                end
            end
        end

        for (int i = 0; i < RS_COUNT; i++) begin
            if (rs[i].busy && (done[i] || divide_done[i]))begin
                rs[i]<= '0;
                break;
            end
        end

        // if(branch_mispredicted)begin
        //     for (int i = 0; i < RS_COUNT; i++) begin
        //         if (rs[i].busy)begin
        //             if(mis_tag_start<=mis_tag_end)begin
        //                 if(rs[i].rob_num>=mis_tag_start && rs[i].rob_num<=mis_tag_end)rs[i]<= '0;
        //             end
        //             else begin
        //                 if(rs[i].rob_num>=mis_tag_start || rs[i].rob_num<=mis_tag_end)rs[i]<= '0;
        //             end
        //         end
        //     end
        // end

    end

end

always_comb begin
    result_mul = '0;
    rob_num_mul = '0;
    mul_rdy = '0;
    mul_full = 1'b0;
    rs1m = '0;
    rs2m = '0;

    for (int i = 0; i < RS_COUNT; i++) begin
        a[i] = '0;
        b[i] = '0;
        bp_mis[i] = '0;
        mul_type[i] = '0;
        start[i] = '0;
        divider_start[i] = '0;
        div_hold[i] = '0;
    end

    if (dis_ex_reg.valid && dis_ex_reg.rs_type == 2'b01) begin
        mul_full = 1'b1;
        for (int i = 0; i < RS_COUNT; i++) begin
            if (!rs[i].busy)mul_full = '0;
        end
    end

    for (int i = 0; i < RS_COUNT; i++) begin
        if (rs[i].busy && rs[i].op1_ready && rs[i].op2_ready) begin
            if((rs[i].aluop == alu_div || rs[i].aluop == alu_divu || rs[i].aluop == alu_rem || rs[i].aluop == alu_remu)) begin
                divider_start[i] = 1'b1;
                start[i] = '0;
            end
            else begin
                div_hold[i] = 1'b1;
                start[i] = '1;
            end
            a[i] = rs[i].Vj;
            b[i] = rs[i].Vk; 

            case(rs[i].aluop)
                alu_mul:  mul_type[i] = 2'b01;  // Multiply signed-signed
                alu_mulh:  mul_type[i] = 2'b01;   // Multiply high signed-signed
                alu_mulhsu:mul_type[i] = 2'b10;   // Multiply high signed-unsigned
                alu_mulhu: mul_type[i] = 2'b00;   // Multiply high unsigned-unsigned
                default : mul_type[i] = 2'b00; 
            endcase
        end
    end

    for (int i = 0; i < RS_COUNT; i++) begin
        if (rs[i].busy) begin
            case(rs[i].aluop)
                alu_mul, alu_mulh, alu_mulhsu, alu_mulhu: begin
                    if(done[i]) begin
                        mul_rdy = 1'b1;
                        rob_num_mul = rs[i].rob_num;
                        rs1m = rs[i].Vj;
                        rs2m = rs[i].Vk;
                        case(rs[i].aluop)
                            alu_mul:  result_mul = p[i][31:0];   // Multiply signed-signed
                            alu_mulh:  result_mul = p[i][63:32];    // Multiply high signed-signed
                            alu_mulhsu:result_mul = p[i][63:32];    // Multiply high signed-unsigned
                            alu_mulhu: result_mul = p[i][63:32];    // Multiply high unsigned-unsigned
                        endcase
                        break;
                    end
                end

                alu_div, alu_divu, alu_rem, alu_remu: begin
                    if(divide_done[i]) begin

                        mul_rdy = 1'b1;
                        rob_num_mul = rs[i].rob_num;
                        rs1m = rs[i].Vj;
                        rs2m = rs[i].Vk;
                        case(rs[i].aluop)
                            alu_div: result_mul = quotient[i];     // Multiply signed-signed
                            alu_divu: result_mul = quotient[i];    // Multiply high signed-signed
                            alu_rem: result_mul = remainder[i];    // Multiply high signed-unsigned
                            alu_remu: result_mul = remainder[i];   // Multiply high unsigned-unsigned
                        endcase
                        // div_hold = 1'b1;
                        // div_state[i] = DIV_IDLE;
                        break;
                    end
                end
            endcase 
        end
    end

    if(branch_mispredicted)begin
        for (int i = 0; i < RS_COUNT; i++) begin
            if (rs[i].busy)begin
                // if(mis_tag_start<=mis_tag_end)begin
                //     if(rs[i].rob_num>=mis_tag_start && rs[i].rob_num<=mis_tag_end)bp_mis[i] = 1'b1;
                // end
                // else begin
                //     if(rs[i].rob_num>=mis_tag_start || rs[i].rob_num<=mis_tag_end)bp_mis[i] = 1'b1;
                // end
                bp_mis[i] = 1'b1;
            end
        end
    end
    
end


generate for (genvar i = 0; i < RS_COUNT; i++) begin : arrays
        shift_add_multiplier  mul_unit(
            .clk(clk),
            .rst(rst),
            .start(start[i]),  // You will need logic to control the start signal based on RS status
            .mul_type(mul_type[i]),  // Determine based on operation required
            .a(a[i]),  // Connect to operands from RS
            .b(b[i]),
            .p(p[i]),  // Connect to the output handling logic
            .done(done[i]),  // Use this to manage state in RS
            .branch_mispredicted(bp_mis[i])
        );

        DW_div_seq_inst #(
            .inst_a_width(32),
            .inst_b_width(32),
            .inst_tc_mode(0),
            .inst_num_cyc(3),
            .inst_rst_mode(0),
            .inst_input_mode(1),
            .inst_output_mode(1),
            .inst_early_start(0)
        ) div_unit (
            .inst_clk(clk),
            .inst_rst_n(~rst),
            .inst_hold(div_hold[i]), // Connect the inst_hold signal
            .inst_start(divider_start[i]), // Use the divider_start signal from the reservation station
            .inst_a(a[i]),
            .inst_b(b[i]),
            .branch_mispredicted(bp_mis[i]),
            .complete_inst(divide_done[i]), // Connect the complete_inst signal
            .divide_by_0_inst(divide_by_0[i]),
            .quotient_inst(quotient[i]),
            .remainder_inst(remainder[i])
        );
    end endgenerate

endmodule
