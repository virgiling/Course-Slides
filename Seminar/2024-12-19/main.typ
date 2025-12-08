#import "@preview/cetz:0.2.2"
#import "@preview/fletcher:0.5.1" as fletcher: edge, node
#import "@preview/curryst:0.3.0": proof-tree, rule
#import "@preview/touying:0.5.2": *
#import "@preview/touying-buaa:0.2.0": *
#import "@preview/i-figured:0.2.4"
#import "@preview/pinit:0.2.2": *
#import "@preview/lovelace:0.3.0": *

#let colorize(svg, color) = {
  let blk = black.to-hex()
  // You might improve this prototypical detection.
  if svg.contains(blk) {
    // Just replace
    svg.replace(blk, color.to-hex())
  } else {
    // Explicitly state color
    svg.replace("<svg ", "<svg fill=\"" + color.to-hex() + "\" ")
  }
}

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
  font: ("Bookerly", "LXGW WenKai GB Screen"),

  // Basic information
  config-info(
    title: [Conflict Directed Lazy Decomposition],
    subtitle: [],
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

= TL;DR

在 SAT 问题的全局约束中，如果将约束编码为 SAT，会导致变量与子句的急速膨胀，造成求解困难。但有时候，编码的辅助变量又属于 nogood 类型的变量，能够指导搜索的过程。


因此本文提出了一种求解器框架称为 LD，在约束传播的过程中，我们有选择的分解（编码）#footnote[在后面统一将其称为分解] 那些 nogood 类型的变量，使得能够更快的求解问题。


= Global Constraints

我们这里以基数约束为例，PB 约束可以视为一种带加权的基数约束

#tblock(title: "基数约束")[
  考虑变量集合 $cal(X) = {x_1, x_2, dots, x_n}$，我们有如下约束：
  $
    x_1 + x_2 + dots + x_n \# K
  $
  其中，$K in RR, x_i in {0, 1}, \# in {lt.eq, gt.eq, eq}$
]

#pagebreak()

== 基数约束示例

#tblock(title: "哈密顿回路")[
  对于一个连通图 $G$，是否存在一个顶点访问顺序 $z = v_i dots v_k, v_(k+1) dots v_i$，使得我们能够访问所有顶点，且每个顶点恰好被访问一次，最终我们需要回到 $v_i$
]

一个简单的编码为，假设 $x_(i, j)$ 表示顶点 $v_j$ 出现在路径 $z$ 的第 $i$ 位，于是我们有：
$
  forall 1 lt.eq j lt.eq |V|, sum_(1 lt.eq i lt.eq |V|)x_(i, j) = 1 \
  forall 1 lt.eq i lt.eq |V|, sum_(1 lt.eq j lt.eq |V|)x_(i, j) = 1 \
  forall 1 lt.eq k lt.eq |V| - 1, not x_(k, i) or not x_(k+1, j), (i, j) in E
$

== 基数约束的求解

对于基数约束，我们常见的求解方法如下：

- Decomposition：编码为 SAT，直接使用 SAT 求解器进行求解
- Lazy Clause Generation：使用 SMT 方法进行求解，这里我们简称为约束传播

= Decomposition

我们考虑一个常用的编码 Cardinality Network

#tblock(title: "Cardinality Network")[
  此电路通过 $k$ 个 2-comparators 来构建的，一个比较算子的电路结构为 $"2-comp"(x_1, x_2, y_1, y_2)$，其中，$x_1, x_2$ 为输入，$y_1, y_2$ 为输出，满足以下约束：
  $
    y_1 = x_1 or x_2\
    y_2 = x_1 and x_2
  $
  一个 Cardinality Network 电路需要满足以下性质：

  - 为真的输出个数与为真的输入个数相同
  - 对任意 $1 lt.eq i lt.eq k$ ，当且仅当电路的输入至少有 $i$ 个为真时，第 $i$ 个输出才为真
]

#pagebreak()

显然，一个基数约束可以快速使用 Cardinality Network 来表达，例如 $x_1 + dots + x_4 gt.eq 3$，我们可以考虑一个 Cardinality Network 满足第 $3$ 个输出为真，如下图所示：

#align(center)[
  #image("fig/CardExample.png", width: 50%)
]

#pagebreak()

而一个 $"2-comp"(x_1, x_2, y_1, y_2)$ 可以快速的编码为 SAT 子句,对于 $gt.eq$ 约束而言:

$
  not x_1 or y_1 \
  not x_2 or y_1 \
  not x_1 or not x_2 or y_2
$

对于 $x_1 + dots + x_4 gt.eq 3$，我们将下图电路编码为 SAT 子句后，只需要最后加上一条单元子句，使得第 $3$ 个输出为真即可。

#align(center)[
  #image("fig/CardExample.png", width: 30%)
]

= Lazy Clause Generation

对于一个由公式 $F$ 与一个约束集合 $\{c_i\}$ 构成的约束满足问题，LCG 由两部分组成：
+ SAT 求解器
+ 每个约束 $c_i$ 的传播函数

