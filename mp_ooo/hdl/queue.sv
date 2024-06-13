module queue
#(
    parameter width = 32,
    parameter depth = 16,
    parameter ptr_len = $clog2(depth) + 1
)
(
    input logic rst,flush_ins,
    input logic clk,
    input logic enqueue,
    input logic [width-1 : 0] enqueue_wdata,
    input logic dequeue,
    output logic full,
    output logic empty,
    output logic [width-1 : 0] dequeue_rdata
);

    logic [width-1 : 0] entries [depth];

    logic [ptr_len-1 : 0] head_ptr;
    logic [ptr_len-1 : 0] tail_ptr;

    assign full = ((head_ptr[ptr_len-2:0] == tail_ptr[ptr_len-2:0]) && (head_ptr[ptr_len-1] != tail_ptr[ptr_len-1]));

    assign empty = ((head_ptr[ptr_len-2:0] == tail_ptr[ptr_len-2:0]) && (head_ptr[ptr_len-1] == tail_ptr[ptr_len-1]));

    always_ff @( posedge clk ) begin
        if(rst || flush_ins)begin
            head_ptr <= '0;
            tail_ptr <= '0;
        end

        else begin
            if(enqueue && !full) begin
                entries[tail_ptr[ptr_len-2 : 0]] <= enqueue_wdata;
                tail_ptr <= tail_ptr + 1'b1;
            end

            if(dequeue && !empty) begin
                head_ptr <= head_ptr + 1'b1;
            end
        end
    end

    always_comb begin
        dequeue_rdata = '0;
        if(dequeue && !empty) begin
            dequeue_rdata = entries[head_ptr[ptr_len-2 : 0]];
        end
    end

endmodule : queue