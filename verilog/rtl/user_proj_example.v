// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;
    
   wire [15:0] in1, in2;
    wire [5:0] in3;
    wire [16:0] out;
    //wire en_mode;

    assign {in3, in1, in2} = io_in[`MPRJ_IO_PADS-2:0];
    assign io_out = {21'd0, out};
    
    axhrca_ngk_rev_16_8_4 u1 (.a(in1),.b(in2),.sum(out));
 endmodule
 
 module axhrca_ngk_rev_16_8_4(a,b,sum);
input [15:0] a,b;

output [16:0] sum;

wire [3:1]cout;
wire [9 : 15] cout1;
wire cin;

assign sum[0]=a[0]^b[0];
assign cin=a[0]&b[0];
ascfa4v2 u1 (a[1],b[1],cin,sum[1],cout[1]);
genvar i;
generate
    for(i=2;i<=(3);i=i+1) begin
        ascfa4v2 u2 (a[i],b[i],cout[i-1],sum[i],cout[i]);
    end
endgenerate

genvar j;
generate 
    for(j=4;j<=(7);j=j+1) begin
    ascfa4v1 u3 (a[j],b[j],sum[j]);
    end
endgenerate
assign sum[8]=a[7] & b[7];

accfa u4(a[9],b[9],sum[8],sum[9],cout1[9]);

genvar z;
generate
 for(z=10;z<=15;z=z+1) begin
 accfa u5(a[z],b[z],cout1[z-1],sum[z],cout1[z]);
 end
endgenerate
assign sum[16]=cout1[5];

endmodule


module accfa(a,b,c,sum,carry);
input a,b,c;
output sum,carry;
wire sum,carry,w;
assign sum=a^b^c;
//assign sum = w^c; // sum bit
assign carry=((a&b) | (b&c) | (a&c)); //carry bit
endmodule

module ascfa4v1(a,b,sum);
input a,b;
output sum;
wire w3=a|b;
assign sum= w3;

endmodule

module ascfa4v2(a,b,cin,sum,cout);
input a,b,cin;
output sum,cout;
wire w3=a|b;
assign sum= w3|cin;
assign cout= a&b;
endmodule



`default_nettype wire