SAT 求解器判定公式是否可满足并给出满足赋值，传播函数通过已决策的变量进行约束传播，在遇到冲突时，为 SAT 求解器提供证明归结

#pagebreak()

考虑以下例子：$not x_1 or x_2, x_3 or x_4, x_1 + x_2 + x_3 + x_4 lt.eq 2$，求解的框架如下：

#align(center)[
  #fletcher-diagram(
    node-stroke: .1em,
    node-fill: gradient.radial(blue.lighten(80%), blue, center: (30%, 20%), radius: 80%),
    spacing: 2.5em,
    node((0, 0), `SAT Solver`, radius: 2.5em),
    node((2, 0), `Propagator`, radius: 2.5em),
    edge((-1.5, 0), (0, 0), "--", [
      $
        not x_1 or x_2 \
        x_3 or x_4
      $
    ]),
    edge((2, 0), (6, 0), "--", [$x_1 + x_2 + x_3 + x_4 lt.eq 2$]),
    edge((0, 0), (2, 0), "-|>", [$x_1^d x_2^("bcp")$], bend: 40deg),
    edge((2, 0), (0, 0), "-|>", [$not x_3^p, not x_4^p$], bend: 40deg),
  )
]

随后，发现冲突，传播函数给出原因如下：

$
  not x_3 = not x_1 or not x_2 or not x_3 \
  not x_4 = not x_1 or not x_2 or not x_4
$

接着，我们给出归结如下：

#align(center)[
  #proof-tree(
    rule(
      $not x_1$,
      rule(
        $not x_1 or not x_2$,
        rule(
          $not x_1 or not x_2 or x_3$,
          $x_3 or x_4$,
          $not x_1 or not x_2 or not x_4$,
        ),
        $not x_1 or not x_2 or not x_3$,
      ),
      $not x_1 or x_2$,
    ),
  )
]

于是 SAT 求解器得到学习子句 $not x_1$

= Lazy Decomposition

分解与 LCG 各有其优势，考虑以下两种情况：

- 考虑一个由上百条基数约束构成的问题，如果我们将其分解为 SAT，会引入巨量的辅助变量与子句，使得求解效率急速降低，这个时候如果使用约束传播方法就会快很多
- 考虑一个基数约束 $sum_i x_i lt.eq K$ 的问题，但这个问题中的一些子句可以推导（归结）出以下约束 $sum_i x_i gt.eq K + 1$ ，使得问题直接变成 UNSAT，这个时候对于约束传播算法，我们无法快速找到矛盾，可能需要枚举所有可能的结果来证明问题是 UNSAT 的，但如果我们分解为 SAT 问题，我们甚至可以在预处理阶段就发现这个矛盾


#pagebreak()

#tblock(title: "基本假设")[
  对于每个问题，将其分解为 SAT 时都会产生一些有助于 SAT 求解的辅助变量以及另一部分加大求解难度的无用辅助变量
]

于是，我们期望如何在分解时只生成那些对 SAT 求解有帮助的辅助变量

== 框架

Lazy Decomposition 可以理解为是一个带探测机制的 LCG 求解器，约束传播的过程中，LD 需要去探测 nogood 变量，并将其编码为 SAT 子句

我们以基数约束中的懒编码为例，详细解释这个求解器是如何工作的。

== 基数约束中的 LD

考虑以下基数约束 $x_1 + x_2 + dots + x_n gt.eq K$，当我们采用 $"2-comp"(x_1, x_2, y_1, y_2)$ 将 $x_1, x_2$ 编码后，由于 $y_1 = x_1 or x_2, y_2 = x_1 and x_2$，于是有如下性质成立：

$
  x_1 + x_2 = y_1 + y_2
$

那么，我们可以将原基数约束进行改写为
$
  y_1 + y_2 + dots x_n gt.eq K
$

然后将其编码为 SAT 语句，相当于我们为 SAT 求解器引入了两个新变量 $y_1, y_2$

#pagebreak()

=== 示例

考虑一个 8 个变量的基数约束 $x_1 + dots x_8 lt.eq 3$，其电路图如下所示（如果完全编码为 SAT）：

#align(center)[
  #image("fig/LD-demo-1.png", width: 40%)
]

这时，如果我们只编码前两层的话，也就是只引入新变量 $z_1, dots, z_(12)$，就可以将基数约束写为$z_5 + z_6 + dots + z_(12) lt.eq 3$


== LD 的具体做法

为了提高效率，求解器仅在执行重启时才添加变量：重启发生得足够频繁，以确保生成重要变量不会太晚，但又不会过于频繁，以免显著影响求解器性能。

#tblock(title: "nogood")[
  在约束满足问题（CSP, Constraint Satisfaction Problem）中，nogood 是指一组变量的赋值组合，这些组合违反了问题中的一个或多个约束条件

  当求解器发现一个冲突（即当前的变量赋值违反了约束），它会回溯并生成一个 nogood，表示导致冲突的赋值组合。
]

