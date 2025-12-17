#import "@preview/cetz:0.2.2"
#import "@preview/curryst:0.3.0": proof-tree, rule
#import "@preview/touying:0.6.1": *
#import "@preview/touying-buaa:0.2.0": *
#import "@preview/i-figured:0.2.4"
#import "@preview/pinit:0.2.2": *
#import "@preview/lovelace:0.3.0": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: ellipse, triangle


#let pinit-highlight-equation-from(
  height: 2em,
  pos: bottom,
  fill: rgb(0, 180, 255),
  highlight-pins,
  point-pin,
  body,
) = {
  pinit-highlight(..highlight-pins, dy: -0.9em, fill: rgb(..fill.components().slice(0, -1), 40))
  pinit-point-from(
    fill: fill,
    pin-dx: 0em,
    pin-dy: if pos == bottom {
      0.5em
    } else {
      -0.9em
    },
    body-dx: 0pt,
    body-dy: if pos == bottom {
      -1.7em
    } else {
      -1.6em
    },
    offset-dx: 0em,
    offset-dy: if pos == bottom {
      0.8em + height
    } else {
      -0.6em - height
    },
    point-pin,
    rect(
      inset: 0.5em,
      stroke: (bottom: 0.12em + fill),
      {
        set text(fill: fill)
        body
      },
    ),
  )
}

// cetz and fletcher bindings for touying
#let cetz-canvas = touying-reducer.with(reduce: cetz.canvas, cover: cetz.draw.hide.with(bounds: true))
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)

#let argmax = math.op("arg max", limits: true)
#let argmin = math.op("arg min", limits: true)

// #show math.equation.where(block: true): i-figured.show-equation.with(
//   leading-zero: false
// )

#show: buaa-theme.with(
  // Lang and font configuration
  lang: "zh",
  font: ("Bookerly", "LXGW WenKai"),

  // Basic information
  config-info(
    title: [Problem Partitioning via Proof Prefixes],
    subtitle: [_Based on Cube&Conquer_],
    author: [凌典],
    date: datetime.today(),
    institution: [Northeast Normal University],
    logo: image(bytes(
      read("../template/fig/nenu-logo.svg").replace(
        black.to-hex(),
        white.to-hex(),
      ),
    )),
  ),
)

#title-slide()
