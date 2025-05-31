#import "@preview/cetz:0.2.2"
#import "@preview/fletcher:0.5.1" as fletcher: node, edge
#import "@preview/curryst:0.3.0": rule, proof-tree
#import "@preview/touying:0.5.2": *
#import "@preview/touying-buaa:0.2.0": *
#import "@preview/i-figured:0.2.4"
#import "@preview/pinit:0.2.2": *
#import "@preview/lovelace:0.3.0": *
#import "@preview/algo:0.3.3": algo, i, d, comment, code

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
    title: [(Adaptive) Large Neighborhood Search],
    subtitle: [],
    author: [凌典],
    date: "2024-03-07",
    institution: [Northeast Normal University],
    logo: image.decode(colorize(read("../template/fig/nenu-logo.svg"), white))
  ),
)

#title-slide()

#slide(
  session: "Introduction",
  title: "Neighborhood Search"
)[
  邻域搜索算法（或称为局部搜索算法）是一类非常常见的改进算法，其在每次迭代时通过搜索当前解的“邻域”找到更优的解。 
  
  邻域搜索算法设计中的关键是邻域结构的选择，即邻域定义的方式。 根据以往的经验，邻域越大，局部最优解就越好，这样获得的全局最优解就越好。 
  
  但与此同时，邻域越大，每次迭代搜索邻域所需的时间也越长。出于这个原因，除非能够以非常有效的方式搜索较大的邻域，否则启发式搜索也得不到很好的效果。
]

#slide(
  session: "Introduction",
  title: "VLSN"
)[
  从熟知的邻域搜索算法 (Neighborhood Search) 出发，当一个邻域搜索算法搜索的邻域规模随着实例规模的增长而呈指数增长时，我们引申出了 Very Large Scale Neighborhood Search(VLSN) 算法。

  #only((2, 3))[
    VLSN 分为四种类型#footnote[#link("https://backend.orbit.dtu.dk/ws/portalfiles/portal/5293785/Pisinger.pdf")["David Pisinger and Stefan Ropke",Large neighborhood search.]]：
    #only(2)[
      - 可变深度邻域搜索(Variable-depth methods)
      #grid(
        columns: 2,
        column-gutter: 1em,
        [
          以启发式的方式搜索一个参数化的更深邻域族 $ N_1，N_2，dots，N_k$ 。一个典型的例子是 1-交换邻域 $N_1$，其中改变一个变量/位置。
        ],
        image("fig/VDNS.png", width: 90%, fit: "contain") 
      )
    ]
    #only(3)[
      - 基于网络流的改进方法(Network-flows based improvement algorithms)
      - 基于多项式时间可解子类限制的方法(Efficiently solvable special cases)
      - 大邻域搜索(Large Neighborhood Search, LNS)
    ]
  ]

  // #only(4)[
  //   一个简单的 VLSN 例子如下：
  //   考虑
  // ]
]

#slide(
  session: "Problem",
  title: "Problem Example"
)[
  #only((1, 2, 3))[考虑一个 CVRP 问题，我们有一个车队，每辆车都有一个容量限制，我们需要将一些货物从一个中心点运送到一些客户点。我们的目标是最小化总行驶距离，并保证每个客户点都被访问且满足容量限制。]

  #only(2)[
    形式化的来说，考虑一个无向图 $G = <V, E>$，其中$c_e in RR(forall e in E)$, $V = {0, dots, n}$，顶点 $0$ 为中心点，顶点 $i$ 为客户点。
    
    每个客户点 $i$ 都有一个需求 $q_i$，有 $m$ 辆车，每辆车都有一个容量限制 $Q$。我们需要找到 $m$ 条路线，每条路线的起点均为中心点，使得车辆恰好访问每个客户一次，并满足每条路线上客户的需求总和小于或等于 $Q$，$m$ 条路线经过的边成本之和最小。
  ]

  #only((3))[
    一个简单的实例及可行解如下：
    #image("fig/CVRP-sample.png", width: 40%, fit: "contain")
  ]

]

#slide(
  session: "Introduction",
  title: "LNS"
)[
  LNS 是一种元启发式搜索算法，其拓展版本为自适应大邻域搜索(Adaptive Large Neighborhood Search, ALNS)。

  大多数的NS算法会明确定义邻域，在 LNS 中，邻域由 `destroy` 和 `repair` 隐式定义。

  #only((2, 3))[
    - `destroy`#footnote[通常包含随机元素，使得每次都会破坏解的不同部分]: 从当前解中移除一部分元素，得到一个部分解
    - `repair`: 从被 `destroy` 的部分解中，重构出一个可行解
  ]

  #only(3)[
    于是，解 $X$ 的邻域 $N(X)$ 被定义为：$N(X) = {"repair"("destroy"(X))}$。
  ]
]

