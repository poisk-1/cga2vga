package poisk2vga

import scala.collection.Seq

import chisel3._
import chisel3.tester._
import org.scalatest.flatspec.AnyFlatSpec

class CaptureSpec extends AnyFlatSpec with CaptureTester {
  it should behave like receiver(1, 0, 2, true)
  it should behave like receiver(1, 0, 2, false)
  it should behave like receiver(13, 1, 234, true)
  it should behave like receiver(13, 1, 234, false)
  it should behave like receiver(234, 13, 13, true)
  it should behave like receiver(234, 13, 13, false)
}

trait CaptureTester extends ChiselScalatestTester { this: AnyFlatSpec =>
  private def readAddressSeq(dut: Capture): Seq[BigInt] = {
    while (!dut.io.valid.peek().litToBoolean) dut.clock.step()

    Iterator
      .continually {
        val (valid, address) = (dut.io.valid.peek(), dut.io.address.peek())
        dut.clock.step()
        (valid, address)
      }
      .takeWhile(_._1.litToBoolean)
      .map(_._2.litValue)
      .toSeq
  }

  private def assertAddressSeq(dut: Capture, dataLength: Int) = assert(
    readAddressSeq(dut) == (0 until dataLength)
  )

  private def assertInvalid(dut: Capture, cycles: Int) = {
    for (_ <- 0 until cycles) {
      assert(dut.io.valid.peek().litValue == 0)
      dut.clock.step()
    }
  }

  private def writeSynqSeq(
      dut: Capture,
      syncLength: Int,
      dataLength: Int,
      polarity: Boolean
  ): Unit = {
    for (
      sync <- Seq
        .fill(syncLength)(polarity.B) ++ Seq.fill(dataLength)((!polarity).B)
    ) {
      dut.io.sync.poke(sync)
      dut.clock.step()
    }
  }

  def receiver(
      syncLength: Int,
      syncSlack: Int,
      dataLength: Int,
      polarity: Boolean,
      invalidCycles: Int = 600
  ): Unit = {
    behavior of s"capture(syncLength=$syncLength, syncSlack=$syncSlack, dataLength=$dataLength, polarity=$polarity)"

    it should "latch on sync" in {
      test(new Capture(syncLength, syncSlack, dataLength, polarity)) { dut =>
        parallel(
          {
            dut.io.sync.poke((!polarity).B)
            dut.clock.step()

            writeSynqSeq(dut, syncLength - syncSlack, dataLength, polarity)
            writeSynqSeq(dut, syncLength, dataLength, polarity)
            writeSynqSeq(dut, syncLength + syncSlack, dataLength, polarity)
          }, {
            assertAddressSeq(dut, dataLength)
            assertAddressSeq(dut, dataLength)
            assertAddressSeq(dut, dataLength)
            assertInvalid(dut, invalidCycles)
          }
        )
      }
    }

    it should "skip short and long sync" in {
      test(new Capture(syncLength, syncSlack, dataLength, polarity)) { dut =>
        parallel(
          {
            dut.io.sync.poke((!polarity).B)
            dut.clock.step()

            writeSynqSeq(dut, syncLength - (syncSlack + 1), dataLength, polarity)
            writeSynqSeq(dut, syncLength, dataLength, polarity)
            writeSynqSeq(dut, syncLength + (syncSlack + 1), dataLength, polarity)
          }, {
            assertAddressSeq(dut, dataLength)
            assertInvalid(dut, invalidCycles)
          }
        )
      }
    }

    it should "skip truncated data" in {
      test(new Capture(syncLength, syncSlack, dataLength, polarity)) { dut =>
        parallel(
          {
            dut.io.sync.poke((!polarity).B)
            dut.clock.step()

            writeSynqSeq(dut, syncLength - syncSlack, dataLength, polarity)
            writeSynqSeq(dut, syncLength, dataLength - 1, polarity)
            writeSynqSeq(dut, syncLength + syncSlack, dataLength, polarity)
          }, {
            assertAddressSeq(dut, dataLength)
            assertAddressSeq(dut, dataLength)
            assertInvalid(dut, invalidCycles)
          }
        )
      }
    }
  }
}
