package poisk2vga

import scala.collection.Seq

import chisel3._
import chisel3.tester._
import org.scalatest.flatspec.AnyFlatSpec

class ReceiverSpec extends AnyFlatSpec with ReceiverTester {
  it should behave like receiver(true, 1, 2)
  it should behave like receiver(false, 1, 2)
  it should behave like receiver(true, 13, 234)
  it should behave like receiver(false, 13, 234)
  it should behave like receiver(true, 234, 13)
  it should behave like receiver(false, 234, 13)
}

trait ReceiverTester extends ChiselScalatestTester { this: AnyFlatSpec =>
  private def readAddressSeq(dut: Receiver): Seq[BigInt] = {
    while (dut.io.valid.peek().litValue == 0) dut.clock.step()

    Iterator
      .continually {
        val (valid, address) = (dut.io.valid.peek(), dut.io.address.peek())
        dut.clock.step()
        (valid, address)
      }
      .takeWhile { case (valid, _) => valid.litValue == 1 }
      .map(_._2.litValue)
      .toSeq
  }

  private def assertAddressSeq(dut: Receiver, dataLength: Int) = assert(
    readAddressSeq(dut) == (0 until dataLength)
  )

  private def assertInvalid(dut: Receiver, cycles: Int) = {
    for (_ <- 0 until cycles) {
      assert(dut.io.valid.peek().litValue == 0)
      dut.clock.step()
    }
  }

  private def writeSynqSeq(
      dut: Receiver,
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
      polarity: Boolean,
      syncLength: Int,
      dataLength: Int,
      invalidCycles: Int = 600
  ): Unit = {
    behavior of s"receiver(polarity=$polarity, syncLength=$syncLength, dataLength=$dataLength)"

    it should "latch on sync" in {
      test(new Receiver(syncLength, dataLength, polarity)) { dut =>
        parallel(
          {
            dut.io.sync.poke((!polarity).B)
            dut.clock.step()

            writeSynqSeq(dut, syncLength, dataLength, polarity)
            writeSynqSeq(dut, syncLength, dataLength, polarity)
            writeSynqSeq(dut, syncLength, dataLength, polarity)
          }, {
            assertAddressSeq(dut, dataLength)
            assertAddressSeq(dut, dataLength)
            assertAddressSeq(dut, dataLength)
            assertInvalid(dut, invalidCycles)
          }
        )
      }
    }

    it should "skip short sync" in {
      test(new Receiver(syncLength, dataLength, polarity)) { dut =>
        parallel(
          {
            dut.io.sync.poke((!polarity).B)
            dut.clock.step()

            writeSynqSeq(dut, syncLength - 1, dataLength, polarity)
            writeSynqSeq(dut, syncLength, dataLength, polarity)
            writeSynqSeq(dut, syncLength - 1, dataLength, polarity)
          }, {
            assertAddressSeq(dut, dataLength)
            assertInvalid(dut, invalidCycles)
          }
        )
      }
    }

    it should "skip long sync" in {
      test(new Receiver(syncLength, dataLength, polarity)) { dut =>
        parallel(
          {
            dut.io.sync.poke((!polarity).B)
            dut.clock.step()

            writeSynqSeq(dut, syncLength + 1, dataLength, polarity)
            writeSynqSeq(dut, syncLength, dataLength, polarity)
            writeSynqSeq(dut, syncLength + 1, dataLength, polarity)
          }, {
            assertAddressSeq(dut, dataLength)
            assertInvalid(dut, invalidCycles)
          }
        )
      }
    }

    it should "skip truncated data" in {
      test(new Receiver(syncLength, dataLength, polarity)) { dut =>
        parallel(
          {
            dut.io.sync.poke((!polarity).B)
            dut.clock.step()

            writeSynqSeq(dut, syncLength, dataLength, polarity)
            writeSynqSeq(dut, syncLength, dataLength - 1, polarity)
            writeSynqSeq(dut, syncLength, dataLength, polarity)
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
