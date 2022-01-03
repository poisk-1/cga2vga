# CGA to VGA converter

Converts RGBI/HSYNC/VSYNC TTL signal at 15 MHz pixel clock and 640 by 200 resolution to standard VGA. Protyped for [Arty A7-35](https://digilent.com/reference/programmable-logic/arty-a7/reference-manual?redirect=1).

## Build Top.v

    $ sbt run

## Run tests

    $ sbt test

## Vivado design

![Schematics](/doc/design.png)

## TODOs

- Capture alignment configurable with push buttons
- Support [Cmod A7-15T](https://digilent.com/reference/programmable-logic/cmod-a7/reference-manual) board
- Design PCB around CMOD A7