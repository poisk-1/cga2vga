`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2023 11:23:13 AM
// Design Name: 
// Module Name: Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Gen #(parameter SYNC = 10, parameter BP = 0, parameter VALID = 100, parameter FP = 0, parameter SYNC_POL = 0) (
    input wire clk,
    input wire reset,
    input wire enable,
    output wire sync,
    output wire valid,
    output wire cascade_enable,
    output wire [$clog2(VALID) - 1:0] address);

    reg [$clog2(SYNC + BP + VALID + FP) - 1:0] address_r;
    reg sync_r;
    reg valid_r;

    always @(posedge clk) begin
        if (!reset) begin
            address_r <= 0;
            sync_r <= SYNC_POL;
            valid_r <= 0;
        end else if(enable) begin
            if (address_r == SYNC - 1)
                sync_r <= !SYNC_POL;

            if (address_r == SYNC + BP - 1)
                valid_r <= 1;

            if (address_r == SYNC + BP + VALID - 1)
                valid_r <= 0;

            if (address_r == SYNC + BP + VALID + FP - 1) begin
                address_r <= 0;
                sync_r <= SYNC_POL;
            end else begin
                address_r <= address_r + 1;
            end
        end
    end

    assign sync = sync_r;
    assign valid = valid_r;
    assign address = address_r - (SYNC + BP);
    assign cascade_enable = address_r == SYNC + BP + VALID + FP - 1;

endmodule

module Buffer (
    input wire clk,
    input wire reset,
    input wire in,
    output wire out
);
    reg r0;
    reg r1;

    always @(posedge clk) begin
        if (!reset) begin
            r0 <= 0;
            r1 <= 0;
        end else begin
            r0 <= in;
            r1 <= r0;
        end
    end

    assign out = r1;
endmodule

module Capture #(parameter OFFSET = 10, parameter VALID = 100) (
    input wire clk,
    input wire reset,
    input wire sync,
    input wire enable,
    output wire valid,
    output wire cascade_enable,
    output wire [/*$clog2(VALID) - 1*/15:0] address
);
    wire at_edge;
    reg sync_r;
    reg [/*$clog2(VALID + OFFSET) - 1*/15:0] counter_r;

    assign at_edge = sync && !sync_r;

    always @(posedge clk) begin
        if (!reset) begin
            sync_r <= 0;
            counter_r <= 0;
        end else if (enable) begin
            sync_r <= sync;
            if (at_edge) begin
                counter_r <= 0;
            end else begin
                counter_r <= counter_r + 1;
            end
        end
    end

    assign cascade_enable = at_edge;
    assign address = counter_r - OFFSET;
    assign valid = counter_r >= OFFSET && counter_r < (OFFSET + VALID);
endmodule

module Sampler (
    input wire clk,
    input wire reset,
    input wire [15:0] sample_address,
    input wire [3:0] sample,
    output wire valid,
    output wire [3:0]data,
    output wire [15:0] address
);
    reg [2:0] sample_counter_r [3:0];
    wire [2:0] sample_pos;

    assign sample_pos = sample_address[2:0];

    integer i;

    always @(posedge clk) begin
        for (i = 0; i < 4; i = i + 1) begin
            if (!reset) begin
                sample_counter_r[i] <= 0;
            end else begin
                if (sample_pos == 0) begin
                    sample_counter_r[i] <= sample[i];
                end else if (sample_pos != 7) begin
                    sample_counter_r[i] <= sample_counter_r[i] + sample[i];
                end
            end
        end
    end

    assign valid = sample_pos == 7;
    assign data[0] = sample_counter_r[0] + sample[0] >= 4;
    assign data[1] = sample_counter_r[1] + sample[1] >= 4;
    assign data[2] = sample_counter_r[2] + sample[2] >= 4;
    assign data[3] = sample_counter_r[3] + sample[3] >= 4;
    assign address = sample_address[15:3];

endmodule

//  Xilinx True Dual Port RAM, No Change, Dual Clock
//  This code implements a parameterizable true dual port memory (both ports can read and write).
//  This is a no change RAM which retains the last read value on the output during writes
//  which is the most power efficient mode.
//  If a reset or enable is not necessary, it may be tied off or removed from the code.

module RAM #(
    parameter RAM_WIDTH = 18, // Specify RAM data width
    parameter RAM_DEPTH = 1024 // Specify RAM depth (number of entries)
) (
    input [$clog2(RAM_DEPTH-1)-1:0] addra, // Port A address bus, width determined from RAM_DEPTH
    input [$clog2(RAM_DEPTH-1)-1:0] addrb, // Port B address bus, width determined from RAM_DEPTH
    input [RAM_WIDTH-1:0] dina, // Port A RAM input data
    input [RAM_WIDTH-1:0] dinb, // Port B RAM input data
    input clka, // Port A clock
    input clkb, // Port B clock
    input wea, // Port A write enable
    input web, // Port B write enable
    input ena, // Port A RAM Enable, for additional power savings, disable port when not in use
    input enb, // Port B RAM Enable, for additional power savings, disable port when not in use
    input rsta, // Port A output reset (does not affect memory contents)
    input rstb, // Port B output reset (does not affect memory contents)
    input regcea, // Port A output register enable
    input regceb, // Port B output register enable
    output [RAM_WIDTH-1:0] douta, // Port A RAM output data
    output [RAM_WIDTH-1:0] doutb // Port B RAM output data
);

    reg [RAM_WIDTH-1:0] BRAM [RAM_DEPTH-1:0];
    reg [RAM_WIDTH-1:0] ram_data_a = {RAM_WIDTH{1'b0}};
    reg [RAM_WIDTH-1:0] ram_data_b = {RAM_WIDTH{1'b0}};

    always @(posedge clka)
    if (ena)
        if (wea)
            BRAM[addra] <= dina;
        else
            ram_data_a <= BRAM[addra];

    always @(posedge clkb)
    if (enb)
        if (web)
            BRAM[addrb] <= dinb;
        else
            ram_data_b <= BRAM[addrb];

            //assign douta = ram_data_a;
            //assign doutb = ram_data_b;

    reg [RAM_WIDTH-1:0] douta_reg = {RAM_WIDTH{1'b0}};
    reg [RAM_WIDTH-1:0] doutb_reg = {RAM_WIDTH{1'b0}};

    always @(posedge clka)
    if (rsta)
        douta_reg <= {RAM_WIDTH{1'b0}};
    else if (regcea)
        douta_reg <= ram_data_a;

    always @(posedge clkb)
    if (rstb)
        doutb_reg <= {RAM_WIDTH{1'b0}};
    else if (regceb)
        doutb_reg <= ram_data_b;

    assign douta = douta_reg;
    assign doutb = doutb_reg;
endmodule

module Top (
    input wire cga_clk,
    input wire cga_reset,
    input wire cga_hsync,
    input wire cga_vsync,
    input wire cga_red,
    input wire cga_green,
    input wire cga_blue,
    input wire cga_intensity,
    input wire vga_clk,
    input wire vga_reset,
    output wire cga_hsync_b,
    output wire cga_vsync_b,
    output wire cga_blue_b,
    output wire cga_valid,
    output wire [15:0] cga_vaddress,
    output wire [15:0] hsample_address,
    output wire [15:0] cga_haddress,
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [1:0] vga_red,
    output wire [1:0] vga_green,
    output wire [1:0] vga_blue
);

    Buffer cga_hsync_buffer(.clk(cga_clk), .reset(cga_reset), .in(cga_hsync), .out(cga_hsync_b));
    Buffer cga_vsync_buffer(.clk(cga_clk), .reset(cga_reset), .in(cga_vsync), .out(cga_vsync_b));
    Buffer cga_red_buffer(.clk(cga_clk), .reset(cga_reset), .in(cga_red), .out(cga_red_b));
    Buffer cga_green_buffer(.clk(cga_clk), .reset(cga_reset), .in(cga_green), .out(cga_green_b));
    Buffer cga_blue_buffer(.clk(cga_clk), .reset(cga_reset), .in(cga_blue), .out(cga_blue_b));
    Buffer cga_intensity_buffer(.clk(cga_clk), .reset(cga_reset), .in(cga_intensity), .out(cga_intensity_b));

    parameter CAP_HOFFSET = 'h48e;
    parameter CAP_VOFFSET = 'h33;

    wire cga_venable;
    wire cga_vvalid;
    wire cga_hvalid;

    parameter CAP_HVALID = 640;
    parameter CAP_CLK_MUL = 8;
    parameter CAP_VVALID = 200;

    Capture #(.OFFSET(CAP_HOFFSET), .VALID(CAP_HVALID * CAP_CLK_MUL)) cga_hcap(.clk(cga_clk), .reset(cga_reset), .sync(cga_hsync_b), .enable(1), .valid(cga_hvalid), .cascade_enable(cga_venable), .address(hsample_address));
    Capture #(.OFFSET(CAP_VOFFSET), .VALID(CAP_VVALID)) cga_vcap(.clk(cga_clk), .reset(cga_reset), .sync(cga_vsync_b), .enable(cga_venable), .valid(cga_vvalid), .address(cga_vaddress));

    wire cga_sampler_valid;
    wire [3:0] cga_sampler_data;

    Sampler cga_sampler(.clk(cga_clk), .reset(cga_reset), .sample_address(hsample_address), .sample({cga_intensity_b, cga_red_b, cga_green_b, cga_blue_b}), .valid(cga_sampler_valid), .data(cga_sampler_data), .address(cga_haddress));

    assign cga_valid = cga_vvalid & cga_hvalid & cga_sampler_valid;

    reg [15:0] cga_vaddress_r;
    reg [15:0] cga_haddress_r;
    reg cga_valid_r;
    reg [3:0] cga_sampler_data_r;

    always @(posedge cga_clk) begin
        cga_vaddress_r <= cga_vaddress;
        cga_haddress_r <= cga_haddress;
        cga_valid_r <= cga_valid;
        cga_sampler_data_r <= cga_sampler_data;
    end

    /*parameter GEN_HSYNC = 96;
    parameter GEN_HBP = 48;
    parameter GEN_HVALID = 640;
    parameter GEN_HFP = 16;
    parameter GEN_VSYNC = 2;
    parameter GEN_VBP = 33;
    parameter GEN_VFP = 10;
    parameter GEN_VVALID = 480;
    
    parameter GEN_V_ADJ = (GEN_VVALID - (CAP_VVALID * 2));
    parameter GEN_VBP_ADJ = GEN_VBP + (GEN_V_ADJ / 2);
    parameter GEN_VFP_ADJ = GEN_VFP + (GEN_V_ADJ / 2);
    parameter GEN_VVALID_ADJ = GEN_VVALID - GEN_V_ADJ;*/
    
    parameter GEN_HSYNC = 136;
    parameter GEN_HBP = 200;
    parameter GEN_HVALID = 1280;
    parameter GEN_HFP = 64;
    
    parameter GEN_VSYNC = 3;
    parameter GEN_VBP = 24;
    parameter GEN_VFP = 1;
    parameter GEN_VVALID = 800;    
    
    wire [$clog2(GEN_HVALID) - 1:0] vga_haddress;
    wire [$clog2(GEN_VVALID) - 1:0] vga_vaddress;

    wire vga_hvalid;
    wire vga_vvalid;
    wire vga_venable;
    //wire [$clog2(GEN_HVALID) - 1:0] vga_haddress;
    //wire [$clog2(GEN_VVALID) - 1:0] vga_vaddress;

    wire vga_hsync0;
    wire vga_vsync0;

    Gen #(.SYNC(GEN_HSYNC), .BP(GEN_HBP), .VALID(GEN_HVALID), .FP(GEN_HFP)) vga_hgen(.clk(vga_clk), .reset(vga_reset), .enable(1), .sync(vga_hsync0), .valid(vga_hvalid), .address(vga_haddress), .cascade_enable(vga_venable));
    Gen #(.SYNC(GEN_VSYNC), .BP(GEN_VBP/*_ADJ*/), .VALID(GEN_VVALID/*_ADJ*/), .FP(GEN_VFP/*_ADJ*/)) vga_vgen(.clk(vga_clk), .reset(vga_reset), .enable(vga_venable), .sync(vga_vsync0), .valid(vga_vvalid), .address(vga_vaddress));

    wire vga_valid0;
    wire vga_valid;
    assign vga_valid0 = vga_hvalid & vga_vvalid;
    Buffer vga_valid_buffer(.clk(vga_clk), .reset(vga_reset), .in(vga_valid0), .out(vga_valid));

    Buffer vga_hsync_buffer(.clk(vga_clk), .reset(vga_reset), .in(vga_hsync0), .out(vga_hsync));
    Buffer vga_vsync_buffer(.clk(vga_clk), .reset(vga_reset), .in(vga_vsync0), .out(vga_vsync));

    wire [3:0] vga_out;

    RAM #(
    .RAM_WIDTH(4), // Specify RAM data width
    .RAM_DEPTH(CAP_HVALID * CAP_VVALID) // Specify RAM depth (number of entries)
    ) your_instance_name (
        .addra(cga_vaddress_r * CAP_HVALID + cga_haddress_r), // Port A address bus, width determined from RAM_DEPTH
        .addrb((vga_vaddress >> 2) * CAP_HVALID + (vga_haddress >> 1)), // Port B address bus, width determined from RAM_DEPTH
        //.addrb((vga_vaddress >> 1) * CAP_HVALID + vga_haddress), // Port B address bus, width determined from RAM_DEPTH
        .dina(cga_sampler_data_r), // Port A RAM input data, width determined from RAM_WIDTH
        .dinb(0), // Port B RAM input data, width determined from RAM_WIDTH
        .clka(cga_clk), // Port A clock
        .clkb(vga_clk), // Port B clock
        .wea(cga_valid_r), // Port A write enable
        .web(0), // Port B write enable
        .ena(cga_valid_r), // Port A RAM Enable, for additional power savings, disable port when not in use
        .enb(vga_valid0), // Port B RAM Enable, for additional power savings, disable port when not in use
        .rsta(!cga_reset), // Port A output reset (does not affect memory contents)
        .rstb(!vga_reset), // Port B output reset (does not affect memory contents)
        .regcea(0), // Port A output register enable
        .regceb(1), // Port B output register enable
        .douta(), // Port A RAM output data, width determined from RAM_WIDTH
        .doutb(vga_out) // Port B RAM output data, width determined from RAM_WIDTH
    );

    //assign vga_red = vga_valid0 ? vga_haddress[6:5] : 0;
    //assign vga_green = vga_valid0 ? vga_haddress[8:7] : 0;
    //assign vga_blue = vga_valid0 ? vga_vaddress[7:6] : 0;

    assign vga_red = vga_valid ? {vga_out[2], vga_out[3]} : 2'b00;
    assign vga_green = vga_valid ? {vga_out[1], vga_out[3]} : 2'b00;
    assign vga_blue = vga_valid ? {vga_out[0], vga_out[3]} : 2'b00;
endmodule