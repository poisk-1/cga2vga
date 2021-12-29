package poisk2vga

import chisel3._
import chisel3.util.log2Ceil

class Top extends Module {
  val H_POLARITY = false
  val H_SYNC = 112
  val H_BPORCH = 144
  val H_FPORCH = 64
  val H_ACTIVE = 640
  val H_TOTAL = H_FPORCH + H_SYNC + H_BPORCH + H_ACTIVE

  val V_POLARITY = false
  val V_SYNC = 9
  val V_BPORCH = 52
  val V_FPORCH = 54
  val V_ACTIVE = 200
  val V_TOTAL = V_FPORCH + V_SYNC + V_BPORCH + V_ACTIVE

  // Adjusted for receiver delay
  val H_BPORCH_ADJ = H_BPORCH - 1
  val V_BPORCH_ADJ = V_BPORCH - 1

  val io = IO(new Bundle {
    val syncGpio = Input(UInt(4.W))
    val rgbiGpio = Input(UInt(4.W))
    val address = Output(UInt(log2Ceil(H_ACTIVE * V_ACTIVE).W))
    val valid = Output(Bool())
    val rgbi = Output(UInt(4.W))
  })

  val hSync = RegNext(RegNext(io.syncGpio(0), (!H_POLARITY).B), (!H_POLARITY).B)
  val vSync = RegNext(RegNext(io.syncGpio(1), (!V_POLARITY).B), (!V_POLARITY).B)
  val rgbi = RegNext(RegNext(RegNext(io.rgbiGpio, 0.U), 0.U), 0.U)

  val vAddress = Wire(UInt(log2Ceil(V_ACTIVE).W))
  val hAddress = Wire(UInt(log2Ceil(H_ACTIVE).W))

  val vValid = Wire(Bool())
  val hValid = Wire(Bool())

  val hReceiver = Module(
    new Receiver(H_SYNC, 1, H_BPORCH_ADJ + H_ACTIVE, H_POLARITY)
  )

  hReceiver.io.sync := hSync

  hAddress := hReceiver.io.address - H_BPORCH_ADJ.U
  hValid := hReceiver.io.valid && (hReceiver.io.address >= H_BPORCH_ADJ.U)

  withClock(hReceiver.io.valid.asClock) {
    val vReceiver =
      Module(
        new Receiver(
          V_SYNC,
          1,
          V_BPORCH_ADJ + V_ACTIVE,
          V_POLARITY
        )
      )

    vReceiver.io.sync := vSync

    vAddress := vReceiver.io.address - V_BPORCH_ADJ.U
    vValid := vReceiver.io.valid && (vReceiver.io.address >= V_BPORCH_ADJ.U)
  }

  io.address := vAddress * H_ACTIVE.U + hAddress
  io.valid := vValid && hValid
  io.rgbi := rgbi
}

object Top extends App {
  (new chisel3.stage.ChiselStage)
    .emitVerilog(new Top(), args)
}
