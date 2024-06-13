module rs_add 
import rv32i_types::*;
#(
    parameter int RS_COUNT = 10,  // Number of reservation stations
    parameter ROB_DEPTH = 32,
    parameter TAG_LEN = $clog2(ROB_DEPTH) - 1
)(
    input logic clk,
    input logic rst,branch_mispredicted,
    input logic [TAG_LEN:0] cdb_tag1,cdb_tag2,cdb_tag3,cdb_tag4, //cdb1 rob cdb2 mul lsq, bp
    input logic [31:0] cdb_result1,cdb_result2,cdb_result3,cdb_result4,
    input logic update_mul,update_rob,update_lsq,update_bp,
    // Additional inputs/outputs for managing reservation stations could be added here
    input dis_ex_t                   dis_ex_reg,


    // Outputs for monitoring, debugging, or further processing
    output logic add_rdy,add_full,
    output logic [TAG_LEN:0] rob_num_add,
    output  logic [31:0] rs1a,rs2a,
    output logic [31:0] result_add
);



// Array of reservation stations
reservation_station_t rs[RS_COUNT];

logic [31:0] a[RS_COUNT];
logic [31:0] b[RS_COUNT];
logic [31:0] f[RS_COUNT];
logic p[RS_COUNT];

logic [4:0] aluop[RS_COUNT];




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
                if (!rs[i].op1_ready && add_rdy && rs[i].Qj == rob_num_add) begin
                    rs[i].Vj <= result_add;  
                    rs[i].op1_ready <= 1;    
                    rs[i].Qj <= 0;                
                end
                if (!rs[i].op1_ready && update_rob && rs[i].Qj == cdb_tag1) begin
                    rs[i].Vj <= cdb_result1;  
                    rs[i].op1_ready <= 1;    
                    rs[i].Qj <= 0;                
                end
                if (!rs[i].op1_ready && update_mul && rs[i].Qj == cdb_tag2) begin
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
                if (!rs[i].op2_ready && add_rdy  && rs[i].Qk == rob_num_add) begin
                    rs[i].Vk <= result_add;
                    rs[i].op2_ready <= 1;
                    rs[i].Qk <= 0;                
                end
                if (!rs[i].op2_ready && update_rob && rs[i].Qk == cdb_tag1) begin
                    rs[i].Vk <= cdb_result1;
                    rs[i].op2_ready <= 1;
                    rs[i].Qk <= 0;                
                end
                if (!rs[i].op2_ready && update_mul && rs[i].Qk == cdb_tag2) begin
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

        if (!branch_mispredicted && dis_ex_reg.valid && dis_ex_reg.rs_type == 2'b00) begin
            for (int i = 0; i < RS_COUNT; i++) begin
                if (!rs[i].busy) begin
                    rs[i].busy <= 1'b1;
                    if(!dis_ex_reg.rs1_rdy)begin
                        if (add_rdy && dis_ex_reg.Qj == rob_num_add) begin
                            rs[i].Vj <= result_add;  
                            rs[i].op1_ready <= 1;    
                            rs[i].Qj <= 0;                
                        end
                        else if (update_rob && dis_ex_reg.Qj == cdb_tag1) begin
                            rs[i].Vj <= cdb_result1;  
                            rs[i].op1_ready <= 1;    
                            rs[i].Qj <= 0;                
                        end
                        else if (update_mul && dis_ex_reg.Qj == cdb_tag2) begin
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
                        if (add_rdy  && dis_ex_reg.Qk == rob_num_add) begin
                            rs[i].Vk <= result_add;
                            rs[i].op2_ready <= 1;
                            rs[i].Qk <= 0;                
                        end
                        else if (update_rob && dis_ex_reg.Qk == cdb_tag1) begin
                            rs[i].Vk <= cdb_result1;
                            rs[i].op2_ready <= 1;
                            rs[i].Qk <= 0;                
                        end
                        else if (update_mul && dis_ex_reg.Qk == cdb_tag2) begin
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
            if (rs[i].busy && rs[i].op1_ready && rs[i].op2_ready)begin
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
    result_add = '0;
    rob_num_add = '0;
    add_rdy = '0;
    add_full = 1'b0;
    rs1a = '0;
    rs2a = '0;
    for (int i = 0; i < RS_COUNT; i++) begin
        a[i] = '0;
        b[i] = '0;
        aluop[i] = '0;
    end

    if (dis_ex_reg.valid && dis_ex_reg.rs_type == 2'b00) begin
        add_full = 1'b1;
        for (int i = 0; i < RS_COUNT; i++) begin
            if (!rs[i].busy)add_full = 1'b0;
        end
    end

    for (int i = 0; i < RS_COUNT; i++) begin
        if (rs[i].busy && rs[i].op1_ready && rs[i].op2_ready) begin

            aluop[i] = {2'b0, rs[i].aluop[2:0]};
            a[i] = rs[i].Vj;
            b[i] = rs[i].Vk; 

            rs1a = rs[i].Vj;
            rs2a = rs[i].Vk;
            add_rdy = 1'b1;
            rob_num_add = rs[i].rob_num;
            result_add = rs[i].cmp? {31'b0, p[i]} : f[i];
            break;
        end
    end
    
end


generate for (genvar i = 0; i < RS_COUNT; i++) begin : arrays
    alu alu_unit (
        .aluop(aluop[i]),
        .a(a[i]),
        .b(b[i]),
        .f(f[i])
    );

    cmp my_comp (
        .a(a[i]),
        .b(b[i]),
        .cmpop(aluop[i][2:0]),
        .br_en(p[i])
    );
    end endgenerate



endmodule
