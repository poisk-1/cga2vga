package poisk2vga

import chisel3._

class Top extends Module {
  val H_POLARITY = false
  val H_SYNC = 112
  val H_BPORCH = 128
  val H_FPORCH = 80
  val H_ACTIVE = 640
  val H_TOTAL = H_FPORCH + H_SYNC + H_BPORCH + H_ACTIVE

  val hReceiver = Module(new Receiver(H_SYNC, H_BPORCH + H_ACTIVE, H_POLARITY))

  val io = IO(new Bundle {
    val syncGpio = Input(UInt(4.W))
    val rgbiGpio = Input(UInt(4.W))
    val hAddress = Output(UInt(hReceiver.io.address.getWidth.W))
    val hValid = Output(Bool())
    val rgbi = Output(UInt(4.W))
  })

  val rgbi = RegNext(RegNext(RegNext(io.rgbiGpio, 0.U), 0.U), 0.U)

  hReceiver.io.sync := io.syncGpio(0)
  io.hAddress := hReceiver.io.address - H_BPORCH.U
  io.hValid := hReceiver.io.valid && hReceiver.io.address >= H_BPORCH.U
  io.rgbi := rgbi
}

object Top extends App {
  (new chisel3.stage.ChiselStage)
    .emitVerilog(new Top(), args)
}