#slide(
  session: "LNS",
  title: "CVRP Example"
)[
  例如先前的 `CVRP` 问题，我们考虑：
  -  `destroy` 为删除当前解 $X$ 中 `15%` 的客户点#footnote[随机选择`15%` 的点删除]，并缩短被删除客户的路线。
  - `repair` 为使用启发式的贪心来构建可行解。

  #grid(
   columns: 3,
   column-gutter: 0em,
   rows: 2,
   row-gutter: 1.5em,
   image("fig/CVRP-1.png", fit: "contain", width: 70%),
   image("fig/CVRP-2.png", fit: "contain", width: 70%),
   image("fig/CVRP-3.png", fit: "contain", width: 70%),
   [
      原始解 $X$
   ],
   [
      `destroy` 后的解 $d(X)$
   ],
   [
      `repair` 后的解 $r(d(X))$
   ]
  )
]

#slide(
  session: "LNS",
  title: "Framework",
)[
  #grid(
    columns: 2,
    column-gutter: 1em,
    algo(
      title: "LNS", 
      parameters: ("X: a feasible solution",),
      row-gutter: .8em,)[
      $X_"best" arrow.l X$\
      while not terminate do#i\
        $X_t arrow.l "repair"("destroy"(X))$\
        if accept($X_t, X$) then#i\
          $X arrow.l X_t$#d\
        if cost($X_t$) < cost($X_"best"$) then#i\
            $X_"best" arrow.l X_t$#d#d\
      return $X_"best"$      
    ],
    [
      #only(1)[
        在设计算法时，显然我们需要从两个方面来进行考量：
        + `accept` 的设计
        + `destroy` 和 `repair` 的设计
      ]
      #only(2)[
        `accept` 函数的设计有多种选择：
        + 简单的爬山算法型，只接受更优解
        + 模拟退火型#footnote[也有使用 `RRT` 等方法]，在接受更优解的同时，也会以一定概率接受更差解

        换而言之，在 `accept` 这个过程中，我们可以引入一个启发式的算法来决定是否接受新解。
      ]
      #only((3, 4))[
        #only(3)[对于 `destroy` 设计，最重要的就是对删除程度的把握。

        程度小会导致搜索空间小，无法跳出局部最优解；程度大则会导致算法退化。因此这是一个消耗时间与解质量的 trade-off。

        常见的做法是：
        + 逐步提升删除的程度
        + 每次迭代时，从一个依赖于实例大小的区间中随机选择删除程度
        ]
        #only(4)[
          注意，在先前提到过 `destory` 需要包含随机元素

          这是为了保证 `destory` 必须保证覆盖到解空间的各个部分#footnote[或者至少是全局最优解所在的那一部分]，从而避免算法陷入局部最优解。
        ]
      ]
      #only(5)[
        对于 `repair` 设计有极大的自由度，我们有以下几种选择：
        
        - `repair` 能够从部分解中构建出当前状态下的最优解
        - `repair` 是启发式算法。
        
        当然，我们也可以设计基于特定问题的 `repair` 方法，甚至使用MIP或约束求解器。

      ]
      #only(6)[
        在 `LNS` 框架中，`destroy` 和 `repair` 在求解时是唯一的，这意味着我们只能够搜索一种邻域结构，显然这是 `LNS` 的一个局限
        
        如果我们能够同时搜索多种邻域结构，那么我们就能够更好的探索解空间。
      ]
    ]
  )
]

#slide(
  session: "ALNS",
  title: "Introduction"
)[
  根据上面所说的局限，于是我们有了 `Adaptive LNS` (i.e. ALNS)

  在此自适应算法中，我们允许在一次搜索中探索多个邻域结构（使用多组不同的 `destroy` 和 `repair`），搜索的邻域结构是通过解的质量而动态变化的。
]

#slide(
  session: "ALNS",
  title: "Framework"
)[
  #grid(
   columns: (55%, 45%),
   column-gutter: .7em,
   algo(
    title: "ALNS",
    parameters: ("X: a feasible solution",),
    row-gutter: .6em,
   )[
    $X_"best" arrow.l X$\
    $rho^-, rho^+ arrow.l (1,dots, 1)$\
    while not terminated do#i\
      select $d in Omega^-, r in Omega^+$ using $rho^-, rho^+$\
      $X_t arrow.l r(d(X, d))$\
      if accept($X_t, X$) then#i\
        $X arrow.l X_t$#d\
      if $"cost"(X_t) < "cost"(X_"best")$ then#i\
        $X_"best" arrow.l X_t$#d\
      update $rho^+, rho^-$#d\
    return $X_"best"$
   ],
   [
    #only(1)[
      - $Omega^-, Omega^+$ 分别表示 `destroy` 和 `repair` 方法的集合
      - $rho^-, rho^+$ 分别表示集合中方法的权重集合
      - 以概率 $phi.alt_j^- = rho_j^-/(sum_(k=1)^(|Omega^-|)rho_k^-)$ 从 $Omega^-$ 中选择 $d_j$，$r_j$ 同理。
    ]
    #only((2, 3, 4))[
      #only(2)[
        而权重 $rho^-, rho^+$ 根据 `destory`, `repair` 方法在搜索过程中的表现而动态调整。
      ]
      #only((2, 3))[
        $
        psi = max cases(
          omega_1 "if " "cost"(X_t) < "cost"(X_"best"),
          omega_2 "if " "cost"(X_t) < "cost"(X),
          omega_3 "if accept",
          omega_4 "if not accept"
        )
        $
      ]
      #only(2)[
        其中 $omega_1 gt.eq omega_2, gt.eq omega_3 gt.eq omega_4 gt.eq 0$
      ]

      #only((3, 4))[
        假设 $d_a$ 与 $r_b$ 为此次被选中的 `destroy` 和 `repair` 方法，那么我们有：

        $rho^-_a = lambda rho_a^- + (1-lambda)psi$

        $rho^+_b = lambda rho_b^+ + (1 - lambda)psi$

        #only(4)[
          显然，只有被选中的 `destroy` 和 `repair` 方法的权重会被更新，从而选择对解空间探索更好的邻域结构。
        ]
      ]
    ]
   ]
  )
]

