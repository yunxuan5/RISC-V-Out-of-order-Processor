module arbiter(
    input logic clk,                 // Clock signal
    input logic rst,               // rst signal
    input logic req_i_cache,         // Request from I-cache
    input logic [31:0] addr_i_cache, // Address from I-cache
    input logic req_d_cache,         // Request from D-cache
    input logic [31:0] addr_d_cache, // Address from D-cache
    input logic [31:0] raddr,        // Read address from memory
    input logic data_valid,              // Read valid from memory
    input logic mem_ready,d_write,           // Memory ready to take more requests
    input logic [255:0] data_in,d_wdata,
    output logic               bmem_read,
    output logic               bmem_write,
    output logic   [63:0]      bmem_wdata,
    output logic   [31:0]      bmem_addr,
    output logic [255:0] i_data_out,d_data_out,
    output logic i_resp,d_resp     
);

localparam MAX_REQ = 1;  // Maximum number of pending requests per cache
logic [31:0] i_cache_addrs[MAX_REQ];  // Array for I-cache addresses
logic [31:0] d_cache_addrs[MAX_REQ];  // Array for D-cache addresses
logic [1:0] burst_count;          // Counter for the number of bursts received

    always_comb begin
        i_data_out = '0;
        d_data_out = '0;
        bmem_addr = '0;
        bmem_read = '0;
        bmem_write = '0;
        i_resp = '0;
        d_resp = '0;
        bmem_wdata = '0;
        case (burst_count)
            0: bmem_wdata = d_wdata[63:0];
            1: bmem_wdata = d_wdata[127:64];
            2: bmem_wdata = d_wdata[191:128];
            3: bmem_wdata = d_wdata[255:192];
        endcase
        if(data_valid)begin
            for (int i = 0; i < MAX_REQ; i++) begin
                if(i_cache_addrs[i] == raddr)begin
                    i_data_out = data_in;
                    i_resp = 1'b1;
                    break;
                end
                if(d_cache_addrs[i] == raddr)begin
                    d_data_out = data_in;
                    d_resp = 1'b1;
                    break;
                end
            end
        end
        
        if(mem_ready)begin
            if (burst_count > 0) begin
                bmem_write = 1'b1;
                bmem_addr = addr_d_cache;
                if(burst_count ==3)d_resp = 1'b1;
            end
            else begin
                for (int i = 0; i < MAX_REQ; i++) begin

                    if(req_d_cache && d_cache_addrs[i] == '0)begin
                        bmem_addr = addr_d_cache;
                        if(d_write)bmem_write = 1'b1;
                        else bmem_read = 1'b1;
                        break;
                    end
                    


                    else if(req_i_cache && i_cache_addrs[i] == '0)begin
                        bmem_addr = addr_i_cache;
                        bmem_read = 1'b1;
                        break;
                    end
                
                end
            end


        end


    end


    
    always_ff @(posedge clk) begin
        if (rst) begin
            burst_count <= '0;
        end else if (bmem_write && mem_ready) begin
            burst_count <= burst_count + 1'b1;       // Increment burst counter
        end 
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < MAX_REQ; i++) begin
                i_cache_addrs[i] <= '0;
                d_cache_addrs[i] <= '0;
            end
        end else begin
            if(mem_ready)begin
                    if (burst_count > 0) begin
                        
                    end
                    else begin
                        for (int i = 0; i < MAX_REQ; i++) begin

                            if(req_d_cache && d_cache_addrs[i] == '0)begin
                                d_cache_addrs[i] <= addr_d_cache;
                                break;
                            end

                            else if(req_i_cache && i_cache_addrs[i] == '0)begin
                                i_cache_addrs[i] <= addr_i_cache;
                                break;
                            end
                        end
                    end


            end
            if(data_valid)begin
                for (int i = 0; i < MAX_REQ; i++) begin
                    if(i_cache_addrs[i] == raddr)begin
                        i_cache_addrs[i] <= '0;
                        break;
                    end
                    if(d_cache_addrs[i] == raddr)begin
                        d_cache_addrs[i] <= '0;
                        break;
                    end
                end
            end
            if (bmem_write && burst_count == 3 && mem_ready) begin  // Last burst received
                for (int i = 0; i < MAX_REQ; i++) begin
                    if(req_d_cache && d_cache_addrs[i] == addr_d_cache)begin
                        d_cache_addrs[i] <= '0;
                        break;
                    end
                end
            end
        end

    end

endmodule


