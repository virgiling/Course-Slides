#import "@preview/cetz:0.2.2"
#import "@preview/fletcher:0.5.1" as fletcher: edge, node
#import "@preview/curryst:0.3.0": proof-tree, rule
#import "@preview/touying:0.5.2": *
#import "@preview/touying-buaa:0.2.0": *
#import "@preview/i-figured:0.2.4"
#import "@preview/pinit:0.2.2": *
#import "@preview/lovelace:0.3.0": *
#import "@preview/physica:0.9.4": *
#import "@preview/mitex:0.2.4": *

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

#set math.mat(delim: "[")

#show: buaa-theme.with(
  // Lang and font configuration
  lang: "zh",
  font: ("Bookerly", "LXGW WenKai"),

  // Basic information
  config-info(
    title: [A Quantum Approximate Optimization Algorithm],
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

= 数理基础

#tblock(title: "量子(Quantum)")[
  量子是物理学中的一个基本概念，指的是物理量的最小不可分割的基本单位，例如电子就属于量子。
]

这里我们可以暴力的将电子作为量子来讨论问题， 电子存在能级的概念， 也就是说， 电子在固定的轨道上运动， 轨道之间存在着能量的鸿沟。

当电子获得了来自原子外的能量时，它就有可能克服能级之间能量的差距，跳跃到另外一个态上面(也就是从基态跃迁到激发态)

#pagebreak()

#tblock(title: "态矢 (State Vector)")[
  量子态#footnote[量子，量子态，态，纯态在量子计算中是一个意思]，在量子理论中，描述量子态的向量称为态矢，态矢分为左矢（bra）和右矢（ket），我们用狄拉克符号来表示：
  $
    ket(psi) = [c_1, c_2, dots, c_n]^T\
    bra(psi) = [c_1^*, c_2^*, dots, c_n^*]
  $
  其中，矢态中的分量均为复数，且相同描述的左右矢，其互为转置共轭
]

根据上面所说的基态与激发态，我们可以仿照经典计算机中比特的定义，定义量子比特如下

#pagebreak()

#tblock(title: "量子比特 (qubit)")[
  经典比特的取值为 1 或 0，由二极管的通电断电实现，量子比特的取值是二维复空间 $CC^2$ 上的向量，我们将其规定为：
  $
    ket(0) = [1, 0]^T\
    ket(1) = [0, 1]^T
  $
]
物理上，实现基元 $ket(0), ket(1)$ 有多种方案，例如电子的自旋：

- $ket(0) = ket(arrow.t)$ 为上旋
- $ket(1) = ket(arrow.b)$ 为下旋

#pagebreak()

#tblock(title: "量子叠加")[
  考虑一个著名的思想实验：薛定谔的猫

  _把一只猫、一个装有毒气的玻璃烧瓶和一个有 50% 几率衰变的原子。当盒子内的监控器侦测到衰变粒子时，就会打破烧瓶，杀死这只猫。_

  薛定谔告诉我们，在量子的世界中，如果我们不打开盒子，那么这只猫处于处于生和死的“叠加态”
]

#tblock(title: "测量与坍缩")[
  对于这只半死半活的猫，当我们打开盒子，经过了我们的观察，猫就会坍塌到一个确定的生或着死的唯一的状态上
]

一旦测量，量子会立刻坍缩到某一个状态上，而不再处于状态的叠加

#pagebreak()

#tblock(title: "量子比特 (qubit)")[
  任意一个量子比特 $ket(psi)$ 我们可以写为如下形式：
  $
    ket(psi) = alpha ket(0) + beta ket(1)
  $
  其中，$alpha, beta in CC$ 且 $|alpha|^2 + |beta|^2 = 1$

  这里的 $|alpha|$ 表示复数的模， $|alpha|^2, |beta|^2$ 表示这个量子比特坍缩到 $ket(0), ket(1)$ 的概率
]

#pagebreak()

