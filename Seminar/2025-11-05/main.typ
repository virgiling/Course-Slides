#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/curryst:0.3.0": proof-tree, rule
#import "@preview/touying:0.5.2": *
#import "@preview/touying-buaa:0.2.0": *
#import "@preview/i-figured:0.2.4"
#import "@preview/pinit:0.2.2": *
#import "@preview/lovelace:0.3.0": *
#import "@preview/frame-it:1.2.0": *

#import fletcher.shapes: ellipse, triangle

#let (example, important, warning) = frames(
  important: ("Important", orange.lighten(60%)),
  warning: ("Warning",),
  example: ("Example", gray),
  // You can add as many as you want
)
// This is necessary. Don't forget this!
#show: frame-style(styles.thmbox)

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
    title: [An Overview of MallobSAT & PaInLeSS],
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

= Methods of Parallelization

现代 SAT 求解器的并行化方法主要分为两大类：

- _Divide&Conquer_（_Cube&Conque_）
- _Portfolio_

== Divide-and-Conquer

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

#pagebreak()

#tblock(title: "静态划分")[
  在原始 _Cube&Conquer_ 中，`cube` 是通过 `lookahead` 来识别一些较为重要的变量（即能快速剪枝的变量），作为划分序列 $(x_1, x_2, dots, x_i)$
]

#pause #tblock(title: "动态划分")[
  在求解过程中，我们通过子问题的 `difficulty` 大小，来动态的划分
]

#pause 然而，这种做法太依赖于选择变量的启发式策略

如果我们没有选好序列，会导致子问题都与原问题一样困难，从而无法获得良好的加速

#pagebreak()

在基于划分的并行方法中，我们通常采用 _Randomized Work Stealing_ 的方法来做负载均衡，如下图：

#grid(
  columns: (1fr, 10em),
  column-gutter: .5em,
  image("../2025-10-26/fig/work_stealing.png", height: 65%),
  [#pause 其中，$x_i$ 为 `Worker2` 通过自身启发式选择的划分变量（动态划分），注意，我们需要在第零层来处理划分],
)

== Portfolio Approach

#tblock(title: "Portfolio")[
  通过不同的求解器参数配置，使用 `nThreads` 个求解器，并行求解原问题
]

#grid(
  columns: (2fr, .5fr),
  [
    #pause
    _Portfolio_ 的核心思想在于 *_diversity_*，通过配置：

    - 不同的随机种子
    - 不同的初始相位
    - 不同的求解器参数
    - 甚至是不同的求解器（CaDiCaL，Kissat，MiniSAT etc.)

    _Portfolio_ 在实际使用中表现都优于 _Divide&Conque_ 方法
  ],
  diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    node((1, 1), shape: ellipse, width: 4cm, height: 7cm, "Search Space", name: <space>),
    node((.4, .5), $w_1$, fill: red.lighten(50%), name: <w1>),
    node((.5, 1.5), $w_2$, fill: blue.lighten(50%), name: <w2>),
    node((1.5, .8), $w_3$, fill: yellow.lighten(50%), name: <w3>),
    node((1.6, 1.2), $w_4$, fill: green.lighten(50%), name: <w4>),
    edge(<w1>, <space>, "->"),
    edge(<w2>, <space>, "->"),
    edge(<w3>, <space>, "->"),
    edge(<w4>, <space>, "->"),
  ),
)


== Hybrid Approach

#tblock(title: "Divide-and-Conquer of Portfolios")[
  对于划分出的一个子问题，我们使用多个求解器使用 _Portfolio_ 的方法进行求解
]

#pause
如下图所示：

#grid(
  columns: (1fr, .5fr),
  figure(
    image("fig/hybrid.png", height: 60%),
  ),
  [通过这样的混合，我们也可以使用划分中使用的 _Work Stealing_ 来达到负载均衡],
)

= Pre-Processing

