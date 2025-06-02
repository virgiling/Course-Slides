#import "@preview/cetz:0.2.2"
#import "@preview/fletcher:0.5.1" as fletcher: node, edge
#import "@preview/curryst:0.3.0": rule, proof-tree
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

#let pinit-highlight-equation-from(height: 2em, pos: bottom, fill: rgb(0, 180, 255), highlight-pins, point-pin, body) = {
  pinit-highlight(..highlight-pins, dy: -0.9em, fill: rgb(..fill.components().slice(0, -1), 40))
  pinit-point-from(
    fill: fill, pin-dx: -0.6em, pin-dy: if pos == bottom { 0.5em } else { -0.9em }, body-dx: 0pt, body-dy: if pos == bottom { -1.7em } else { -1.6em }, offset-dx: 0em, offset-dy: if pos == bottom { 0.8em + height } else { -0.6em - height },
    point-pin,
    rect(
      inset: 0.5em,
      stroke: (bottom: 0.12em + fill),
      {
        set text(fill: fill)
        body
      }
    )
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
    title: [A Continuous-Local-Search Approach for Hybrid SAT Solving],
    subtitle: [],
    author: [凌典],
    date: datetime.today(),
    institution: [Northeast Normal University],
    logo: image.decode(colorize(read("../template/fig/nenu-logo.svg"), white))
  ),
)

#title-slide()

= Background and Motivation

== SAT Solving for Non-CNF

对于一些非 CNF 的约束，例如：

- 基数约束，例如 $x_1 + x_2 + dots.c + x_n gt.eq k$
- NAE 约束，指任意子句中至少有两个变量取值不同
- XOR 子句，例如 $x_1 xor x_2 xor dots.c xor x_n$

SAT 的求解方法主要分为两类：

- 编码为 CNF 后，使用 SAT 求解器求解
- 使用特定的拓展版 SAT 求解器

== Encoding for Non-CNF

编码会引入额外的变量和子句，导致 CNF 更加复杂，以基数约束为例：

#figure(
  table(
    columns: 4,
    table.header(
      [编码方法],
      [变量],
      [子句数],
      [文字数],
    ),

    [Sequential Counter], [1080], [2154], [5358],
    [Tree-based], [328], [1402], [3854],
    [Sort-based], [846], [1296], [3047],
  ),
  caption: [变量数为 $n = 66$，子句数 $m = 315$ 带基数约束的 SAT 编码],
)

== Extensions of SAT

#tblock(title: "CDCL-based SAT 求解器拓展")[
  - Pueblo（2006） 为引入求解 PB 约束 SAT 求解器
  - Cryptominisat（2009） 为引入求解 XOR 约束 SAT 求解器
  - Minicard（2012） 为引入求解基数约束 SAT 求解器
  - MonoSAT （2015）为加入了图性质的 SAT 求解器，可求解 NAE-SAT
]

可以发现，我们缺少一种通用的方法，可以求解非 CNF 约束的 SAT 问题

#pagebreak()

一种更加通用的方法是离散局部搜索（Discrete Local Search）

#tblock(title: "离散局部搜索")[
  考虑一个优化函数 $f_phi (x) = \# "constraints of formula" phi "satisfied by x"$

  我们的做法是:
  - 随机生成一个赋值 $x in {0, 1}^n$
  - 当存在不满足的子句时，我们通过打分函数来反转一个变量 $x_i$
]

其在 3-SAT 上的理论复杂度为 $O^*(1.33^n)$

#pagebreak()

那么，局部搜索算法是否能够用来求解 Non-CNF 约束的 SAT 问题

我们考虑以下例子：

#tblock(title: "基数约束使用局部搜索")[
  对于基数约束 $x_1 + x_2 + x_3 + x_4 gt.eq 2$，我们假定此时为 `UNSAT`，赋值为 $x = (0, 0, 0, 0)$

  可以发现，如果翻转一个变量（例如 $x_1$），我们的目标函数不会有任何的提高
]

因此，由于算法每次迭代都只会翻转一个变量，无法度量这样类似于过程的分数

= FourierSAT

== Continuous Local Search

于是，我们不能停留在离散局部搜索上：

#grid(
  columns: 2,
  [
    #image("fig/progress.png", width: 60%)
    #image("fig/flip.png", width: 60%)#footnote[
      https://www.youtube.com/watch?v=YsCxQ8LHRZY&t=495s
    ]
  ],
  [
    
    - 连续的目标函数比离散的超立方体更能度量优化的过程
    - 连续的优化过程在一次迭代时不止“翻转”一个变量
  ]
)

== Math Background

首先，我们引入一个定理：

