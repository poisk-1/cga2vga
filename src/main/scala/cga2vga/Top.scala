package cga2vga

import chisel3._
import chisel3.util.log2Ceil
import chisel3.util.Cat
import chisel3.util.Fill
import chisel3.util.log2Floor
import chisel3.internal.firrtl.Width
import chisel3.experimental.Analog

class IOBUF extends BlackBox {
  val io = IO(new Bundle {
    val IO = Analog(1.W)
    val I = Input(Bool())
    val O = Output(Bool())
    val T = Input(Bool())
  })
}

class IOBUFInput(width: Int) extends RawModule {
  val io = IO(new Bundle {
    val IO = Vec(width, Analog(1.W))
    val O = Output(UInt(width.W))
  })

  val o = for (i <- 0 until width) yield {
    val ioBuf = Module(new IOBUF())
    ioBuf.io.IO <> io.IO(i)
    ioBuf.io.I := false.B
    ioBuf.io.T := true.B

    ioBuf.io.O
  }

  io.O := Cat(o.reverse)
}

class IOBUFOutput(width: Int) extends RawModule {
  val io = IO(new Bundle {
    val IO = Vec(width, Analog(1.W))
    val I = Input(UInt(width.W))
  })

  val o = for (i <- 0 until width) yield {
    val ioBuf = Module(new IOBUF())
    ioBuf.io.IO <> io.IO(i)
    ioBuf.io.I := io.I(i)
    ioBuf.io.T := false.B
  }
}

class Top extends RawModule {
  val CAP_CLOCK_MULTIPLE = 4

  val CAP_H_POLARITY = false
  val CAP_H_SYNC = 112
  val CAP_H_ALIGN = 2
  val CAP_H_BPORCH = 144 + CAP_H_ALIGN
  val CAP_H_FPORCH = 64 - CAP_H_ALIGN
  val CAP_H_ACTIVE = 640
  val CAP_H_TOTAL = CAP_H_FPORCH + CAP_H_SYNC + CAP_H_BPORCH + CAP_H_ACTIVE

  val CAP_V_POLARITY = false
  val CAP_V_SYNC = 9
  val CAP_V_ALIGN = -1
  val CAP_V_BPORCH = 52 + CAP_V_ALIGN
  val CAP_V_FPORCH = 54 - CAP_V_ALIGN
  val CAP_V_ACTIVE = 200
  val CAP_V_TOTAL = CAP_V_FPORCH + CAP_V_SYNC + CAP_V_BPORCH + CAP_V_ACTIVE

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

  val SYMBOL_WIDTH = 8
  val SYMBOL_HEIGHT = 8
  val SYMBOL_V_CENTER = GEN_V_ACTIVE_ADJ / 2
  val SYMBOL_H_CENTER = GEN_H_ACTIVE / 2
  val SYMBOL_V_TOP = SYMBOL_V_CENTER - SYMBOL_HEIGHT / 2
  val SYMBOL_V_BOTTOM = SYMBOL_V_CENTER + SYMBOL_HEIGHT / 2
  val SYMBOL_H_LEFT = SYMBOL_H_CENTER - SYMBOL_WIDTH / 2
  val SYMBOL_H_RIGHT = SYMBOL_H_CENTER + SYMBOL_WIDTH / 2

  val io = IO(new Bundle {
    val reset = Input(Bool())

    // 25 MHz
    val genClock = Input(Clock())
    val genSync = Vec(2, Analog(1.W))
    val genGreen = Vec(4, Analog(1.W))
    val genRed = Vec(4, Analog(1.W))
    val genBlue = Vec(4, Analog(1.W))

    // 15 MHz * CAP_CLOCK_MULTIPLE
    val capClock = Input(Clock())
    val capSync = Vec(2, Analog(1.W))
    val capRgbi = Vec(4, Analog(1.W))

    val pushButtons = Vec(2, Analog(1.W))

    val address = Output(UInt(log2Ceil(CAP_H_ACTIVE * CAP_V_ACTIVE).W))
    val valid = Output(Bool())
    val rgbi = Output(UInt(4.W))
  })

  val capSyncIoBuf = Module(new IOBUFInput(2))
  val capRgbiIoBuf = Module(new IOBUFInput(4))

  capSyncIoBuf.io.IO <> io.capSync
  capRgbiIoBuf.io.IO <> io.capRgbi

  val genSyncIoBuf = Module(new IOBUFOutput(2))
  val genRedIoBuf = Module(new IOBUFOutput(4))
  val genGreenIoBuf = Module(new IOBUFOutput(4))
  val genBlueIoBuf = Module(new IOBUFOutput(4))

  genSyncIoBuf.io.IO <> io.genSync
  genRedIoBuf.io.IO <> io.genRed
  genGreenIoBuf.io.IO <> io.genGreen
  genBlueIoBuf.io.IO <> io.genBlue

  val pushButtonsIoBuf = Module(new IOBUFInput(2))

  pushButtonsIoBuf.io.IO <> io.pushButtons

  val frameBuffer = Module(new RAM(4, CAP_H_ACTIVE * CAP_V_ACTIVE))

  frameBuffer.io.clka := io.capClock
  frameBuffer.io.clkb := io.genClock

