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
  font: ("Bookerly", "LXGW WenKai"),

  // Basic information
  config-info(
    title: [An Overview of Parallel SAT Solver],
    subtitle: [],
    author: [凌典],
    date: datetime.today(),
    institution: [Northeast Normal University],
    logo: image.decode(colorize(read("../template/fig/nenu-logo.svg"), white)),
  ),
)

#title-slide()

= Prelimitaries

== SAT 问题简介

#tblock(title: "可满足问题 (SAT)")[
  给定一个 CNF ：$cal(F)(x_1, x_2, dots, x_n)$，问是否存在一组赋值 $phi$ 使得 $cal(F) = 1$ 成立
]

其中 CNF 形式的布尔公式 $cal(F)$ 由若干子句 $C_1, C_2, dots, C_m$ 合取得到，每个子句又由若干文字 $l_i in {x_i, overline(x_i)}$ 析取构成。

== SAT 求解算法

现代 SAT 求解器的算法主流为 CDCL，通过子句学习以及非时序回溯（回跳）来获取良好的性能。比较重要的特性为：

+ 良好的启发式分支策略（EVSIDS + VMTF），以及相位选择策略
+ 学习子句管理
+ 重启策略（Luby 序列/自适应重启）
+ 优秀的预处理与简化技术
+ 与 Local-search 的集成

= Methods of Parallelization

现代 SAT 求解器的并行化方法主要分为两大类：

- _Divide&Conquer_（_Cube&Conque_）
- _Portfolio_

== Divide-and-Conquer

我们可以通过假定一组部分赋值，来将问题划分为不同的子问题，如下图所示：

#grid(
  columns: 2,
  column-gutter: 2em,
  image("fig/cube_and_conquer.png", height: 50%),
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
  image("fig/work_stealing.png", height: 65%),
  [#pause 其中，$x_i$ 为 `Worker2` 通过自身启发式选择的划分变量（动态划分）],
)

== Portfolio Approach

#tblock(title: "Portfolio")[
  通过不同的求解器参数配置，使用 `nThreads` 个求解器，并行求解原问题#footnote[与机器学习中 `boost` 方法类似]
]

#pause
_Portfolio_ 的核心思想在于 *_diversity_*，通过配置：

- 不同的随机种子
- 不同的初始相位
- 不同的求解器参数
- 甚至是不同的求解器（CaDiCaL，Kissat，MiniSAT etc.)

#pause
_Portfolio_ 在实际使用中表现都优于 _Divide&Conque_ 方法

= Lemma Sharing

#tblock(title: "学习子句共享")[
  在实际求解中（不论是 _D&C_ 还是 _Portfolio_），我们都需要让线程之间共享优质的学习子句，以获取更好的性能。
]

#pause

我们通过以下指标来判断 Lemma 的质量：

+ Lemma 的长度，越短的 Lemma 质量越好
+ LBD（子句中来自不同决策层的文字的个数），LBD 越小 Lemma 的质量越好

#pause

在导出时，我们设置 `lbd_limit` 来过滤那些质量较高的 lemma

且 `ldb_limit` 是自适应的，在多次无法导出 lemma 时增大，导出过多时减小

== Basic Approach

目前大多数的共享方式如下图所示

#figure(
  image("fig/lemma_sharing.png", height: 80%),
)

== Sharing in D&C Approach

对于任意 `worker`，假定此时得到了一条学习子句 $"lemma" = a or b or c$， 此时 `ldb_limit` 为 $3$

#pause
假定这个 Lemma 可以被导出，此 `worker` 遵循的假设为 $x_1 and x_2 and x_3$，那么我们需要导出的 Lemma 为：

$
  C = (not x_1 or not x_2 or not x_3) or (a or b or c)
$

可以发现这个子句的质量会比较差（随着假设的增多，lemma 长度变大）

== Sharing in Portfolio Approach

在 _Portfolio_ 中，由于每个 `Worker` 求解的问题都是原问题，因此不存在 Lemma Sharing 不可用的情况

- 过滤：我们依然通过 `ldb` 与 *长度* 来过滤出优质 Lemma，一般而言，优先选择 *长度短* 的 Lemma

- 导入时机：导入的越早越好，一般的做法为：
  + 在*重启* / 回溯到 *第零层* 时导入
  + 每隔 *一定冲突数* 触发导入（例如 400 次）
  + 每隔 *固定时间* 触发导入（例如 0.5s）

== MallobSAT 的共享

#figure(
  image("fig/mallob_sharing.png", width: 85%),
)

这里每个节点是一个 `Worker`，通过二叉树通信，合并导出的 Lemma

#pause
规避了 “当某个 `Worker` 导出缓冲区没满时，无法导出足够优质的 Lemma，浪费了通信时间也没有得到任何收益”

= Lemma Sharing on GPU

考虑给定的一个 `Worker` 以及 Lemma 的共享池 `Sharer`

给定一个子句 $c in "Sharer" and c in.not "Worker"$，我们认为：当 $exists l_t "is not assigned" top, forall l_i in c$，此时 $c$ 必须立刻加入到 `Worker` 中

#pause
因为 $c$ 可以作为单元子句/冲突子句进行剪枝，对搜索空间的缩小有益

#pagebreak()

于是，我们考虑以下函数：

```python
def assignment_trigger(assignment: list[list], lemma):
  all_false = [1 for _ in range(k)]
  one_unknown = [0 for _ in range(k)]
  for l in lemma:
    one_unknown = (all_false & assignment[l] == 0) | (one_unknown & assignment[l] == -1)
    all_false = all_false & assignment[l] == -1
  return (res = all_false | one_unknown)
```

其中 `assignment` 为一个 $k times n$ 的数组，`assignment[i]` 表示 `Worker[i]` 的赋值

#pause
我们返回的向量 `res[i]` 表示子句 $c$ 需要导出给 `Worker[i]`