#slide(
  session: "ALNS",
  title: "Different destroy and repair"
)[
  #only(1)[
    在上面的讨论中，我们认为 `destroy` 和 `repair` 是可以任意搭配的

    但存在着以下情况：
    + 某一个 `destroy` 只和某一个 `repair` 搭配效果很好
    + 一个 `repair` 方法可能做出了某些假设，导致其只能搭配某些 `destroy` 方法
  ]

  #only(2)[
    对于第一种情况，我们考虑将 `destroy` 和 `repair` 方法组合成一个 `operator`，并对这个算子进行分配权重与调整。

    #grid(
     columns: (1.2fr, 1.2fr),
      image("fig/ALNS-combine.png", fit: "contain", width: 80%), 
      image("fig/ALNS-combine-phi.png", fit: "contain", width: 80%),
    )
  ]

  #only(3)[
    对于第二种情况，我们采用耦合邻域来解决：
    
    定义子集 $K_i subset.eq Omega^+$，使得采取 `destory` 函数 $d_i$ 时，`repair` 函数只能从 $K_i$ 中选择。

    当 $K_i = emptyset.rev$ 时，有两种策略来解决：
      + $d_i$ 同时负责 `destroy` 和 `repair`
      + 采用普通的启发式策略进行 `repair`
  ]
]

#slide(
  session: "ALNS",
  title: "Design"
)[
  由于 `ALSN` 在 `accept` 函数上的设计与 `LNS` 相差不大，我们主要关注 `destroy` 和 `repair` 方法的设计。
]

#slide(
  session: "ALNS Design",
  title: "Destroy"
)[
  + 随机选择应该删除的部分 (`random destory`)
  + 尝试移除 $q$ 个“关键”变量，即具有较高成本或破坏当前解结构的变量(`worst destroy` / `critical destroy`)
  + 可以选择一些相关的变量，#pin(1)这些变量在保持解的可行性的同时易于互换#pin(2) (`related destroy`)
  
  #only(2)[
    #pinit-highlight(1, 2)
    对于CVRP，可以定义每对客户之间的相关性，例如客户之间的距离，也可以包括客户需求（需求相似的客户被认为是相关的）。
    
    因此，`destory` 方法将选择具有高度相关度量的一组客户。
  ]

  #only((beginning: 3))[
    4. 基于历史信息选择 $q$ 个变量并删除，历史信息可以是统计某个给定变量（或一组变量）的设置导致错误解的频率(`history based destroy`)
  ]
]

#slide(
  session: "ALNS Design",
  title: "Repair"
)[
  + 贪心算法的各类改进变体
  + 近似 / 精确算法，精确算法可以以解的质量为代价来对时间进行松弛，以求解的更快，例如目前有许多 `repair` 方法使用 MIP 求解器进行。
]

#slide(
  session: "Application",
  title: "Application"
)[
  #only(1)[
    #rotate(
      90deg
    )[
      #image("fig/VRP.png", fit: "contain", width: 100%, height: 160%)
    ]
  ]
  #only(2)[
    #rotate(
      90deg
    )[
      #image("fig/VRP-2.png", fit: "contain", width: 100%, height: 160%)
    ]
  ]
  #only(3)[
    #rotate(
      90deg
    )[
      #image("fig/non-VRP.png", fit: "contain", width: 100%, height: 160%)
    ]
  ]
]

#slide(
  session: "(A)LNS",
  title: "Conclusion & Discussion"
)[

  1. Hybrid Neighborhoods

  邻域搜索复杂性的增加意味着局部搜索算法可以执行更少的迭代。 Gutin 和 Karapetyan 通过实验比较了多维分配问题的许多小型和大型邻域，包括它们的各种组合。事实证明，大小邻域的某些组合可以提供最佳结果。

  2. ML for Adaptive
  
  机器学习等技术是否可以用于改进 ALNS 的自适应层。更聪明的动态选择 `destory` 和 `repair` 可能会改善启发式，并且让算法中的其他参数适应当前的实例，例如 `accept` 函数的参数。
]