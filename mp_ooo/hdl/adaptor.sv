module cache_line_adaptor(
    input logic clk,                  // Clock signal
    input logic rst,                // Reset signal
    input logic [63:0] data_in,       // Data input from memory
    input logic [31:0] read_addr,     // Address of the incoming data
    input logic data_valid,           // Data valid signal from memory
    output logic [255:0] data_out,    // Output data to cache
    output logic [31:0] data_out_addr,// Address for the output data
    output logic data_out_valid       // Data out valid signal to cache
);

    logic [63:0] data_buffer[3:0];    // Buffer to store data bursts
    logic [1:0] burst_count;          // Counter for the number of bursts received

    always_ff @(posedge clk) begin
        if (rst) begin
            burst_count <= '0;
            data_out_valid <= '0;
        end else if (data_valid) begin
            if (burst_count < 4) begin
                data_buffer[burst_count] <= data_in;  // Store incoming data burst
                burst_count <= burst_count + 1'b1;       // Increment burst counter
            end

            if (burst_count == 3) begin  // Last burst received
                data_out <= {data_in, data_buffer[2], data_buffer[1], data_buffer[0]};
                data_out_addr <= read_addr;
                data_out_valid <= 1'b1;
                burst_count <= '0;  // Reset for next cacheline
            end
        end else begin
            data_out_valid <= 1'b0;  // No valid data to output
        end
    end

endmodule
