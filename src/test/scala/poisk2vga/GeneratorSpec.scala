package poisk2vga

import scala.collection.Seq

import chisel3._
import chisel3.tester._
import org.scalatest.flatspec.AnyFlatSpec

class GeneratorSpec extends AnyFlatSpec with GeneratorTester {
  it should behave like generator(1, 2, true)
  it should behave like generator(1, 2, false)
  it should behave like generator(13, 234, true)
  it should behave like generator(13, 234, false)
  it should behave like generator(234, 13, true)
  it should behave like generator(234, 13, false)
}

trait GeneratorTester extends ChiselScalatestTester { this: AnyFlatSpec =>
  private def readSeq(dut: Generator, length: Int): Seq[(Boolean, Boolean, BigInt)] = {
    for (_ <- 0 until length) yield {
      val x = (dut.io.sync.peek().litToBoolean, dut.io.valid.peek().litToBoolean, dut.io.address.peek().litValue)

      dut.clock.step()

      x
    }
  }

  private def assertSeq(dut: Generator, syncLength: Int, dataLength: Int, polarity: Boolean) = {
    val (syncSeq, dataSeq) = readSeq(dut, syncLength + dataLength).splitAt(syncLength)

    assert(syncSeq.forall(x => x._1 == polarity && !x._2))
    assert(dataSeq.filter(_._2).map(_._3).toSeq == (0 until dataLength))
  }

  def generator(
      syncLength: Int,
      dataLength: Int,
      polarity: Boolean
  ): Unit = {
    behavior of s"generator(syncLength=$syncLength, dataLength=$dataLength, polarity=$polarity)"

    it should "generate" in {
      test(new Generator(syncLength, dataLength, polarity)) { dut =>
        assertSeq(dut, syncLength, dataLength, polarity)
        assertSeq(dut, syncLength, dataLength, polarity)
        assertSeq(dut, syncLength, dataLength, polarity)
      }
    }
  }
}
