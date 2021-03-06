package cga2vga

import chisel3._
import chisel3.util.log2Ceil

class Capture(
    syncLength: Int,
    syncSlack: Int,
    dataLength: Int,
    polarity: Boolean
) extends Module {
  require((syncLength - syncSlack) >= 1)
  require(syncSlack >= 0)
  require(dataLength >= 2)

  val io = IO(new Bundle {
    val sync = Input(Bool())
    val address = Output(UInt(log2Ceil(dataLength).W))
    val valid = Output(Bool())
  })

  val counter = RegInit(
    0.U(log2Ceil(Math.max((syncLength + syncSlack), dataLength) + 1).W)
  )
  val valid = RegInit(false.B)

  val sync = RegNext(io.sync, (!polarity).B)

  def isStartEdge = sync =/= polarity.B && io.sync === polarity.B
  def isEndEdge = sync === polarity.B && io.sync =/= polarity.B

  def waitForSync() =
    when(isStartEdge) {
      counter := (syncLength + syncSlack).U
    }

  when(counter =/= 0.U) {
    counter := counter - 1.U

    when(valid === true.B) {
      when(counter === 1.U) {
        valid := false.B
        waitForSync()
      }
    }.elsewhen(isEndEdge) {
      when(counter >= 1.U && counter <= (1 + syncSlack * 2).U) {
        valid := true.B
        counter := dataLength.U
      }.otherwise {
        counter := 0.U
      }
    }
  }.otherwise {
    waitForSync()
  }

  io.address := (dataLength.U - counter)
  io.valid := valid
}
