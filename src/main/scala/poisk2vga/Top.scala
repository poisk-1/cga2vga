package poisk2vga

import chisel3._
import chisel3.util.log2Ceil
import chisel3.util.Cat
import chisel3.util.Fill
import chisel3.util.log2Floor

class PMODPin extends Bundle {
  val I = Input(Bool())
  val O = Output(Bool())
  val T = Output(Bool())
}

class PMOD extends Bundle {
  val pins = Vec(8, new PMODPin())
}

class Top extends RawModule {
  val io = IO(new Bundle {
    val reset = Input(Bool())

    // 25 MHz
    val genClock = Input(Clock())
    val genPmodGreenSync = new PMOD()
    val genPmodRedBlue = new PMOD()

    // 15 MHz * CAP_CLOCK_MULTIPLE
    val capClock = Input(Clock())
    val capPmod = new PMOD()
  })

  val CAP_H_POLARITY = false
  val CAP_H_SYNC = 112
  val CAP_H_BPORCH = 144
  val CAP_H_FPORCH = 64
  val CAP_H_ACTIVE = 640
  val CAP_H_TOTAL = CAP_H_FPORCH + CAP_H_SYNC + CAP_H_BPORCH + CAP_H_ACTIVE

  val CAP_V_POLARITY = false
  val CAP_V_SYNC = 9
  val CAP_V_BPORCH = 52
  val CAP_V_FPORCH = 54
  val CAP_V_ACTIVE = 200
  val CAP_V_TOTAL = CAP_V_FPORCH + CAP_V_SYNC + CAP_V_BPORCH + CAP_V_ACTIVE

  // Adjusted for receiver delay
  val CAP_H_BPORCH_ADJ = CAP_H_BPORCH - 1
  val CAP_V_BPORCH_ADJ = CAP_V_BPORCH - 1

  val CAP_CLOCK_MULTIPLE = 2

  for (i <- 0 until 8) {
    io.capPmod.pins(i).T := true.B
    io.capPmod.pins(i).O := false.B
    io.genPmodGreenSync.pins(i).T := false.B
    io.genPmodRedBlue.pins(i).T := false.B
  }

  val frameBuffer = Module(new RAM(4, CAP_H_ACTIVE * CAP_V_ACTIVE))

  frameBuffer.io.clka := io.capClock
  frameBuffer.io.clkb := io.genClock

  withClockAndReset(io.capClock, io.reset) {
    val hSync =
      RegNext(
        RegNext(io.capPmod.pins(0).I, (!CAP_H_POLARITY).B),
        (!CAP_H_POLARITY).B
      )
    val vSync =
      RegNext(
        RegNext(io.capPmod.pins(1).I, (!CAP_V_POLARITY).B),
        (!CAP_V_POLARITY).B
      )
    val rgbi =
      RegNext(
        RegNext(
          RegNext(
            Cat(
              io.capPmod.pins(7).I,
              io.capPmod.pins(6).I,
              io.capPmod.pins(5).I,
              io.capPmod.pins(4).I
            ),
            0.U
          ),
          0.U
        ),
        0.U
      )

    val vAddress = Wire(UInt(log2Ceil(CAP_V_ACTIVE).W))
    val hAddress = Wire(UInt(log2Ceil(CAP_H_ACTIVE).W))

    val vValid = Wire(Bool())
    val hValid = Wire(Bool())

    val hCap = Module(
      new Capture(
        CAP_H_SYNC * CAP_CLOCK_MULTIPLE,
        1,
        (CAP_H_BPORCH_ADJ + CAP_H_ACTIVE) * CAP_CLOCK_MULTIPLE,
        CAP_H_POLARITY
      )
    )

    hCap.io.sync := hSync

    hAddress := (hCap.io.address - (CAP_H_BPORCH_ADJ * CAP_CLOCK_MULTIPLE).U) >> log2Ceil(
      CAP_CLOCK_MULTIPLE
    )
    hValid := hCap.io.valid &&
      (hCap.io.address >= (CAP_H_BPORCH_ADJ * CAP_CLOCK_MULTIPLE).U) &&
      !hCap.io.address(0)

    withClock(hSync.asClock) {
      val vCap =
        Module(
          new Capture(
            CAP_V_SYNC,
            1,
            CAP_V_BPORCH_ADJ + CAP_V_ACTIVE,
            CAP_V_POLARITY
          )
        )

      vCap.io.sync := vSync

      vAddress := vCap.io.address - CAP_V_BPORCH_ADJ.U
      vValid := vCap.io.valid && (vCap.io.address >= CAP_V_BPORCH_ADJ.U)
    }

    frameBuffer.io.ena := vValid && hValid
    frameBuffer.io.wea := vValid && hValid
    frameBuffer.io.addra := vAddress * CAP_H_ACTIVE.U + hAddress
    frameBuffer.io.dia := rgbi
  }

