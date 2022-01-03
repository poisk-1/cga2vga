package cga2vga

import chisel3._
import chisel3.util.log2Ceil

class Generator(
    syncLength: Int,
    dataLength: Int,
    polarity: Boolean
) extends Module {
  require(syncLength >= 1)
  require(dataLength >= 2)

  val io = IO(new Bundle {
    val sync = Output(Bool())
    val address = Output(UInt(log2Ceil(dataLength).W))
    val valid = Output(Bool())
  })

  val counter = RegInit(
    (syncLength - 1).U(log2Ceil(Math.max(syncLength, dataLength)).W)
  )

  val sync = RegInit(polarity.B)

  when(counter === 0.U) {
    when(sync === polarity.B) {
      counter := (dataLength - 1).U
    }.otherwise {
      counter := (syncLength - 1).U
    }

    sync := !sync
  }.otherwise {
    counter := counter - 1.U
  }

  io.address := ((dataLength - 1).U - counter)
  io.sync := sync
  io.valid := (sync =/= polarity.B)
}
