package cga2vga

import chisel3._
import chisel3.util.HasBlackBoxInline
import chisel3.util.log2Ceil

class SymbolsROM(width: Int, depth: Int)
    extends BlackBox
    with HasBlackBoxInline {

  override def desiredName: String = s"symbols_rom_${width}_${depth}"

  val addressWidth = log2Ceil(depth)

  val io = IO(new Bundle {
    val clk = Input(Clock())
    val en = Input(Bool())
    val addr = Input(UInt(addressWidth.W))
    val dout = Output(UInt(width.W))
  })

  setInline(
    s"$desiredName.v",
    s"""
       |module $desiredName (clk,en,addr,dout);
       |
       |input clk,en;
       |input [${addressWidth - 1}:0] addr;
       |output [${width - 1}:0] dout;
       |reg [${width - 1}:0] ram [${depth - 1}:0];
       |reg [${width - 1}:0] dout;
       |
       |initial begin
       |  $$readmemb("symbols.data", ram, 0, ${depth - 1});
       |end
       |always @(posedge clk)
       |begin
       |  if (en)
       |    begin
       |      dout <= ram[addr];
       |    end
       |end
       |
       |endmodule""".stripMargin
  )
}
