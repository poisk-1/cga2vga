# CGA to VGA converter

Converts RGBI/HSYNC/VSYNC TTL signal at 15 MHz pixel clock and 640 by 200 resolution to standard VGA. Prototyped on [Arty A7-35T](https://digilent.com/reference/programmable-logic/arty-a7/reference-manual?redirect=1). Production on [Cmod A7-15T](https://digilent.com/reference/programmable-logic/cmod-a7/reference-manual) board.

## Build Top.v

    $ sbt run

## Run tests

    $ sbt test

## Vivado design for Cmod A7-15T

![Schematics](/doc/design.png)

## TODOs

- Capture alignment configurable with push buttons;
- Design PCB around Cmod A7.