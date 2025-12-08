#import "@preview/cetz:0.2.2"
#import "@preview/fletcher:0.5.1" as fletcher: edge, node
#import "@preview/curryst:0.3.0": proof-tree, rule
#import "@preview/touying:0.5.2": *
#import "@preview/touying-buaa:0.2.0": *
#import "@preview/i-figured:0.2.4"
#import "@preview/pinit:0.2.2": *
#import "@preview/lovelace:0.3.0": *
#import "@preview/algo:0.3.3": algo, code, comment, d, i

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

#show: buaa-theme.with(
  // Lang and font configuration
  lang: "zh",
  font: ("Bookerly", "LXGW WenKai GB Screen"),

  // Basic information
  config-info(
    title: [Stochastic Search in Metaheuristics],
    subtitle: [],
    author: [凌典],
    date: "2024-04-09",
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

#slide(
  title: "General Framework",
  session: "Framework",
)[
  #only(1)[
    一个组合优化问题可以被抽象成如下结构：

    $
      min f(x) quad s.t. quad x in S
    $
    其中， $f$ 为目标函数，$S$ 为解空间

    显然 `max` 和 `min` 可以相互替换#footnote[当限制为 `min` 时函数也可以称为 `cost` ，限制为 `max` 时称为 `fitness`]

  ]
  #only((2, 3))[
    #only(2)[
      那么，一个随机搜索的抽象框架如下：

      在第 $t$ 次迭代时，考虑一个总集合（或者也可以当作一个内存区域，其中存储的结构是高度自定义的）$M_t$，一个解集及其邻域的子集 $L_t$
    ]

    #only((2, 3))[
      + $M_1$ 初始化
      + 当 $t = 1 , dots$
        + $L_t = g(M_t, z_t)$
        + $L_t^+ = { (x_i, f(x_i)) |forall x_i in L_t}$
        + $M_{t + 1} = h(M_t, L^+_t, z^(prime)_t)$
    ]

    #only(2)[
      其中 $z_t, z^(prime)_t$ 表示随机程度
    ]

    #only(3)[
      值得注意的是：当前的最优解 $x^("curr")_t$ 是由 $(M_t, L^+_t)$ 定义的，且算法的结束条件也是依赖于 $(M_t, L^+_t)$ 定义的#footnote[关于这一点我们在后面会详细解释]
    ]
  ]
]

#slide(
  title: "Instance of Framework",
  session: "Framework",
)[
  #only(1)[我们从 `SA` 与 `GA` 两个算法来说明框架的实例化]
  #grid(
    columns: (1fr, 1.2fr),
    column-gutter: 0.5em,
    [
      #only(1)[
        + $M_1$ 初始化
        + 当 $t = 1 , dots$
          + $L_t = g(M_t, z_t)$
          + $L_t^+ = { (x_i, f(x_i)) |forall x_i in L_t}$
          + $M_{t + 1} = h(M_t, L^+_t, z^(prime)_t)$
      ]
      #only(2)[
        #image("fig/SA.png", fit: "contain", width: 100%)
      ]
      #only(3)[
        #image("fig/GA.png", fit: "contain", width: 100%)
      ]
    ],
    [
      #only(2)[
        对于 `SA` 来说：

        - $M_t$ 由单个元素组成，即当前搜索点 $x$
        - $L_t$ 由单个元素组成，即 $x$ 的邻域解 $y$
        - 为了从 $M_t$ 中确定 $L_t$，选择 $M_t$ 中元素 $x$ 的一个随机邻居 $y$
        - 若将 $M_t$ 更新为 $M_(t + 1)$，则由 SA 中使用的随机接受规则决定当前解 $y$ 是否被接受
          - 如果是，$M_(t + 1)$ 包含 $y$，否则包含 $x$
      ]
      #only(3)[
        对于 `GA` 来说：

        - $M_t$ 就是在 $t$ 时刻的种群
        - $L_t$ 由 $k$ 个解组成
        - 为了从 $M_t$ 中确定 $L_t$ ，将变异和交叉算子应用于 $M_t$ 中的解, 由此得到 $L_t$
        - 为了将 $M_t$ 更新到 $M_(t + 1)$，对 $L_t$ 中包含的个体使用相应的目标函数值进行适应度比例选择，给出 $M_(t + 1)$
      ]
    ],
  )
]