  withClockAndReset(io.genClock, io.reset) {
    val GEN_H_POLARITY = false
    val GEN_H_SYNC = 96
    val GEN_H_BPORCH = 48
    val GEN_H_FPORCH = 16
    val GEN_H_ACTIVE = 640

    val GEN_V_POLARITY = false
    val GEN_V_SYNC = 2
    val GEN_V_BPORCH = 33
    val GEN_V_FPORCH = 10
    val GEN_V_ACTIVE = 480

    // Adjusted to fit captured frame
    val GEN_TO_CAP_V_RATIO = 2
    val GEN_V_ACTIVE_ADJ = CAP_V_ACTIVE * GEN_TO_CAP_V_RATIO
    val GEN_V_BPORCH_ADJ = GEN_V_BPORCH + (GEN_V_ACTIVE - GEN_V_ACTIVE_ADJ) / 2
    val GEN_V_FPORCH_ADJ = GEN_V_FPORCH + (GEN_V_ACTIVE - GEN_V_ACTIVE_ADJ) / 2

    val vAddress = Wire(UInt(log2Ceil(GEN_V_ACTIVE_ADJ).W))
    val hAddress = Wire(UInt(log2Ceil(GEN_H_ACTIVE).W))

    val vValid = Wire(Bool())
    val hValid = Wire(Bool())

    val hGen = Module(
      new Generator(
        GEN_H_SYNC,
        GEN_H_BPORCH + GEN_H_ACTIVE + GEN_H_FPORCH,
        GEN_H_POLARITY
      )
    )

    io.genPmodGreenSync.pins(4).O := hGen.io.sync

    hAddress := hGen.io.address - GEN_H_BPORCH.U
    hValid := hGen.io.valid && (hGen.io.address >= GEN_H_BPORCH.U) && (hGen.io.address < (GEN_H_BPORCH + GEN_H_ACTIVE).U)

    withClock((!hGen.io.sync).asClock) {
      val vGen =
        Module(
          new Generator(
            GEN_V_SYNC,
            GEN_V_BPORCH_ADJ + GEN_V_ACTIVE_ADJ + GEN_V_FPORCH_ADJ,
            GEN_V_POLARITY
          )
        )

      io.genPmodGreenSync.pins(5).O := vGen.io.sync

      vAddress := vGen.io.address - GEN_V_BPORCH_ADJ.U
      vValid := vGen.io.valid && (vGen.io.address >= GEN_V_BPORCH_ADJ.U) && (vGen.io.address < (GEN_V_BPORCH_ADJ + GEN_V_ACTIVE_ADJ).U)
    }

    io.genPmodGreenSync.pins(6).O := false.B
    io.genPmodGreenSync.pins(7).O := false.B

    frameBuffer.io.enb := vValid && hValid
    frameBuffer.io.web := false.B
    frameBuffer.io.addrb := ((vAddress >> log2Ceil(GEN_TO_CAP_V_RATIO)) * GEN_H_ACTIVE.U + hAddress)

    val green = Wire(UInt(4.W))
    val red = Wire(UInt(4.W))
    val blue = Wire(UInt(4.W))

    def assignChannel(channel: UInt, i: Int) =
      when(vValid && hValid) {
        val rgbi = frameBuffer.io.dob

        when(rgbi(3) === true.B) {
          channel := Fill(4, rgbi(i))
        }.otherwise {
          channel := Cat(0.U, Fill(3, rgbi(i)))
        }
      }.otherwise {
        channel := 0.U
      }

    assignChannel(red, 0)
    assignChannel(green, 1)
    assignChannel(blue, 2)

    for (i <- 0 until 4) {
      io.genPmodGreenSync.pins(i).O := green(i)
      io.genPmodRedBlue.pins(i).O := red(i)
      io.genPmodRedBlue.pins(i + 4).O := blue(i)
    }
  }
}

object Top extends App {
  (new chisel3.stage.ChiselStage)
    .emitVerilog(new Top(), args)
}
