module DW_div_seq_inst(inst_clk, inst_rst_n, inst_hold, inst_start, inst_a, 
   inst_b, branch_mispredicted, complete_inst, divide_by_0_inst, quotient_inst, remainder_inst);

  parameter inst_a_width = 8; 
  parameter inst_b_width = 8; 
  parameter inst_tc_mode = 0; 
  parameter inst_num_cyc = 3; 
  parameter inst_rst_mode = 0; 
  parameter inst_input_mode = 1; 
  parameter inst_output_mode = 1; 
  parameter inst_early_start = 0; 

  input inst_clk; 
  input inst_rst_n; 
  input inst_hold; 
  input inst_start; 
  input [inst_a_width-1 : 0] inst_a; 
  input [inst_b_width-1 : 0] inst_b; 
  input branch_mispredicted;
  output reg complete_inst; 
  output divide_by_0_inst; 
  output reg [inst_a_width-1 : 0] quotient_inst; 
  output reg [inst_b_width-1 : 0] remainder_inst;

  localparam DIV_IDLE = 2'b00, DIV_START = 2'b01, DIV_RUNNING = 2'b10, DIV_COMPLETE = 2'b11;
  reg [1:0] state;
  reg [1:0] cycle_count;
  wire dw_complete;
  reg [inst_a_width-1:0] dw_quotient;
  reg [inst_b_width-1:0] dw_remainder;
  reg dw_divide_by_0;
  // Instance of DW_div_seq 
  DW_div_seq #(inst_a_width, inst_b_width, inst_tc_mode, inst_num_cyc,
               inst_rst_mode, inst_input_mode, inst_output_mode,
               inst_early_start) 
    U1 (.clk(inst_clk),   .rst_n(inst_rst_n),   .hold(inst_hold), 
        .start(state == DIV_START),   .a(inst_a),   .b(inst_b), 
        .complete(dw_complete),   .divide_by_0(dw_divide_by_0), 
        .quotient(dw_quotient),   .remainder(dw_remainder) );

  always @(posedge inst_clk) begin
        if (!inst_rst_n || branch_mispredicted) begin
            state <= DIV_IDLE;
            complete_inst <= '0;
            quotient_inst <= '0;
            remainder_inst <= '0;
            cycle_count <= '0;
        end else begin
            case (state)
                DIV_IDLE: begin
                    if (inst_start && !inst_hold) begin
                        state <= DIV_START;
                    end
                end
                DIV_START: begin
                    state <= DIV_RUNNING;
                end
                DIV_RUNNING: begin
                    if (dw_complete) begin
                        state <= DIV_COMPLETE;
                        quotient_inst <= dw_quotient;
                        remainder_inst <= dw_remainder;
                        complete_inst <= '1;
                    end else if (inst_hold) begin
                        state <= DIV_IDLE;
                    end
                end
                DIV_COMPLETE: begin
                    if (!inst_start) begin
                        complete_inst <= '0;
                        state <= DIV_IDLE;
                    end
                end
            endcase
        end
    end

    assign divide_by_0_inst = dw_divide_by_0;
endmodule