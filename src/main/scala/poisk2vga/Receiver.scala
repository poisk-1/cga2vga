package poisk2vga

import chisel3._
import chisel3.util.log2Ceil

class Receiver(
    syncLength: Int,
    dataLength: Int,
    polarity: Boolean
) extends Module {
  require(syncLength >= 1)
  require(dataLength >= 2)

  val io = IO(new Bundle {
    val sync = Input(Bool())
    val address = Output(UInt(log2Ceil(dataLength).W))
    val valid = Output(Bool())
  })

  val counter = RegInit(0.U(log2Ceil(syncLength + dataLength).W))
  val valid = RegInit(false.B)

  val futureSync = RegNext(RegNext(io.sync, polarity.B), polarity.B)
  val sync = RegNext(futureSync, polarity.B)

  def isStartEdge = sync =/= polarity.B && futureSync === polarity.B
  def isEndEdge = sync === polarity.B && futureSync =/= polarity.B

  def waitForSync() =
    when(isStartEdge) {
      counter := (syncLength + dataLength).U
    }

  when(counter =/= 0.U) {
    counter := counter - 1.U

    when(valid === true.B) {
      when(counter === 1.U) {
        valid := false.B
        waitForSync()
      }
    }.elsewhen(isEndEdge) {
      when(counter === (dataLength + 1).U) {
        valid := true.B
      }.otherwise {
        counter := 0.U
      }
    }
  }.otherwise {
    waitForSync()
  }

  io.address <> (dataLength.U - counter)
  io.valid <> valid
}
