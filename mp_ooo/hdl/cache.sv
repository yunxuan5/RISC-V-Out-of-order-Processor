module cache (
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);
logic [2:0] block_offset;
logic [3:0] set_index;
logic [22:0] tag; 

logic data_we[4];
logic tag_we[4];
logic valid_we[4];

logic [31:0] data_wmask[4]; 

logic [255:0]data_in[4];
logic [255:0]data_out[4];
logic [23:0]tag_in[4];
logic [23:0]tag_out[4];
logic valid_in[4];
logic valid_out[4];


    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (data_we[i]),
            .wmask0     (data_wmask[i]),
            .addr0      (set_index),
            .din0       (data_in[i]),
            .dout0      (data_out[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (tag_we[i]),
            .addr0      (set_index),
            .din0       (tag_in[i]),
            .dout0      (tag_out[i])
        );
        ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (valid_we[i]),
            .addr0      (set_index),
            .din0       (valid_in[i]),
            .dout0      (valid_out[i])
        );
    end endgenerate
    
enum logic [2:0] {
    S_IDLE,
    S_CHECK_TAG,
    S_CHECK_TAG2,
    S_WRITE_ALLOCATION,
    S_UPDATE_CACHE,
    S_WRITE_BACK
} current_state, next_state;

logic cpu_req;
logic [1:0] hit_way,least_way;

logic [31:0] mem_addr;

logic [2:0] plru_bits; 

always_comb begin
    cpu_req = (!rst) && (ufp_rmask != '0 || ufp_wmask != '0);
end

always_ff @(posedge clk) begin
    if (rst) current_state <= S_IDLE;
    else current_state <= next_state;
end

always_ff @(posedge clk) begin
    if (rst) begin
        mem_addr <= '0;
    end
    else begin
        mem_addr <= dfp_addr;
    end
end


always_ff @(posedge clk) begin
    if(rst)begin
        plru_bits <= '0;
    end
    else begin
        if (hit_way == 2'b00) begin
            plru_bits[2] <= 1'b1;
            plru_bits[0] <= 1'b1;
        end 
        else if (hit_way == 2'b01) begin
            plru_bits[2] <= 1'b0;
            plru_bits[0] <= 1'b1;
        end 
        else if (hit_way == 2'b10) begin
            plru_bits[1] <= 1'b1;
            plru_bits[0] <= 1'b0;
        end 
        else if (hit_way == 2'b11) begin
            plru_bits[1] <= 1'b0;
            plru_bits[0] <= 1'b0;
        end
    end
end

always_comb begin
    case(plru_bits)
        3'b101, 3'b111: hit_way = 2'b00;    //D
        3'b001, 3'b011: hit_way = 2'b01;    //C
        3'b010, 3'b110: hit_way = 2'b10;    //B
        3'b000, 3'b100: hit_way = 2'b11;    //A
        default : hit_way = 2'b00;
    endcase
    case(plru_bits)
        3'b000, 3'b010: least_way = 2'b00;    //D
        3'b100, 3'b110: least_way = 2'b01;    //C
        3'b001, 3'b101: least_way = 2'b10;    //B
        3'b011, 3'b111: least_way = 2'b11;    //A
        default : least_way = 2'b00;
    endcase
    ufp_rdata = '0;
    ufp_resp = '0;
    
    dfp_addr = mem_addr;
    dfp_read = '0;
    dfp_write = '0;
    dfp_wdata = '0;

    block_offset = ufp_addr[4:2];
    set_index = ufp_addr[8:5];
    tag = ufp_addr[31:9];  

    for (int i = 0; i < 4; i++) begin
        data_we[i] = 1'b1;
        tag_we[i] = 1'b1;
        valid_we[i] = 1'b1;
        data_in[i] = {{224{1'b0}}, ufp_wdata} << (32 * block_offset); 
        data_wmask[i] = {{28{1'b0}}, ufp_wmask} << (4 * block_offset);
        tag_in[i] = '0;
        valid_in[i] = '0;
    end

    next_state = current_state;
    unique case(current_state)
        S_IDLE: begin
            if (cpu_req)begin
                next_state = S_CHECK_TAG;
            end
        end
        S_CHECK_TAG: begin

            if (valid_out[0] && (tag_out[0][22:0] == tag)) begin
                next_state = S_IDLE;
                ufp_resp = 1'b1;
                hit_way = 2'b00;
                if(ufp_rmask != '0)begin
                    ufp_rdata = data_out[0][32*block_offset+:32];
                end
                if(ufp_wmask != '0) begin
                    data_we[0] = 1'b0;
                    tag_we[0] = 1'b0;
                    tag_in[0] = {1'b1, tag};
                end   
            end
            else if (valid_out[1] && (tag_out[1][22:0] == tag)) begin
                next_state = S_IDLE;
                ufp_resp = 1'b1;
                hit_way = 2'b01;
                if(ufp_rmask != '0)begin
                    ufp_rdata = data_out[1][32*block_offset+:32];
                end
                if(ufp_wmask != '0) begin
                    data_we[1] = 1'b0;
                    tag_we[1] = 1'b0;
                    tag_in[1] = {1'b1, tag};
                end   
            end
            else if (valid_out[2] && (tag_out[2][22:0] == tag)) begin
                next_state = S_IDLE;
                ufp_resp = 1'b1;
                hit_way = 2'b10;
                if(ufp_rmask != '0)begin
                    ufp_rdata = data_out[2][32*block_offset+:32];
                end
                if(ufp_wmask != '0) begin
                    data_we[2] = 1'b0;
                    tag_we[2] = 1'b0;
                    tag_in[2] = {1'b1, tag};
                end   
            end
            else if (valid_out[3] && (tag_out[3][22:0] == tag)) begin
                next_state = S_IDLE;
                ufp_resp = 1'b1;
                hit_way = 2'b11;
                if(ufp_rmask != '0)begin
                    ufp_rdata = data_out[3][32*block_offset+:32];
                end
                if(ufp_wmask != '0) begin
                    data_we[3] = 1'b0;
                    tag_we[3] = 1'b0;
                    tag_in[3] = {1'b1, tag};
                end   
            end

            else begin
                if (!cpu_req)begin
                    next_state = S_IDLE;
                end
                else begin
                    next_state = S_WRITE_ALLOCATION;
                    valid_we[least_way] = 1'b0;
                    valid_in[least_way] = 1'b1;
                    tag_we[least_way] = 1'b0;
                    tag_in[least_way] = {1'b0, tag};
                    if(valid_out[least_way]  && tag_out[least_way][23] == 1'b1)begin //dirty miss
                        next_state = S_WRITE_BACK;
                        dfp_addr = {tag_out[least_way][22:0],set_index,5'b00000};
                    end
                end
                       
            end
        end
        S_WRITE_ALLOCATION: begin
            dfp_addr = {ufp_addr[31:5],5'b00000};
            dfp_read = 1'b1;
            dfp_write = 1'b0;
            if(dfp_resp)begin
                next_state = S_UPDATE_CACHE;
                data_we[least_way] = 1'b0;
                data_in[least_way] = dfp_rdata;
                data_wmask[least_way] = '1;
            end
        end
        S_UPDATE_CACHE: begin
            next_state = S_CHECK_TAG;
        end
        S_WRITE_BACK: begin
            dfp_addr = mem_addr;
            dfp_read = 1'b0;
            dfp_write = 1'b1;
            dfp_wdata = data_out[least_way];
            if(dfp_resp)begin
                next_state = S_WRITE_ALLOCATION;
            end
        end
        default:;
    endcase
end

endmodule