  withClockAndReset(io.capClock, io.reset) {
    val vAddress = Wire(UInt(log2Ceil(CAP_V_ACTIVE).W))
    val hAddress = Wire(UInt(log2Ceil(CAP_H_ACTIVE).W))

    val vValid = Wire(Bool())
    val hValid = Wire(Bool())

    val hSync =
      RegNext(
        RegNext(capSyncIoBuf.io.O(0), (!CAP_H_POLARITY).B),
        (!CAP_H_POLARITY).B
      )
    val vSync =
      RegNext(
        RegNext(capSyncIoBuf.io.O(1), (!CAP_V_POLARITY).B),
        (!CAP_V_POLARITY).B
      )
    val rgbi =
      RegNext(
        RegNext(
          RegNext(capRgbiIoBuf.io.O, 0.U),
          0.U
        ),
        0.U
      )

    val hCap = Module(
      new Capture(
        CAP_H_SYNC * CAP_CLOCK_MULTIPLE,
        1,
        (CAP_H_BPORCH + CAP_H_ACTIVE) * CAP_CLOCK_MULTIPLE,
        CAP_H_POLARITY
      )
    )

    hCap.io.sync := hSync

    hAddress := (hCap.io.address - (CAP_H_BPORCH * CAP_CLOCK_MULTIPLE).U) >> log2Ceil(
      CAP_CLOCK_MULTIPLE
    )
    hValid := hCap.io.valid &&
      (hCap.io.address >= (CAP_H_BPORCH * CAP_CLOCK_MULTIPLE).U) &&
      !hCap.io.address(0) &&
      !hCap.io.address(1)

    withClock(hSync.asClock) {
      val vCap =
        Module(
          new Capture(
            CAP_V_SYNC,
            1,
            CAP_V_BPORCH + CAP_V_ACTIVE,
            CAP_V_POLARITY
          )
        )

      vCap.io.sync := vSync

      vAddress := vCap.io.address - CAP_V_BPORCH.U
      vValid := vCap.io.valid && (vCap.io.address >= CAP_V_BPORCH.U)
    }

    frameBuffer.io.ena := vValid && hValid
    frameBuffer.io.wea := true.B
    frameBuffer.io.addra := vAddress * CAP_H_ACTIVE.U + hAddress
    frameBuffer.io.dia := rgbi

    io.valid := frameBuffer.io.ena
    io.address := frameBuffer.io.addra
    io.rgbi := frameBuffer.io.dia
  }

  withClockAndReset(io.genClock, io.reset) {
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

    val hSync = RegNext(hGen.io.sync)
    val vSync = Wire(Bool())

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

      vSync := RegNext(vGen.io.sync)

      vAddress := vGen.io.address - GEN_V_BPORCH_ADJ.U
      vValid := vGen.io.valid && (vGen.io.address >= GEN_V_BPORCH_ADJ.U) && (vGen.io.address < (GEN_V_BPORCH_ADJ + GEN_V_ACTIVE_ADJ).U)
    }

    genSyncIoBuf.io.I := Cat(vSync, hSync)

    frameBuffer.io.enb := true.B
    frameBuffer.io.web := false.B
    frameBuffer.io.addrb := ((vAddress >> log2Ceil(
      GEN_TO_CAP_V_RATIO
    )) * GEN_H_ACTIVE.U + hAddress)

    val symbolsROM = Module(new SymbolsROM(8, 8 * 5))

    symbolsROM.io.clk := io.genClock
    symbolsROM.io.addr := vAddress - SYMBOL_V_TOP.U
    symbolsROM.io.en := true.B

    /*val SYMBOL_COUNTER = 25000000

    val symbolCounter = RegInit(UInt(log2Ceil(SYMBOL_COUNTER).W), 0.U)
    val symbolPressed =
      RegNext(
        RegNext(pushButtonsIoBuf.io.O(0), false.B),
        false.B
      )

    when(symbolCounter === 0.U) {
      when(symbolPressed === true.B) {
        symbolCounter := SYMBOL_COUNTER.U
      }
    }.otherwise {
      symbolCounter := symbolCounter - 1.U
    }*/

    val rgbi = Wire(UInt(4.W))
    val rgbiValid = RegNext(vValid && hValid)

    /*val rgbiSymbolActive = RegNext(
      vAddress >= SYMBOL_V_TOP.U && vAddress < SYMBOL_V_BOTTOM.U && hAddress >= SYMBOL_H_LEFT.U && hAddress < SYMBOL_H_RIGHT.U
    )
    val rgbiSymbolPosition =
      RegNext(
        (SYMBOL_WIDTH - 1).U - (hAddress - SYMBOL_H_LEFT.U)
      )

    when(rgbiValid && rgbiSymbolActive && symbolCounter =/= 0.U) {
      rgbi := Cat(
        true.B,
        false.B,
        false.B,
        symbolsROM.io.dout(rgbiSymbolPosition)
      )
    }.otherwise {
    }*/

    rgbi := frameBuffer.io.dob

    def assignChannel(channel: UInt, i: Int) =
      when(rgbiValid) {
        when(rgbi(3) === true.B) {
          channel := Fill(4, rgbi(i))
        }.otherwise {
          channel := Cat(0.U, Fill(3, rgbi(i)))
        }
      }.otherwise {
        channel := 0.U
      }

    assignChannel(genRedIoBuf.io.I, 0)
    assignChannel(genGreenIoBuf.io.I, 1)
    assignChannel(genBlueIoBuf.io.I, 2)
  }
}

object Top extends App {
  (new chisel3.stage.ChiselStage)
    .emitVerilog(new Top(), args)
}