#tblock(title: "测量")[
  对于一个量子比特，我们无法测量 $alpha, beta$ 的具体值，我们只能通过测量来获取量子比特的可观测的信息
]

哈密顿量 $H$ 就是一个可观测量，对应于系统的总能量，哈密顿量的谱为测量系统总能是所有可能结果的集合

#pagebreak()

每次观测遵循以下规则 (以哈密顿量为例)：

- 对 $H$ 做谱分解 $H = sum^n_(i=1)lambda_i ket(psi_i) bra(psi_i)$，得到正交基 ${ket(psi_i)}^n_(i=1)$

- 对 $ket(psi)$ 做正交分解 $ket(psi) = sum^n_(i=1)c_i ket(psi_i)$，于是 $ket(psi)$ 为这 $n$ 个状态的叠加态

哈密顿量的每次观测每次测量结果为特征值 $lambda_i$ 中的一个，且得到 $lambda_i$ 的概率为 $|c_i|^2$，测量后，量子态坍塌为 $ket(psi_i)$

我们记 $expval(H)$ 表示哈密顿量的测量结果的期望值，可以证明$expval(H) = expval(H, psi)$

#pagebreak()

#tblock(title: "演化")[
  量子态是随着时间改变的，纯态由波函数 $psi(t)$ 来描述，随时间的变化规律遵从薛定谔方程：
  $
    i hbar (partial ket(psi)) / (partial t) = (-hbar / (2m) nabla^2 + V) ket(psi) = H ket(psi)
  $
  $H$ 表示哈密顿算子（哈密顿量），当其随时间改变时，方程的解为#footnote[这里的 $cal(T)$ 表示时间演化算符]：
  $
    ket(psi(t)) = cal(T)exp((-i)/hbar integral_0^t H(t)dd(t))ket(psi(0))
  $
]

#pagebreak()

对于一个封闭的量子系统，其演化过程我们使用酉变换来描述

具体而言，在 $t_1$ 时刻系统处于量子态 $psi(t_1)$，经过一个和时间 $t_1, t_2$ 相关的酉变换 $U(t)$，系统在 $t_2$ 时刻的状态为 $ket(psi(t_2)) = U(t)ket(psi(t_1))$

其中，酉变换 $U$ 是一个矩阵，并且满足 $U U^dagger = I$

于是：

$
  ket(psi(t)) & = cal(T)exp((-i)/hbar integral_0^t H(t)dd(t))ket(psi(0)) \
              & = U(t)ket(psi(0))
$

#pagebreak()

在量子计算中，各种形式的酉变换被称为量子门，例如最经典的泡利 X 门：
$
  sigma_1 = sigma_x = X = mat(0, 1; 1, 0)
$

其作用在量子比特 $ket(psi) = alpha ket(0) + beta ket(1)$ 上的效果如下：

$
  X ket(psi) = mat(0, 1; 1, 0) mat(alpha; beta) = mat(beta; alpha)
$

经典比特门中的非门效果一致：$X ket(0) = ket(1), X ket(1) = ket(0)$

#pagebreak()

#tblock(title: "多比特系统")[
  对于存在两个及以上的量子比特系统，我们将其称为复合系统，其通过张量积进行构造。
]

张量积是两个向量空间形成一个更大向量空间的运算。在量子力学中，量子的状态由希尔伯特空间中的单位向量来描述。

假设 $cal(H)_1, cal(H)_2$ 分别为 $n_1, n_2$ 维的希尔伯特空间，$cal(H)_1$ 与 $cal(H)_2$ 的张量积表示一个 $n_1 times n_2$ 维的希尔伯特空间，我们用 $cal(H)_1 times.circle cal(H)_2$ 来表示

#pagebreak()

我们以一个例子来说明其运算规则：