_PaInLeSS_ (#strong[PA]rallel #strong[IN]stantiab#strong[LE] #strong[S]at #strong[S]olver) 及其分布式版本 _D-Painless_ 都引入了预处理技术#footnote[来源于 PRS ]来加速并行的求解。

#pause
- 等价文字替换（ELS）： 只在子句数量超过 150,000,000 时打开
#pause
- 归结检查（Resolution Check）：为 BVE 的增强版，当 $|s(x)| times |s(not x)| lt.eq |s(x)| + |s(not x)|$ 时，对含有 $x, not x$ 的所有子句做归结
#pause
- Fourier-Motzkin Elimination：处理基数约束
- 高斯消元：处理 XOR 门

= Lemma Sharing

#tblock(title: "学习子句共享 (Lemma Sharing)")[
  在实际求解中（不论是 _D&C_ 还是 _Portfolio_），我们都需要让线程之间共享优质的学习子句，以获取更好的性能。
]

#important[
  我们在这里只关注 _Portfolio_ 方法中的共享，因为在 _D&C_ 中共享是十分困难的（带有假设的子句无法共享，优质的单元子句难以找到）
]

#pause
1. 什么样的 Lemma 需要被分享
2. Lemma 需要共享给谁

== PaInLeSS

==== 什么样的 Lemma 需要被分享

我们一般通过 `length`、`lbd` 等条件进行过滤与约束（有时也考虑活跃度），_Painless_ 允许自定义策略

#pause
#grid(
  columns: (1.5fr, 1fr),
  [
    ```py
    class Lemma:
      def __lt__(self, other):
        if self.lbd == other.lbd:
          return str(self) < str(other)
        if self.length == other.length
          return self.lbd < other.lbd
        return self.length < other.length
    ```
  ],
  [
    + *长度*
    + *LDB*
    + *字典序*
    通过这个优先级进行 Lemma 质量的排序
  ],
)

我们过滤掉那些没有达到要求的 Lemma，例如 ldb > *ldb_limit* 的。

#pagebreak()

==== Lemma 需要共享给谁

几乎所有的并行 SAT 求解器都遵循 `All-to-All` 的原则：即在所有的 `Worker` 之间共享所有的 Lemma。

#important[
  注意， `Worker` 本身可以选择过滤掉一些不需要/无用的 Lemma
]

#pagebreak()

#grid(
  columns: (2fr, 1fr),
  column-gutter: .5em,
  figure(
    image("fig/painless.png", height: 80%),
  ),
  [
    - 使用 `Sharer` 的线程，其在本地内存维护了一个 *无锁* 的队列，用于存储全局的学习子句
    - 每 0.5s / 0.1s `Sharer` 激活一次共享，将自身的子句导入到每个 `Worker` 中
  ],
)

== PaInLeSS 实例（SAT25-Parallel-SAT-1st)

#grid(
  columns: (1.5fr, 1.5fr),
  figure(image("fig/painless-2025.png")),
  [
    - PRS 预处理
    - 初始解构造：通过遗传算法，构造一半的 `Worker` 初始解（另一半可以根据种群来选择相位）
    - Lemma Sharing：
      - 动态 LBD
      - 每隔 0.5s 激活一次导入子句（最多不超过 1500 个文字）
  ],
)

== MallobSAT

=== HordeSAT（Painless）

- $"worker"_i$ 将一组本地产生的 lemma 导出到一个固定大小为 $beta_0$ 的缓冲区 $"buff_exp"_i$
- 所有进程的缓冲区 $"buff_exp"_i$ 被连接起来，形成一个共享缓冲区 $frak(B)$（按照子句长度排序的多个桶）
- 每隔一定时间，$frak(B)$ 被广播到所有的 $"worker"_i$ 的 $"buff_imp"_i$ 中

#pause
=== Weakness

- *缓冲区未充分利用*：若 $"buff_exp"_i$ 未被补充满，那么相当于 $B$ 的很多空间被浪费，没有携带任何信息（动态 LBD 会导致初始阶段一些 Lemma 被丢弃）
#pause
- 重复 Lemma 问题：对于单元子句，HordeSat 从不进行重复项过滤
- 可扩展性瓶颈：$"nThreads" prop |B|$

#pagebreak()

#figure(
  image("../2025-10-26/fig/mallob_sharing.png", width: 85%),
)

这里每个节点是一个 `Worker`，通过二叉树通信，合并导出的 Lemma

#pause
规避了 “当某个 `Worker` 导出缓冲区没满时，无法导出足够优质的 Lemma，浪费了通信时间也没有得到任何收益”


== HordeSAT（Painless） Buffer

