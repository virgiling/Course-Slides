#import "@preview/cetz:0.2.2"
#import "@preview/fletcher:0.5.1" as fletcher: edge, node
#import "@preview/curryst:0.3.0": proof-tree, rule
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
    title: [The Impact of Literal Sorting on Cardinality Constraint Encodings],
    subtitle: [AAAI'25],
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

= 基数约束


#tblock(title: "基数约束定义")[
  考虑变量集合 $cal(X) = {x_1, x_2, dots, x_n}$, 我们将如下形式的约束称为基数约束:

  $
    x_1 + x_2 + dots + x_n sharp K
  $

  其中 $sharp in {gt.eq, lt.eq, eq}, x_i in {0, 1}, K in bb(N)$
]

值得注意的是，我们可以通过 $x_i + overline(x)_i = 1$ 将 $gt.eq, lt.eq$ 相互转化，而 $eq$ 可以通过 $gt.eq, lt.eq$ 进行夹逼。

= 编码方式

基数约束的编码方式主要有以下三种类型：

+ Sequential Counter
+ Tree-Based(Totalizer)
+ Sorting Network


我们通过 $x_1 + x_2 + x_3 + overline(x)_4 lt.eq 2$ 来解释这三种编码
这里，我们将 $x_i$ 称为数据文字，区别于我们引入的辅助变量及其对应的文字。

== Sequential Counter

我们通过下图所示的网格法来进行编码：

#grid(columns: 2, column-gutter: 1em)[
  #image("fig/seq.png", width: 70%)
  // #only(3)[
  //   #pin(1)$overline(y)_(4, 3) = overline(o)_3 = 1$#pin(2)
  //   #pinit-highlight(1, 2)
  // ]
][
  #only(1)[
    当且仅当前 $i$ 个数据文字*至少*有 $j$ 个为真时，$y_(i, j)$ 为真

    于是，$y_(n, j)$ 就表示该基数约束中至少有 $j$ 个文字为真，换而言之，如存在约束 $x_1+ x_2 + dots + x_n gt.eq K$，那么只需要保证 $y_(n, K)$ 为真即可。
  ]
  #only(2)[
    考虑上文的约束 $x_1 + x_2 + x_3 + overline(x_4) lt.eq 2$，在这种情况下，必然不能有 $K + 1$ 或更多的文字为真

    于是我们只需要约束 $y_(4, 3) = o_3$ 为假即可
  ]
  #only(3)[
    于是对于示例，我们只需要编码到 $o_3$ 即可，其依赖关系如下式所示：

    $
      y_(i+1, j) arrow.l y_(i, j) \
      y_(i, j+1) arrow.l (y_(i-1, j)and x_i)
    $

    我们的编码为增加以下子句：
    $
      overline(y)_(i, j) or y_(i+1, j) \
      overline(x)_(i+j) or overline(y)_(i, j) or y_(i, j+1)
    $
  ]
  #only(4)[
    显然，我们可以发现这种编码方式是不对称的：

    *$y_(i, j)$ 从左到右承载的信息量呈递增*

    例如 $y_(2, 1), y_(2, 2)$ 中有任一为真，我们都可以推断出 $x_1, x_2$ 的赋值信息

    然而我们找不到任何一个 $y_(i,j)$ 能够只辅助推理 $x_3, overline(x)_4$ 的赋值

  ]

]

== Totalizer

我们通过一棵二叉树来实现：

#grid(columns: 2, column-gutter: .8em)[
  #image("fig/tree.png", width: 60%)
][
  #only(1)[
    此二叉树在每一层都会计算为真的数据文字数。数据文字组成了二叉树的叶子，其他的节点为辅助变量，辅助变量的下标为其子节点下标的序数之和

    这里 $o_3 = 1$ 等价于 $l_1, r_2$ 或 $l_2, r_1$ 有一对均为真
  ]
  #only(2)[
    当约束为 $lt.eq$ 时，那么必然不能有 $K + 1$ 或更多的文字为真，于是只需要添加单元子句 $overline(o)_(K+1)$ 即可
  ]
  #only(3)[
    我们可以发现，*这种编码方式是对称的*

    因为我们可以通过辅助变量 $r_1, r_2$ 来推理出 $x_3, overline(x)_4$ 的赋值信息
  ]
  #only(4)[
    *如果文字在叶子节点相距的越远，统一其信息需要的树的深度就越多*

    例如 $x_1, overline(x)_4$ 只有在根节点才会共享一个辅助变量来统一其赋值信息
  ]
]

== Cardinality Network

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
  #image("../2024-12-19/fig/CardExample.png", width: 50%)
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
  #image("../2024-12-19/fig/CardExample.png", width: 35%)
]

#pagebreak()

我们的例子可以通过以下电路来编码：

