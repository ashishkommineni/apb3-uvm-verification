`timescale 1ns / 1ps

module apb3_register_slave #(
    parameter int unsigned ADDR_WIDTH  = 8,
    parameter int unsigned DATA_WIDTH  = 32,
    parameter int unsigned WAIT_STATES = 1
) (
    input  logic                  PCLK,
    input  logic                  PRESETn,
    input  logic                  PSEL,
    input  logic                  PENABLE,
    input  logic                  PWRITE,
    input  logic [ADDR_WIDTH-1:0] PADDR,
    input  logic [DATA_WIDTH-1:0] PWDATA,
    output logic [DATA_WIDTH-1:0] PRDATA,
    output logic                  PREADY,
    output logic                  PSLVERR
);
  localparam int WAIT_W = (WAIT_STATES == 0) ? 1 : $clog2(WAIT_STATES + 1);
  logic [WAIT_W-1:0] wait_count_q;
  logic [DATA_WIDTH-1:0] regs[0:3];
  logic access;
  logic valid_addr;
  logic transfer;

  assign access     = PSEL && PENABLE;
  assign valid_addr = (PADDR[ADDR_WIDTH-1:4] == '0) && (PADDR[1:0] == 2'b00);
  assign PREADY     = access && (wait_count_q == WAIT_W'(WAIT_STATES));
  assign transfer   = access && PREADY;
  assign PSLVERR    = transfer && !valid_addr;

  always_comb begin
    PRDATA = '0;
    if (valid_addr) PRDATA = regs[PADDR[3:2]];
  end

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      wait_count_q <= '0;
    end else if (!access) begin
      wait_count_q <= '0;
    end else if (!PREADY) begin
      wait_count_q <= wait_count_q + 1'b1;
    end
  end

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      for (int i = 0; i < 4; i++) regs[i] <= '0;
    end else if (transfer && PWRITE && valid_addr) begin
      regs[PADDR[3:2]] <= PWDATA;
    end
  end
endmodule
