#import "@preview/cetz:0.2.2"
#import "@preview/curryst:0.3.0": proof-tree, rule
#import "@preview/touying:0.5.2": *
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

= Preliminaries

== Cube & Conquer


我们可以通过假定一组部分赋值，来将问题划分为不同的子问题，如下图所示：

#grid(
  columns: 2,
  column-gutter: 2em,
  figure(
    diagram(
      node-stroke: 1pt,
      cell-size: .5em,
      node-shape: "circle",
      label-size: .7em,
      let (root, x11, x12, x21, x22, x23, x24) = (
        (3, 0),
        (2, 1),
        (4, 1),
        (1.5, 2),
        (2.5, 2),
        (3.5, 2),
        (4.5, 2),
      ),
      node(root, ""),
      node(x11, ""),
      node(x12, ""),
      node(x21, ""),
      node(x22, ""),
      node(x23, ""),
      node(x24, ""),
      node((1.5, 2.9), $cal(S)_1$, shape: triangle.with(aspect: .6), fill: red.lighten(50%)),
      node((2.5, 2.9), $cal(S)_2$, shape: triangle.with(aspect: .6), fill: blue.lighten(50%)),
      node((3.5, 2.9), $cal(S)_3$, shape: triangle.with(aspect: .6), fill: green.lighten(50%)),
      node((4.5, 2.9), $cal(S)_4$, shape: triangle.with(aspect: .6), fill: yellow.lighten(50%)),
      edge(root, x11, $x_1$),
      edge(root, x12, $not x_1$),
      edge(x11, x21, $x_2$),
      edge(x11, x22, $not x_2$),
      edge(x12, x23, $x_2$),
      edge(x12, x24, $not x_2$),
    ),
  ),
  [
    我们通过假定赋值，将原问题 $cal(F)$ 划分为四个子问题:
    - $S_1 = cal(F) and (x_1) and (x_2)$
    - $S_2 = cal(F) and (x_1) and (not x_2)$
    - $S_3 = cal(F) and (not x_1) and (x_2)$
    - $S_4 = cal(F) and (not x_1) and (not x_2)$

    其中，我们添加的假设被称为 `cube`

    #pause 通过划分子问题后，我们使用多个线程去分别求解这些子问题，直到有一个找到 SAT / 所有线程都 UNSAT
  ],
)

== Clause Proof

#tblock(title: "子句证明")[
  子句证明是 CNF 的证明序列，用于说明 UNSAT 为什么 UNSAT，通过不断对证明序列的子句做归结，能够导出空子句 $bot$ 从而证明 UNSAT。
]

#pause 例如对于问题 $cal(F) = c_1 and c_2 and c_3 = (x_1 or x_2) and (not x_1) and (not x_2)$，导出的证明为： $1, 2, 3$，对这三条子句做归结，得到 $bot$

#pause 导出的证明子句可能是学习子句，也可能是原公式的子句，我们称学习子句为 *冗余子句*，意为删除此子句对公式的可满足性不产生任何影响。

= Parallelization via Proof Prefixes

== Proof Prefixes

#tblock(title: "证明前缀")[
  我们假定证明是一组，那么证明前缀（Proof Prefixes）是指从证明起始处开始的一系列子句添加步骤序列。
]

#pause _Cube & Conquer_ 的一个重要前提是如何找到一个良好的划分

我们通过实验，发现以下事实：

#pagebreak()

#grid(
  columns: (2fr, .4fr),
  column-gutter: 0em,
  figure(
    image("./fig/proof-prefix-in-eval.png", width: 60%),
  ),
  [
    #pause 变量在证明前缀的子句中出现的次数
  ],
)

#meanwhile
- 在非平凡（包含足够多步骤）的证明前缀中频繁出现的变量，往往会在证明后续部分持续高频出现
- 对于已知存在有效划分的问题而言，划分变量通常在原始公式生成的证明中具有较高出现频率

== Partitioning

#tblock(title: "传统划分")[
  首先，给定一组划分集合 $S = {x_1, x_2, dots, x_d}$ ，我们下一步是确定第 $d+1$ 个划分的变量是谁。
]

#pause 然而这样我们会生成 $2^d$ 个子问题，意味着我们需要找到 $2^d$ 个非平凡证明前缀，效率太低。

#pagebreak()

#figure(
  image("./fig/partition.png", width: 80%),
)

对于这 $2^d$ 个子问题，我们随机采样 $s$ 个子问题出来，对这 $s$ 个子问题进行证明前缀的生成，然后#pin(1)统计并得出第 $d+1$ 个变量#pin(2)。

#pause #pinit-highlight(1, 2)
#pinit-point-from(2, pin-dy: 40pt, body-dy: -50pt)[
  #text(size: .7em, fill: blue.lighten(20%))[
    需要统计所有 sample 子问题的证明前缀后选择

    仅生成 100000 个证明前缀
  ]
]

= Cardinality Splitting

== Totalizer