#slide(
  title: "Instance of Framework",
  session: "Framework",
)[

  #only((
    1,
    2,
  ))[回顾 “当前的最优解 $x^"curr"_t$ 是由 $(M_t, L^+_t)$ 定义的，且算法的结束条件也是依赖于 $(M_t, L^+_t)$ 定义的”]

  #only(1)[
    对于 `SA` 而言，显然当前的最优解一定是 $L^+_t$ 中目标函数最优的那个，其结束条件一般为温度是否降低到某个阈值，这显然依赖于迭代时解是否依概率被接受，显然依赖于 $(M_t, L^+_t)$
  ]

  #only(2)[
    关于结束条件，大多情况下 `GA` 的结束条件时检查最优解的函数是否收敛，显然依赖于 $L^+_t$
  ]

  #only(3)[
    针对 $M_t$ 在不同算法内的不同抽象，可以将元启发式进行粗略的分类：

    1. Stochastic Local Search Algorithms：在 `SA`, `ILS`, `VNS` 中，$M_t$ 只包含着较小且固定数量的解集，例如当前搜索点，当前邻居
    2. Population-Based Stochastic Search Algorithms：`GA` ，$M_t$ 可以看作是当前迭代次数下的种群
    3. Model-Based Stochastic Search Algorithms：蚁群优化( Ant Colony Optimization，ACO )，$M_t$ 由实值参数向量组成，例如 ACO 中的信息素向量
  ]
]

#slide(
  title: "Convergence",
  session: "Algorithm",
)[
  观察 $(M_t, L^+_t)$，可以发现实际上这个二元组是一个离散时间的马尔科夫链：

  下一次迭代的 $(M_(t + 1), L^+_(t + 1))$ 的计算方式为
  $
    (h(M_t, L^+_t, z^(prime)_(t + 1)), {(x_i, f(x_i)) | forall x_i in g(M_(t + 1), z_(t + 1))})
  $

  更一般的， $(M_t)$ 的计算就是一个马尔科夫过程

  于是，通过判断此马尔科夫过程是否存在平稳态，我们能够知道算法是否能依概率收敛，且能够大致评估需要多少次迭代才能够收敛。
]

#slide(
  title: "Parameter",
  session: "Optimization",
)[

  #only(1)[
    启发式中一个重要的问题是参数应该如何设置，在随机搜索中我们将其分为两类：

    + $g$ 中包含的为采样参数，它们控制着样本点在 $L_t$ 中的分布，例如 `GA` 中的变异率和交叉率
    + $h$ 中包含的为学习参数，它们决定了在抽样试验点上观察到的对 $M_(t + 1)$ 的影响程度，例如 `SA` 中的温度参数
  ]

  #only((2, 3, 4, 5))[
    参数应该动态变化还是保持不变
    #only(3)[

      有很好的实证论证动态更新效果很好，多个随机搜索算法的收敛结果#footnote[指算法在迭代过程中是否能够收敛到某个目标或最优解]是基于动态参数方案的。例如，SA 的经典收敛结果要求温度参数 $T$ 是逐渐减小的

      对随机搜索算法关键参数的动态管理是实现 搜索-利用 平衡的关键点
    ]
    #only(4)[

      然而，对于动态更新更优的理论保证暂时还没有，在 `SA` 中有一个持续了很长时间的讨论：
      === 是否应该进行降温？

      根据理论上的收敛结果，减小优化过程中的温度 $T$ 是否真的有优势，或者是否可以通过应用所谓的 Metropolis 算法#footnote[该算法保持一个固定的、恒定的温度 $T$]来实现相同的性能

      答案是对于一些实际发生的优化问题，例如最小生成树问题，SA 优于 Metropolis
    ]
    #only(5)[

      在某些问题和算法中，例如遗传算法，将变异概率 $p_m$ 固定为常数比周期性改变 $p_m$ 收敛结果要更好。
    ]
  ]

]

#slide(
  title: "Black-Box Optimization",
  session: "Optimization",
)[
  #only(1)[
    === 黑盒优化器

    大多数随机元启发式方法的基本形式并不利用关于特定问题实例的任何信息（比如，TSP中的距离矩阵），只使用关于搜索空间的信息，例如邻域结构，以及关于所考虑的特定问题类型的信息。

    那么，可以想象算法是一个反复调用返回给定解 $x$ 的适应度值的“黑盒”过程，但算法并不知道这些适应度值是如何确定的。

    此时将算法称为黑盒优化器
  ]
  #only(2)[
    实际应用的随机元启发式方法的几个变体并不是黑盒优化器，因为它们除了使用黑盒类型的核心机制外，还利用了问题实例的信息。

    例如在蚁群算法中使用问题特定的启发值，我们可以称这样的算法为灰盒优化器，同时将它们与数学规划（MP）的“白盒”算法区分。

    一些元启发式方法，如GRASP，本质上就是“灰盒”的。灰盒优化器的一种特殊形式是元启发式方法和数学规划方法（如局部分支）之间的混合方法，被称为数学启发式算法（matheuristic algorithms）。
  ]
]