#pagebreak()

传播函数为每个约束中的变量 $x_i$ 都维护了一个数值 $"act"_i$，
每当有一次 nogood 被生成时，包含在 nogood 中的所有变量的 $"act"_i$ 都会自增 $1$

当求解器重启时，传播函数的做法如下：

#import fletcher.shapes: diamond, rect

#align(center)[
  #fletcher-diagram(
    node-stroke: .5pt,
    edge-stroke: .5pt,
    node((0, 0), [$forall x_i in c_i$], corner-radius: 2pt, extrude: (0, 3)),
    edge("-|>"),
    node((1, 0), [$"act"_i gt.eq lambda N$], shape: diamond),
    edge("u,r,d", "-|>", [Yes], label-pos: 0.1),
    edge((1, 0), (1, 0.7), "-|>", [#text(size: .6em)[No]]),
    node((1, 0.7), [$"act"_i = "act_i"/2$]),
    edge((1, 0.7), (1, 1.3), "-|>"),
    node(
      (2, 0),
      [#text(size: .6em)[
        $x_i$ 为门 \
        $"2-comp"(x_i, x_j, y_i, y_j)$ \
        的输入
      ]],
      shape: diamond,
    ),
    edge((2, 0), (1, 1.3), "-|>", [No], bend: 40deg),
    edge((2, 0), (3.5, 0), "-|>", [Yes]),
    node(
      (3.5, 0),
      [#text(size: .6em)[
        $"2-comp"(x_i, x_j, y_i, y_j)$ \
        的 $x_j$ 已被生成
      ]],
      shape: diamond,
    ),
    edge("-|>", [Yes]),
    node((3.5, -0.7), [$y_i + y_j$ 替换 $x_i + x_j$]),
    node((3.5, 1), [生成 $x_j$]),
    edge("r,u,u,l,d", "-|>"),
    edge((3.5, 0), (3.5, 1), "-|>", [No]),
    node((1, 1.3), [Solver]),
  )
]

== LD 示例

考虑基数约束 $x_1 + dots +x_8 lt.eq 3$，在经过一些求解步骤后，现在的约束变为：$z_9 + z_17+z_18 + z_12+ z_5 + z_15 + z_7 + z_16 lt.eq 3$，具体电路图如下：

#align(center)[
  #image("fig/LD-demo-2.png", width: 40%)
]

此时，我们考虑一次重启

#pagebreak()

#grid(
  columns: 2,
  column-gutter: 1em,
  [
    假设 $"act"_12 gt.eq lambda N$，可以发现 $z_12$ 需要与 $z_16$ 组成一个 `2-comp`，并且 $z_16$ 已经被生成，于是我们直接生成一个 $"2-comp"(z_12, z_16, z_27, z_28$)，使用 $z_27 + z_28$ 替换 $z_12+ z_16$ ，并生成 SAT 子句：
    $
      not z_12 or not z_28 \
      not z_16 or not z_28 \
      z_12 or z_16 or not z_27or z_27 or z_28
    $
  ],
  align(center)[
    #image("fig/LD-demo-2.png")
  ],
)


#pagebreak()

#grid(
  columns: 2,
  column-gutter: 1em,
  [
    假设 $"act"_18 gt.eq lambda N$，但这时我们发现 $z_20$ 还没有被生成

    为构造门 `2-comp`($z_18, z_20, z_25, z_26$) ，我们需要先生成 $z_20$，

    由于生成 $z_20$ 需要生成 $z_14$，经过向上的 dfs，我们最终获得集合为 ${z_5, z_7, z_15 }$，最终，得到 $z_20$ 后，我们使用 $"2-comp"(z_18, z_20, z_25, z_26$)，将 $z_18$ 进行替换
  ],
  image("fig/LD-demo-3.png"),
)

= Experiment

Benchmark 选取大多为 SAT 问题带有一个基数约束形式的目标函数 $x_1 + dots + x_n$，我们的做法是：

1. 首先，SAT 会给出初始问题的赋值 $O$
2. 接着，我们迭代使得 $O = O - 1$，并在原有的子句约束上加入基数约束 $x_1 + dots + x_n lt.eq O$，直到在规定时间内找不到 SAT 的赋值

== Partial MaxSAT

数据来源于 MaxSAT Evaluation 2011，我们通过对所有软子句中加入一个新变量，将问题转化为 SAT 问题，并将目标函数设置为加入的新变量之和

#align(center)[
  #image("fig/part-maxsat.png", width: 60%)
]

== Discrete-Event System Diagnosis Suite

例子中含有一组 SAT 子句和一个很长的基数约束形式的目标函数

#align(center)[
  #image("fig/DES.png", width: 50%)
]

== MSU4

数据来源于 MaxSAT Evaluation 2011，使用 MSU4 可以将 Partial MaxSAT 问题转换为一组带有多个基数约束的 SAT 问题

#align(center)[
  #image("fig/MSU4.png", width: 60%)
]