`Sharer` 的共享缓冲区 #pin(1)$frak(B)$#pin(2)
#pause

#pinit-highlight(1, 2)
#pinit-point-from(2, offset-dy: 5pt, body-dy: -5pt)[（按照子句长度排序的多个桶，每个桶是一个栈）]

#pause
缓冲区的设计存在以下缺陷：

- 为每个长度分配固定大小的空间非常低效。
- 新添加的子句会被丢弃，导致最终桶中不会保留最近产生的 Lemma

#pause
#line(length: 100%)
#grid(
  columns: (1fr, 1fr),
  diagram(
    node-stroke: 1pt,
    let (solver, buf, sharer) = ((0, 0), (1, 0), (2, 0)),
    node(solver, $W_i$),
    node(buf, $"buff_imp"_i$),
    node(sharer, $cal(S)$),
    edge(sharer, buf, "->", $"acquire lock"$, label-size: .9em, bend: -30deg),
    edge(buf, solver, "->", $"acquire lock"$, label-size: .9em, bend: +30deg),
  ),
  [
    #pause
    如果 $W_i$ 没有成功获取 $"buff_imp"_i$ 的锁（说明 `Sharer` 正在向里面写入），那么 $W_i$ 会在下一次尝试导入。

    但这会导致 $"buff_imp"_i$ 的增长，使得我们在处理导入 Lemma 耗费非常久
  ],
)

== MallobSAT Buffer

我们依然使用桶来描述 $frak(B)$，但每个桶我们不假定为固定容量
#pause
假定通过全局的预算 `budget` 来控制整个缓冲区 $frak(B)$ 的剩余容量，于是我们插入子句的算法如下：

#[
  #set text(.7em)
  #figure(
    kind: "algorithm",
    supplement: [Algorithm],
    pseudocode-list(
      booktabs: true,
      numbered-title: [导出 Lemma 到 `Sharer`],
    )[
      + lemma $arrow.l W_i$ exported
      + #line-label(<insert>) *if* $|"lemma"| lt.eq$ budget *then*
        + $frak(B) arrow.l frak(B) union "lemma"$
        + budget $arrow.l$ budget - $|"lemma"|$
      + *else*
        + #line-label(<drop>)*for* bucket *in* $frak(B)[| l > |"lemma"| |]$ *do*
          + $c^* arrow.l argmax_(l, "lbd") c, c in "bucket"$
        + $frak(B) arrow.l frak(B) - {c^*}$
        + budget $arrow.l$ budget + $|c^*|$
        + *goto* @insert
    ],
  )
]

== Lemma Fliter

=== HordeSAT（Painless）

导出/导入 Lemma 时，我们需要避免重复共享相同的 Lemma，因此需要引入过滤机制（单元子句除外）

AMQ（Approximate Membership Query），具体是通过 Bloom 过滤器，全局一个 $frak(F)_g$，每个 _Worker_ 一个 $frak(F)_i$

#grid(
  columns: (2fr, 1fr),
  [
    #pause
    #line(length: 100%)
    在导出时：
    - 产生一个 Lemma: $c$ 时，$frak(F)_i arrow.l frak(F)_i union {c}$
    - 在 $frak(F)_g$ 中查询 $c$ 是否存在，得到的为概率结果

    #pause
    在导入时
    - （分布式）$frak(F)_g$ 是否存在 $c$
    - $frak(F)_i$ 是否存在 $c$，不存在则导入 $frak(F)_i arrow.l frak(F)_i union {c}$
  ],
  [
    #important[
      Bloom 过滤器是一种概率性数据结构，它永远不会产生漏报，但有可能产生*误报*

      意味着过滤器错误地报告“某个子句已经存在于集合中”，而实际上该子句是全新的、从未被加入过的。
    ]
  ],
)

#pagebreak()

=== MallobSAT

- 由于我们在聚合子句时，已经完成了去重，因此这里并不需要 $frak(F)_g$

- 为单元子句引入 $cal(H)$（精确哈希集）来替代 AMQ

- #strike[#pin(3)带遗忘机制的过滤：每 X 秒，每个 $frak(F_i)$ 中随机“遗忘”一半的子句#pin(4)]
#pause
#pinit-highlight(3, 4)
#pinit-point-from(4)[
  #set text(.8em)
  实验结果显示效果较差
]

