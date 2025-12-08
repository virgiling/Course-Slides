#import "@preview/cetz:0.2.2"
#import "@preview/fletcher:0.5.1" as fletcher: edge, node
#import "@preview/curryst:0.3.0": proof-tree, rule
#import "@preview/touying-buaa:0.2.0": *
#import "@preview/i-figured:0.2.4"
#import "@preview/pinit:0.2.2": *
#import "@preview/lovelace:0.3.0": *
#import "@preview/subpar:0.2.2"

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
    title: [RL for B&B Optimisation using Retrospective Trajectories],
    subtitle: [AAAI '23],
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

= 组合优化中的强化学习

在 Yoshua Bengio 的综述中，可以发现，基于 MDP 的 RL 十分适合解决组合优化问题

#align(center)[
  #image("fig/rl4co.png", width: 40%)
]

本文提出一种基于 RL 的分支方法，用于替代传统启发式来做分支的决策

= 符号定义

MILP 问题可以形式化为：

$
  argmin_x {bold(c)^T bold(x) | bold(A) bold(x) = bold(b), bold(l) lt.eq bold(x) lt.eq bold(u), bold(x) in bb(Z)^p times bb(R)^(n - p)}
$

其中 $bold(c)$ 表示目标函数的系数向量，$bold(A)$ 表示约束矩阵，$bold(b)$ 表示约束向量，$bold(l)$ 和 $bold(u)$ 分别表示变量的下界和上界。


== B&B 中的分支

#only((1, 3))[
  传统的分支限界中，分支的决策通常基于启发式规则，例如:
]

#only((1, 2))[
  + Pseudocost Branching：根据历史分支效果（如界限提升）来选择变量，计算快，但早期分支决策如果初始化不好，会极大影响整体性能。
]

#only(2)[
  + Strong Branching：对每个候选变量都做一次“试分支”，计算其对局部界限的提升，选择最优变量。
]

#only(3)[
  #align(center)[
    #image("fig/B&B.png", width: 80%)
  ]
  注意，每次分支后，我们都添加了一个局部约束，例如这里的 $x_2 gt.eq 6, x_1 lt.eq 1$
]


= 如何推理

== 二分图

首先，我们引入一个二分图：

$cal(G) = (X, C, E)$，其中：

+ 顶点集合 $V = X union C$，$X$ 表示变量，$C$ 表示所有约束（包括全局约束与分支的约束）。
+ 边集合 $E = {(x, c)| x in X, c in C, "iff" c "contains" x}$。

#figure(
  image("fig/bigraph.png", width: 30%),
)<network>

== 网络架构

#figure(
  image("fig/network.png", width: 80%),
)


#only(1)[
  本文使用 GCN 来综合变量与约束的特征值，帮助 RL 进行决策，GCN 选定的特征值如 @features 所示
  #subpar.grid(
    figure(
      image("fig/all_features.png", width: 90%),
      caption: [所有特征值],
    ),
    <all>,

    figure(
      image("fig/features.png"),
      caption: [变量附加特征值],
    ),
    <additional>,

    columns: (1fr, 1fr),
    caption: [变量与约束的特征值],
    label: <features>,
  )
]

#only(2)[
  随后，每次我们选择一个变量 $x_i$ 进行分支（不妨设为 $x_i gt.eq b_i$）

  此时，我们新增了约束，就会得到一个新的二分图 $cal(G)^prime$

  我们通过 GCN 的多层消息传播与聚合后，顶点得到新的 `embedding`，然后我们通过一个 MLP 将 `embedding` 映射为强化学习 `Q-Learning` 中的 `Q` 值
]

= 如何训练

== 先前方法的缺陷

- 奖励稀疏（Sparse Rewards）：在MILP分支问题中，只有最终解才有明确奖励，导致RL训练时很难获得有效反馈。

- 探索困难（Difficult Exploration）：每一步的分支选择空间巨大（可能有上千个变量），RL很难有效探索到优质策略。

- 部分可观测性（Partial Observability）：分支决策后，节点选择策略（node selection）会跳转到树中任意位置，导致RL agent很难预测下一个状态，学习难度大。

- 长决策序列（Long Episodes）：一个MILP实例的分支决策序列可能非常长，导致RL训练时信号传递困难，credit assignment（归因）问题严重。

== Methodology

首先，我们建立 MDP 模型如下：

- State: 以当前搜索树的*焦点节点*为中心，将其对应的 MILP 子问题化为二分图
- Action: 在当前节点的所有可分支变量中，选择一个变量进行分支
- Reward:
  - 每分支一次，奖励为 -1
  - 如果当前动作使得子树被 fathomed#footnote[
      指在 B&B 树搜索过程中，已经不需要再继续扩展（分支）下去的节点。
    ]，奖励为 0


#only(2)[
  但此时 MDP 模型依然无法保证我们进行状态转移后，不会转移到搜索树的任意位置，于是，我们通过构建训练集来帮助 RL 进行学习。
]

= 轨迹重构

#tblock(title: "轨迹重构")[
  在训练时，不直接用原始长序列（即solver实际走过的节点序列），而是“回溯”地将搜索树分解为多个短的、每个都在同一子树内的轨迹。
]

#figure(
  image("fig/train.png", width: 90%),
)

== 训练数据生成

#figure(
  image("fig/train.png", width: 70%),
)

+ 使用任意节点选择策略（如SCIP默认）完整求解一个MILP实例，得到完整的BnB树。

+ 回溯式地将BnB树分解为多条“子树内轨迹”：
  每条轨迹从某个高层节点出发，终点是该子树中尚未被选过的fathomed叶节点。


== 训练流程

RL 采用 n-step DQN 来拟合 Q 函数，损失函数为：
$
  J_("DQN"_n)(Q) = [r^((n))_t + gamma^((n))_t max_(u^prime) Q_(overline(theta))(s_(t+n), u^prime) - Q_theta (s_t, u_t)]^2.
$

过程如下：

+ 用当前策略与环境交互，通过 retro branching 方式收集轨迹。

+ 将轨迹中的 transition 加入经验回放池。

+ 从回放池采样一批transition，计算损失，反向传播更新网络参数。

+ 周期性地更新目标网络参数，直到网络收敛

= 实验结果

== Benchmark & Baseline

Benchmark 选的为 MILP 的问题集：集合覆盖，组合拍卖，容量设施选址，最大独立集。

Baseline 为：

- FMSTS，当前 SOTA 的 RL 方法
- IL，当前 SOTA 的模仿学习方法
- 两种启发式方法：PB 与 SB
- Random 分支

== 结果

在 500 $times$ 1000 的集合覆盖问题下，其表现为：

#figure(
  image("fig/eval.png", width: 50%),
)

