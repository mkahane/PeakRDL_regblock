{%- import "utils_tmpl.sv" as utils with context -%}


import {{package_name}}::*;


module {{module_name}} (
        input wire clk,
        {%- for signal in reset_signals %}
        {{signal.port_declaration}},
        {% endfor %}

        {%- for signal in user_signals %}
        {{signal.port_declaration}},
        {% endfor %}

        {%- for interrupt in interrupts %}
        {{interrupt.port_declaration}},
        {% endfor %}

        {{cpuif.port_declaration|indent(8)}},

        {{hwif.port_declaration|indent(8)}}
    );

    localparam ADDR_WIDTH = {{addr_width}};
    localparam DATA_WIDTH = {{data_width}};

    //--------------------------------------------------------------------------
    // CPU Bus interface logic
    //--------------------------------------------------------------------------
    logic cpuif_req;
    logic cpuif_req_is_wr;
    logic [ADDR_WIDTH-1:0] cpuif_addr;
    logic [DATA_WIDTH-1:0] cpuif_wr_data;
    logic [DATA_WIDTH-1:0] cpuif_wr_bitstrb;

    logic cpuif_rd_ack;
    logic [DATA_WIDTH-1:0] cpuif_rd_data;
    logic cpuif_rd_err;

    logic cpuif_wr_ack;
    logic cpuif_wr_err;

    {{cpuif.get_implementation()|indent}}

    //--------------------------------------------------------------------------
    // Address Decode
    //--------------------------------------------------------------------------
    {{address_decode.get_strobe_struct()|indent}}
    access_strb_t access_strb;

    always_comb begin
        {{address_decode.get_implementation()|indent(8)}}
    end

    // Writes are always posted with no error response
    assign cpuif_wr_ack = cpuif_req & cpuif_req_is_wr;
    assign cpuif_wr_err = '0;

    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------
    {{field_logic.get_storage_struct()|indent}}

    //Field next-state logic, and output port signal assignment (aka output mapping layer)
    {%- call utils.AlwaysFF(cpuif_reset) %}
    if({{cpuif_reset.activehigh_identifier}}) begin
        {{field_logic.get_storage_reset_implementation()|indent(8)}}
    end else begin
        {{field_logic.get_storage_next_state_implementation()|indent(8)}}
    end
    {%- endcall %}

    /*
    always_comb begin
        Next State Logic
        {{field_logic.assign_default_nextstate()|indent(8)}}
        if({{cpuif.signal(cpuif_wr_valid.identifier)}}) begin
            case (slv_reg_wr_addr)
            {{field_logic.get_write_demux(addr_to_reg_map, cpuif.signal("wrdata"))|indent(12)}}
            endcase
        end
    end


    //--------------------------------------------------------------------------
    // Readback mux
    //--------------------------------------------------------------------------
    logic readback_err;
    logic readback_done;
    logic [DATA_WIDTH-1:0] readback_data;

    {{readback_mux.get_implementation(addr_to_reg_map, cpuif.signal("rddata"))|indent}}
    

    {%- call utils.AlwaysFF(cpuif_reset) %}
        if({{cpuif_reset.activehigh_identifier}}) begin
            cpuif_rd_ack <= '0;
            cpuif_rd_data <= '0;
            cpuif_rd_err <= '0;
        end else begin
            cpuif_rd_ack <= readback_done;
            cpuif_rd_data <= readback_data;
            cpuif_rd_err <= readback_err;
        end
    {%- endcall %}
    */

endmodule