考虑 Totalizer 编码基数约束 $x_1 + x_2 + x_3 + x_4 gt.eq 2$：

#figure(
  diagram(
    spacing: 2em,
    let (x1, x2, x3, x4, y1, y2, z1) = (
      (1, 3),
      (3, 3),
      (5, 3),
      (7, 3),
      (2, 2),
      (6, 2),
      (4, 1),
    ),
    node(x1, $x_1$),
    node(x2, $x_2$),
    node(x3, $x_3$),
    node(x4, $x_4$),
    node(y1, $b_1^1, b_2^1$),
    node(y2, $b_1^2, b_2^2$),
    node(z1)[$o_1,$ #text(fill: red, $o_2$)  $,o_3, o_4$],
    edge(x1, y1),
    edge(x2, y1),
    edge(x3, y2),
    edge(x4, y2),
    edge(y1, z1),
    edge(y2, z1),
  ),
)

== Splitting

#grid(
  columns: (2fr, 1fr),
  column-gutter: 0pt,
  figure(
    image("fig/splitting.png", width: 100%),
  ),
  [
    #set text(size: 0.8em)
    编码基数约束 $l_1 + l_(16) lt.eq 7$，附加单元子句 $not o_8$

    辅助变量遵循 $c_"cnt"^("dep", "id")$ 的命名方式

    #pause #text(fill: red.darken(20%))[
      若 $c_4^(1, 1) = top$，那么有：

      $
            l_1 + dots +l_8 & gt.eq 4 \
        l_9 + dots + l_(16) & lt.eq 3
      $
    ]
    #pause #text(fill: blue.lighten(20%))[
      若 $c_4^(1, 1) = bot$，那么有：
      $
        l_1 + dots +l_8 & lt.eq 3
      $
    ]

    #pause 因此，对辅助变量进行赋值 $arrow.double.l.r$ 对基数约束做分解
  ],
)

#pagebreak()

#grid(
  columns: (2fr, 1fr),
  column-gutter: 0pt,
  figure(
    image("fig/splitting.png", width: 100%),
  ),
  [
    #set text(size: 0.8em)
    辅助变量的选择十分重要，选择不当会出现极其不平衡的子问题

    #pause #text(fill: red.darken(20%))[
      令 $c_7^(1, 1) = top$，则产生子问题为：
      $
        l_9 + dots + l_16 lt.eq 0 \
        l_1 + dots + l_7 lt.eq 7
      $

      从而得到一个非常容易的子问题，基本上不属于良好的划分
    ]
  ],
)

#pagebreak()

我们基于 $italic("Rk")$ 来进行全局基数约束的分解，防止选择到不平衡的辅助变量。

对于度为 k ，包含 s 个变量的基数约束 $sum^s_i x_i lt.eq k$，在二叉树的第 $L$ 层，假定该层的每个节点均包含 $n$ 个计数器，首先定义下列指标：

$
  italic("Rk") & = k/s \
  italic("id") & = floor.l italic("Rk") times n floor.r
$

其中 $italic("id")$ 来指明，到底选这一层的哪个计数器。

#pagebreak()

算法如下所示：

#box(width: 100%)[
  #figure(
    pseudocode-list(
      title: [Totalizer Based Splitting],
      booktabs: true,
    )[
      + 首先计算全局比率 $italic("Rk")$
      + $phi_S = emptyset$
      + *while* $|phi_S| eq.not italic("cutoff")$ *do*
        + $italic("node") arrow.l$ 当前层 $L$ 的第 $i$ 个节点（包含 $n$ 个计数器）
        + $italic("id") arrow.l floor.l italic("Rk") times n floor.r$ 计算计数器索引
        + *if* $i mod 2 equiv 1$ *then* $id arrow.l id + 1$
        + $c_L^(L, i) = italic("id")$
        + *if* $i mod 2 equiv 0$ *then* $L arrow.l L + 1$
    ],
  )
]

#pagebreak()

#grid(
  columns: (2fr, 1fr),
  column-gutter: 0pt,
  figure(
    image("fig/splitting.png", width: 100%),
  ),
  [
    #set text(size: 0.8em)
    考虑图中，Rk= $7/16$，假定我们现在想要 6 个划分变量，那么我们从第 $1$ 层开始往下找

    #pause 在第 1 层的第 1 个节点，其含有 8 个计数器，那么我们拿到的划分变量为 $c_(7/16 + 1)^(1, 1)$，即为 $c_4^(1, 1)$

    #pause 第 1 层的第 2 个节点，其含有 8 个计数器，那么拿到的为 $c_3^(1, 1)$
  ],
)

= Experimental Evaluation

== MaxSAT 23 Unweight

#figure(
  image("fig/maxsat-eval.png", width: 90%),
)

仅选取了 UNSAT 实例，且为每种类型中最难求解的问题

== SAT 22/23/24

#figure(
  image("fig/sat-comp.png", fit: "cover", height: 90%),
)
