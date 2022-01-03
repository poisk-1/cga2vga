package cga2vga

import chisel3._
import chisel3.util.HasBlackBoxInline
import chisel3.util.log2Ceil

class RAM(width: Int, depth: Int) extends BlackBox with HasBlackBoxInline {

  override def desiredName: String = s"rams_tdp_rf_rf_${width}_${depth}"

  val addressWidth = log2Ceil(depth)

  val io = IO(new Bundle {
    val clka = Input(Clock())
    val wea = Input(Bool())
    val ena = Input(Bool())
    val addra = Input(UInt(addressWidth.W))
    val dia = Input(UInt(width.W))
    val doa = Output(UInt(width.W))

    val clkb = Input(Clock())
    val web = Input(Bool())
    val enb = Input(Bool())
    val addrb = Input(UInt(addressWidth.W))
    val dib = Input(UInt(width.W))
    val dob = Output(UInt(width.W))
  })

  setInline(
    s"$desiredName.v",
    s"""
       |module $desiredName (clka,clkb,ena,enb,wea,web,addra,addrb,dia,dib,doa,dob);
       |
       |input clka,clkb,ena,enb,wea,web;
       |input [${addressWidth - 1}:0] addra,addrb;
       |input [${width - 1}:0] dia,dib;
       |output [${width - 1}:0] doa,dob;
       |reg [${width - 1}:0] ram [${depth - 1}:0];
       |reg [${width - 1}:0] doa,dob;
       |
       |always @(posedge clka)
       |begin
       |  if (ena)
       |    begin
       |      if (wea)
       |        ram[addra] <= dia;
       |      doa <= ram[addra];
       |    end
       |end
       |
       |always @(posedge clkb)
       |begin
       |  if (enb)
       |    begin
       |      if (web)
       |        ram[addrb] <= dib;
       |      dob <= ram[addrb];
       |    end
       |end
       |
       |endmodule""".stripMargin
  )
}