#tblock(title: "Walsh-Fourier Transform")[
  对于一个布尔函数 $f: {-1, 1}^n arrow.r {-1, 1}$，这里 $-1 arrow.l.r top, 1 arrow.l.r bot$，一定存在一种方法将其表述为一个多线性多项式#footnote[一种多元多项式，其中每个变量都是线性的]，其至多含有 $2^n$ 项: $F(X) = sum_(S subset.eq [n]) hat(f)(S) times product_(i in S) x_i$，其中 $hat(f)(S) = 1/2^n  sum_(x in {-1, 1}^n) f(x) times product_(x_i in S) x_i$，称为 Walsh-Fourier 系数。
]

#pagebreak()

例如 $f(x_1, x_2) = x_1 and x_2$ 可以被写为：$F(x_1, x_2) = 1/2 + 1/2 x_1 + 1/2 x_2 - 1/2 x_1 x_2$，其计算过程如下(左侧中的集合表示哪些变量为真):

$
  mat(
    hat(f)(emptyset);
    hat(f)({x_1});
    hat(f)({x_2});
    hat(f)({x_1, x_2});
  ) = 
  mat(
    1/2;
    1/2;
    1/2;
    -1/2;
  ) = 1/2^2 #pin(1)mat(
    1, 1, 1, 1;
    1, -1, 1, -1;
    1, 1, -1, -1;
    1, -1, -1, 1;
  )#pin(2)
  times 
  #pin(3)mat(
    1;
    1;
    1;
    -1;
  )#pin(4)
$

#pinit-highlight-equation-from((1, 2), (1, 2), height: 2.5em, pos: bottom, fill: rgb(150, 90, 170))[
  Hadamard 矩阵 $H_2({-1, 1}^(2^n times 2^n))$
]

#pinit-highlight-equation-from((3, 4), (3, 4), height: 2.5em, pos: top, fill: rgb("#568fc5"))[
  $x_1 and x_2$ 的值
]

由于我们只需要知道 $f(X)$ 的所有取值即可进行计算，因此对于任意的约束我们都可以按照这样的法则进行展开。

#pagebreak()

对于 Hadamard 矩阵，其运算规则为：

$
  H_0 = 1\
  H_m = 1/sqrt(2) mat(
    H_(m-1), H_(m-1);
    H_(m-1), -H_(m-1);
  )
$

- 朴素计算的时间复杂度为 $O(2^n times 2^n)$

- 使用分治，计算此矩阵的时间复杂度为 $O(n times 2^n)$

== Transform to Continuous Function

考虑离散的优化函数 $f_phi (x) = \# "constraints of formula" phi "satisfied by x"$，我们将其转化为以下连续函数：

对于一个实数向量 $a in [-1, -1]^n$，我们在布尔向量 $x in {-1, 1}^n$ 上定义一个概率空间 $S_a$:

$
  S_a = cases(
    PP[x_i = top] = (1-a_i)/2,
    PP[x_i = bot] = (1+a_i)/2,
  )
$

于是，我们定义目标函数为 $F_phi (a) = EE_(x in S_a)[f_phi (x)] = sum_c PP_(x in S_a)[c(x) = top] =  sum_c "FE"_c (a)$

其中，$"FE"_c(a)$ 表示子句 $c$ 在 $a$ 取值下的 Fourier 展开。

== Optimization

对于 $f = (x_1 or x_2) and (not x_1 xor x_2)$，我们展开后得到 $F_phi = 1/4(1-x_1-x_2+x_1x_2) + 1/2 (1+x_1x_2)$

我们的做法是使用投影梯度下降（Projected Gradient Descent）来优化 $F_phi$

#pagebreak()

#image("fig/pgd.png")#footnote[
  Reference: https://www.youtube.com/watch?v=YsCxQ8LHRZY&t=495s
]

#pagebreak()

其算法流程如下：

#text(size: 0.7em)[
  #set align(center)
  #pseudocode-list[
  + *for* $j in [J]$ *do*
    + $x_0 tilde cal(U)[-1, 1]^n$
    + $t arrow.l 0$
    + *while* not converged *do*
      + $G(x_t) = 1/eta (x_t - product_([-1, 1]^n) x_t - eta dot.c nabla F(x_t))$
      + *if* $||G(x_t)||_2 gt 0$ *then*
        + $x_(t+1) arrow.l x_t - eta dot.c G(x_t)$
      + *else*
        + *if* $x_t$ is not feasible *then* 
          + $x_(t+1) arrow.l $ moving towards a negative direction 
        + *else* \# Meet a local optimal
          + *break*
]
]

== Experimental Results

在顶点覆盖问题（基数约束）上的实验表现如下，$n in {50, 100, 150, 200, 250}$，每种 $n$ 随机生成 100 个实例：

#image("fig/fourierSAT.png", width: 55%)

= GradSAT

- 增加 PB 约束的支持
- 引入动态约束加权
- BDD-based 信念传递来计算梯度
- 重启策略

= FastFourierSAT

- 快速傅立叶并行计算每一个子句的展开