#mimath(
  `
\begin{bmatrix}
1 & 2 & 3 \\
4 & 5 & 6
\end{bmatrix}
\otimes
\begin{bmatrix}
b_{11} & b_{12} \\
b_{21} & b_{22}
\end{bmatrix}
= \begin{bmatrix}
b_{11} & b_{21} &\textbar& 2b_{11} & 2b_{12} &\textbar& 3b_{11} & 3b_{12} \\
b_{21} & b_{22} &\textbar& 2b_{21} & 2b_{22} &\textbar& 3b_{21} & 3b_{22} \\
\\
4b_{11} & 4b_{21} &\textbar& 5b_{11} & 5b_{12} &\textbar& 6b_{11} & 6b_{12} \\
4b_{21} & 4b_{22} &\textbar& 5b_{21} & 5b_{22} &\textbar& 6b_{21} & 6b_{22} \\
\end{bmatrix}
  `,
)

对于上文中的狄拉克符号（纯态单量子），我们将其表示为：

$
  ket(psi) times.circle ket(phi) = ket(psi phi) = mat(alpha_1 beta_1; alpha_1 beta_2; alpha_2 beta_1; alpha_2 beta_2)
$

= 量子计算原理

经典计算中，最基本的单元是比特，而最基本的控制模式是逻辑门，可以通过逻辑门的组合来达到控制电路的目的。

类似地，处理量子比特的方式就是量子逻辑门，使用量子逻辑门，有意识的使量子态发生演化，所以量子逻辑门是构成量子算法的基础。

#pagebreak()

#tblock(title: "Problem-inspired ansatz")[
  假定当前问题的哈密顿量为 $H$，目标是寻找这个哈密顿量的基态，我们将损失函数定义为：
  $
    cal(C(theta)) = expval(H) = expval(H, psi(theta))
  $
  其中， $ket(psi(theta)) = U(theta) ket(psi_0)$
]

其中，$U(theta)$ 为我们需要生成的量子线路

哈密顿量 $H$ 的谱为测量系统总能是所有可能结果的集合，于是，我们找到使得问题哈密顿量最小的那个 $theta$，即可测量得到最终的量子态 $ket(psi(theta))$ 会坍缩到哪个状态上。

= QAOA

== 概览

任意一个组合优化问题都可以被编码为 MAX-SAT 的形式（$n$ 个变量，$m$ 条子句），并使用这 $n$ 个 0-1 变量定义一个目标函数：

$
  C(z) = sum^m_(alpha=1)C_(alpha)(z)
$

其中，$z = z_1z_2 dots z_n$，为一个比特串，$C_(alpha)(z)$ 表示第 $alpha$ 条子句是否满足

对于一个量子计算机，其运行在一个 $2^n$ 维的希尔伯特空间内，我们需要求得的比特串为 $ket(z)$，使得 $C(z)$ 最大

== 绝热量子计算

#tblock(title: "绝热定理")[
  对于一个含时但演化足够慢($T arrow infinity$)的物理系统，若系统的初始时刻处于一能量本征态 $ket(psi(0))$ ，那么在 $t$ 时刻将处于 $H(t)$ 相应的瞬时本征态 $ket(psi(t))$ 上
]

那么，我们构建一个含时的哈密顿量演化过程 $H_B arrow.r H_P$ 如下:

$
  hat(H) = H(t) = (1 - s(t)) H_B + s(t) H_P, \
  s(0) = 0, s(T) = 1
$

其中 $H_B = - sum_i sigma^x_i$，其对应的本征态为 $ket(psi(0)) = product_i ket(+)$，注意这里的 $product_i ket(+)$ 表示张量积 $ket(+) times.circle ket(+) times.circle dots$

#pagebreak()

$
  H(t) = (1 - s(t)) H_B + s(t) H_P, \
  s(0) = 0, s(T) = 1
$

注意，我们需要系统演化的足够缓慢，于是我们考虑细分：
$
  H(t) = product^p_j ( (1 - s(j Delta t))H_B + s(j Delta t)H_P)Delta t
$

#pagebreak()

