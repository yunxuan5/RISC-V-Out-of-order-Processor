module gshare_branch_predictor #(
    parameter ADDR_BITS = 10,      // Using 12 bits of the PC for BHT indexing
    parameter HISTORY_BITS = 10    // Matching history size for balanced XOR
)(
    input logic clk,
    input logic rst,
    input logic prediction_result, prediction_valid, request_prediction,                // Actual outcome of the branch
    // input logic [31:0] pc, prediction_pc,                    // Full 32-bit program counter
    output logic prediction                    // Predicted outcome of the branch
);

    // Branch History Table (BHT)
    // logic [1:0] bht[2**ADDR_BITS];             // 2-bit saturating counter for each entry

    // // Global History Register (GHR)
    // logic [HISTORY_BITS-1:0] global_history;

    // // Calculated index for BHT using XOR of relevant PC bits and global history
    // logic [ADDR_BITS-1:0]  bht_index;
    // logic [ADDR_BITS-1:0] prediction_bht_index;

    // // Predict branch outcome based on BHT
    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         // Reset BHT and GHR
    //         global_history <= {HISTORY_BITS{1'b0}};
    //         for (int i = 0; i < 2**ADDR_BITS; i++) begin
    //             bht[i] <= 2'b01;  // Initialize to weakly taken
    //         end
    //     end else begin
    //         if(prediction_valid)begin
    //             if (prediction_result && bht[prediction_bht_index] != 2'b11) begin
    //                 bht[prediction_bht_index] <= bht[prediction_bht_index] + 1'b1;  // Increment counter towards strongly taken
    //             end else if (!prediction_result && bht[prediction_bht_index] != 2'b00) begin
    //                 bht[prediction_bht_index] <= bht[prediction_bht_index] - 1'b1;  // Decrement counter towards strongly not taken
    //             end
    //             global_history <= {global_history[HISTORY_BITS-2:0], prediction_result};  // Update history
    //         end
    //     end
    // end

    // always_comb begin
    //     prediction = '0;
    //     bht_index = (pc[ADDR_BITS+1:2] ^ global_history);
    //     prediction_bht_index = (prediction_pc[ADDR_BITS+1:2] ^ global_history);
    //     if(request_prediction)begin
    //         prediction = bht[bht_index][1];  
    //     end
    // end
    logic [1:0] bht;
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset BHT and GHR
            // global_history <= {HISTORY_BITS{1'b0}};
            // for (int i = 0; i < 2**ADDR_BITS; i++) begin
            bht <= 2'b01;  // Initialize to weakly taken
            // end
        end else begin
            if(prediction_valid)begin
                if (prediction_result && bht != 2'b11) begin
                    bht <= bht + 1'b1;  // Increment counter towards strongly taken
                end else if (!prediction_result && bht != 2'b00) begin
                    bht <= bht- 1'b1;  // Decrement counter towards strongly not taken
                end
                // global_history <= {global_history[HISTORY_BITS-2:0], prediction_result};  // Update history
            end
        end
    end

    always_comb begin
        prediction = '0;
        // bht_index = (pc[ADDR_BITS+1:2] ^ global_history);
        // prediction_bht_index = (prediction_pc[ADDR_BITS+1:2] ^ global_history);
        if(request_prediction)begin
            prediction = bht[1];  
        end
    end



endmodule