#grid(columns: 2, column-gutter: 1em)[
  #image("fig/card.png", width: 80%)
  这里，我们只需要加入单元子句 $overline(o)_3$ 即可
][
  可以发现，这种网络结构虽然是对称的，*但其本质上也是排序敏感的*

  因为每次其通过门时，都是按照两两分组来实现的，那么分组的顺序或许就会显得十分重要。
]

= 文字排序方法

本文提供了几种排序方法来辅助上文中的编码，根据时间复杂度的从小到大，这些方法为：
+ `Natural`
+ `Random`
+ `Occur`
+ `Proximity`
+ `PAMO`
+ `Graph`

我们考虑的例子为：

$
  (x_1 or x_2) and (not x_1 or x_2) and (not x_2 or x_3 or x_4) and (not x_4 or x_5)\
  x_1 + x_2 + x_3 + not x_4 lt.eq 2
$

#pagebreak()

`Natural` 的方法最为简单，通过给定变量的编号直接进行排序，那么我们得到的基数约束为:
$
  x_1 + x_2 + x_3 + not x_4 lt.eq 2
$

#pause `Random` 的方法通过一个随机排列来对变量进行排序，纯粹的碰运气方法

#pause `Occur` 通过统计变量在子句中出现的次数（正负文字都统计），根据出现次数的递减顺序进行排序（因为 Sequential Counter 为这种不平衡提供了最多的推理能力，保证稠密的变量出现在前面，稀疏的在后面），那么我们得到的基数约束为
$
  x_2 + x_1 + not x_4 +x_3 lt.eq 2
$

#pagebreak()

`Proximity`/`PAMO` 是可以视为一种方法，`PAMO` 只是增加了一个组件

`Proximity`/`PAMO` 通过基数探测，从子句中探测出那些变量数大于等于 5 个的基数约束，我们将这些约束简称为 AMO。其工作流程可以视为一个 BFS，如下所述：
#pagebreak()

#grid(columns: (1fr, .75fr))[
  #text(size: .7em)[
    #figure(
      kind: "algorithm",
      supplement: [Algorithm],
      pseudocode-list(booktabs: true, numbered-title: [PAMO])[

        + *while* there exists $v in C$ have not been selected *do*
          + $v arrow.l$ variable with highest score in $C$
          + ording $arrow.l$ ording appending $v$
          + *if* AMO activated
            + *for* $c in$ AMO $and v in c$ *do*
              + *for* $v_i in c and v_i eq.not v$ *do*
                + $"score"(v_i) arrow.l "score"(v_i) + |c|^2$
          + *for* $c in$ clauses and $v in c$ *do*
            + *for* $v_i in c and v_i eq.not v$ *do*
              + $"score"(v_i) arrow.l "score"(v_i) + beta = cases(4 ", if"|c| = 2, 1/(|c|) ", otherwise")$
        + *end*
        + *return* ording
      ],
      caption: "PAMO",
    )
  ]
][
  单独使用 `Proximity` 后，我们得到的基数约束为
  $
    x_2 + x_1 + x_3 + not x_4 lt.eq 2
  $
]
#pagebreak()

`Graph` 通过变量为节点，是否在一条子句内为边构成的一张无向图，这里我们使用的社区检测的方法，找到那些合适的社区，我们会运行多次，找到不同的解，例如：

$
  S_1 = {C_(1, 1) = {x_1, x_3, x_5}, C_(1, 2) = {x_2, x_4}}\
  S_2 = {C_(2, 1) = {x_1, x_3, x_5}, C_(2, 2) = {x_2}, C_(2, 3) = {x_4}}\
  S_3 = {C_(3, 1) = {x_1, x_3}, C_(3, 2) = {x_2, x_5}, C_(3, 3) = {x_4}}
$

我们每次选择那些*具有更多数量的社区*（ $S_2, S_3$），
然后我们选择*社区平均大小最小*的解（ $S_3$），
最后，我们将那些出现在基数约束中的变量按照此社区中出现的顺序进行拼接，得到：

$
  x_1 + x_3 + x_2 + not x_4 lt.eq 2
$

= 实验

MaxSAT 很适合作为基数约束编码/求解的 benchmark：

#tblock(title: "MaxSAT 的基数约束")[
  我们通过对所有软子句中加入一个新变量，将问题转化为 SAT 问题，并将目标函数设置为加入的新变量之和

  此时，目标函数就是基数约束，我们将其转化为一个附有 $sum_i y_i lt.eq O$ 的 SAT 问题
]

#pagebreak()

表中的 `PAMO` + `Occur` 意思是对少于 100 万个子句的公式运行 `PAMO`，否则使用 `Occur` 排序

#align(center)[
  #image("fig/eval_maxsat.png", width: 60%)
]

#pagebreak()

接着，我们后面均使用基于 `Totalizer` 的改进版本来编码基数约束，然后进行 SAT 的求解, 其中 VBS 是理论最优求解器的结果

#align(center)[
  #image("fig/eval_sat.png", width: 50%)
]

#pagebreak()

#align(center)[
  #image("fig/eval_time.png", width: 45%)
]
