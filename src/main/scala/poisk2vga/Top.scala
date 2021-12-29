package poisk2vga

import chisel3._
import chisel3.util.log2Ceil

class Top extends RawModule {
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
    val reset = Input(Bool())
    val capClock = Input(Clock())
    val genClock = Input(Clock())
    val syncGpio = Input(UInt(4.W))
    val rgbiGpio = Input(UInt(4.W))
    val address = Output(UInt(log2Ceil(H_ACTIVE * V_ACTIVE).W))
    val rgbi = Output(UInt(4.W))
  })

  val frameBuffer = Module(new RAM(4, H_ACTIVE * V_ACTIVE))

  frameBuffer.io.clka := io.capClock
  frameBuffer.io.clkb := io.genClock

  withClockAndReset(io.capClock, io.reset) {
    val hSync =
      RegNext(RegNext(io.syncGpio(0), (!H_POLARITY).B), (!H_POLARITY).B)
    val vSync =
      RegNext(RegNext(io.syncGpio(1), (!V_POLARITY).B), (!V_POLARITY).B)
    val rgbi = RegNext(RegNext(RegNext(io.rgbiGpio, 0.U), 0.U), 0.U)

    val vAddress = Wire(UInt(log2Ceil(V_ACTIVE).W))
    val hAddress = Wire(UInt(log2Ceil(H_ACTIVE).W))

    val vValid = Wire(Bool())
    val hValid = Wire(Bool())

    val hCapture = Module(
      new Receiver(H_SYNC, 1, H_BPORCH_ADJ + H_ACTIVE, H_POLARITY)
    )

    hCapture.io.sync := hSync

    hAddress := hCapture.io.address - H_BPORCH_ADJ.U
    hValid := hCapture.io.valid && (hCapture.io.address >= H_BPORCH_ADJ.U)

    withClock(hCapture.io.valid.asClock) {
      val vCapture =
        Module(
          new Receiver(
            V_SYNC,
            1,
            V_BPORCH_ADJ + V_ACTIVE,
            V_POLARITY
          )
        )

      vCapture.io.sync := vSync

      vAddress := vCapture.io.address - V_BPORCH_ADJ.U
      vValid := vCapture.io.valid && (vCapture.io.address >= V_BPORCH_ADJ.U)
    }

    frameBuffer.io.ena := vValid && hValid
    frameBuffer.io.wea := vValid && hValid
    frameBuffer.io.addra := vAddress * H_ACTIVE.U + hAddress
    frameBuffer.io.dia := rgbi
  }

  withClockAndReset(io.genClock, io.reset) {
    val genAddress = RegInit(UInt(log2Ceil(H_ACTIVE * V_ACTIVE).W), 0.U)

    when(genAddress === (H_ACTIVE * V_ACTIVE - 1).U) {
      genAddress := 0.U
    }.otherwise {
      genAddress := genAddress + 1.U
    }

    frameBuffer.io.enb := true.B
    frameBuffer.io.web := false.B
    frameBuffer.io.addrb := genAddress

    io.rgbi := frameBuffer.io.dob
    io.address := genAddress
  }
}

object Top extends App {
  (new chisel3.stage.ChiselStage)
    .emitVerilog(new Top(), args)
}