本质上，我们相当于演化了 $p$ 次，每次的时间为 $Delta t$，我们可以通过以下等式求得经过 $p$ 次演化的本征态 $ket(psi)$ ：

$
  ket(psi) = product_i U_i ket(psi(0))
$

其中 $U_i$ 是一个酉变化，根据上面提到的哈密顿量演化过程，我们可以将其写为如下形式：

#mitex(
  `
\ket{\psi} = \prod^p_{j=1} \exp \Bigg(-i \bigg( (1 - s(j\Delta t))H_B + s(j\Delta t)H_P \bigg)\Delta t \Bigg)\ket{\psi_0}
`,
)

#pagebreak()

#grid(
  columns: 2,
  column-gutter: 4em,
  [
    #set text(.8em)
    #mitex(
      `
    \ket{\psi} = \prod^p_{j=1} \exp \Bigg(-i \bigg( (1 - s(j\Delta t))H_B + s(j\Delta t)H_P \bigg)\Delta t \Bigg)\ket{\psi_0}
    `,
    )

    进一步的，为了方便电路的实现，对每次的演化，我们规定如下：

    #mitex(
      `
    \begin{aligned}
    s(t) = 1 &,  t \in [0, \gamma_1) \\
    s(t) = 0 &, t \in [\gamma_1, \gamma_1 + \beta_1)\\
    s(t) = 1 &, t \in [\gamma_1 + \beta_1, \gamma_1 + \beta_1 + \gamma_2)\\
    &\vdots
    \end{aligned}
    `,
    )
  ],
  [
    #set text(.8em)
    于是，最终我们可以得到本征态的计算为：
    #mitex(
      `
    \begin{aligned}
    \ket{\psi(\overrightarrow{\gamma}, \overrightarrow{\beta})} &= e^{-iH_B\beta_p}\times e^{-iH_P\gamma_p} \times \dots \times e^{-iH_B\beta_1} \times e^{-iH_P\gamma_1} \ket{+} \\
    &= \prod^p_{j=1} e^{-iH_B\beta_j} e^{-iH_P\gamma_j} \ket{+} \\
    &= \prod^p_{j=1}U_B^{(j)}U_C^{(j)} \ket{+}
    \end{aligned}
    `,
    )
  ],
)

#pagebreak()

#mitex(
  `
\begin{aligned}
\ket{\psi(\overrightarrow{\gamma}, \overrightarrow{\beta})} &= e^{-iH_B\beta_p}\times e^{-iH_P\gamma_p} \times \dots \times e^{-iH_B\beta_1} \times e^{-iH_P\gamma_1} \ket{+} \\
&= \prod^p_{j=1} e^{-iH_B\beta_j} e^{-iH_P\gamma_j} \ket{+} \\
&= \prod^p_{j=1}U_B^{(j)}U_C^{(j)} \ket{+}
\end{aligned}
`,
)

我们令 $theta = (arrow(gamma), arrow(beta))$，即可得到：

$
  ket(psi(theta)) = product^p_(j=1)U_B^((j))U_C^((j)) ket(+)
$

其中，$theta = (gamma_1, beta_1, dots, gamma_p, beta_p)$

#pagebreak()

$
  ket(psi(theta)) = product^p_(j=1)U_B^((j))U_C^((j)) ket(+)
$

其中，$theta = (gamma_1, beta_1, dots, gamma_p, beta_p)$

于是，我们获得了一个可以使用经典优化器优化的模型：

$
  cal(C)(theta) = expval(hat(H), psi(theta))
$

#pagebreak()

通过测量得到 $cal(C)(theta)$ 后，调用传统优化器更新 $theta$（梯度下降，牛顿法，单纯形等），不断重复这个过程

#align(center)[
  #image("fig/qaoa.png", width: 60%)
]

最后，我们在基态中测量 $ket(psi(theta))$，测得概率最大的一个作为问题的解

= MVC 问题示例

Talk is cheap, show me the code.
