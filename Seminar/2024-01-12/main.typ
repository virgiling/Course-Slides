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
    title: [Learning-based Multi-Start ILS for PMSCP],
    subtitle: [],
    author: [凌典],
    date: "2024-01-12",
    institution: [Northeast Normal University],
    logo: image.decode(colorize(read("../template/fig/nenu-logo.svg"), white))
  ),
)

#title-slide()

#slide(
  session: "Problem Description",
  title: "Formulation",
)[
  #only((1, 2))[给定一个全集 $E = {e_1, e_2, dots, e_m}$
  
  一个集合 $S = {s_1, s_2, dots, s_n}$，其中 $s_i subset.eq E and s_i != emptyset.rev$

  一个集合 $G = {g_1, g_2, dots, g_q}$，其中 $q_i subset.eq S and q_i != emptyset.rev and q_i sect q_j = emptyset.rev$]

  #only((2, 3, 4))[
    $E$ 中的每个元素 $e_i$ 有其对应的利润 $a_i$

    $S$ 中的每个元素 $s_j$ 有对应的代价 $b_j$

    $G$ 中的每个元素 $g_k$ 有对应的代价 $c_k$

    于是，问题描述为：找到 $S$ 的一个子集 $X^* subset.eq S, X^* != emptyset.rev$
    
    使得目标函数 $f = $ #pin(1) $sum_(s_i in X^* and e_j in s_i) a_j - sum_(s_i in X^*) b_i - sum_(g_k in G and s_i in X^* and s_i in g_k) c_k$ #pin(2) 最大

    #only((3, 4))[
      #pinit-highlight(1, 2)
      #only(4)[
        #pinit-point-from(
          pin-dx: 20pt,
          pin-dy: 130pt,
          body-dx: 0pt,
          body-dy: 0pt,
          offset-dx: 300pt,
          offset-dy: 200pt,
          1)[
          注意，这里的所有 \
          可能重复的覆盖都 \
          只计算一次
        ]
      ]
    ]
  ]

  #only(5)[
    我们考虑如下例子，$E = {e_1, dots, e_5}, S = {s_1, dots, s_5}, G = {g_1, g_2}$，考虑一个可行解为：$X^* = {s_4}$，则 $f = a_1 + a_4 + e_5 - b_4 - c_2 = 5 + 3 + 6 - 5 - 3 = 6$
    #figure(
     image("fig/Instance-example.png", height:75%, fit: "contain"),
    )

  ]
]

#slide(
  session: "Related Work",
  title: "Related Work"
)[

对比的三种 SOTA 算法如下：

  + MILP(CPLEX)
  + ITS
  + Parallel ITS

本文提出的算法为 LMSILS

#only(2)[
  // TODO complete the parallel ITS algorithm
  并行的 ITS 做法简单表述为
]

]

#slide(
  session: "LMSILS",
  title: "LMSILS Framework"
)[
  
  #only(1)[
    算法采用的为 学习驱动 + 多启动，考虑原本的多启动框架：
    #algo(
      title: "Multi-Start",
      parameters: ([Instance $I$],),
    )[
      $X^* arrow.l emptyset.rev$\
      while not terminated #i\
        $X_0 arrow.l $ Initial_Solotion($I$)\
        $X_0 arrow.l$ Local_Search($X_0$)\

        if $f(X_0) > f(X^*)$#i\
          $X^* arrow.l X_0$#d#d\
      
      return $X^*$
    ]
    +  _Initial_Solotion_ 替换为学习驱动的初始化算法
    +  _Local_Search_ 替换为一个两阶段局部搜索算法
  ]

  #only(2)[
    整体框架如下所示：
    #algo(
      title: "LMSILS",
      parameters: ([Instance $I$],),
    )[
      $I^prime arrow.l $Reduction($I$)\
      $X^* arrow.l emptyset.rev$\
      $(epsilon.alt, eta, beta, omega, gamma) arrow.l $Initial_Parameter() \
      while not terminated #i\
        $X_0 arrow.l $ Learning_Driven_Initialization($I^prime, eta, epsilon.alt$)\
        $(X_0, eta, gamma) arrow.l$ Intensification_Driven_Iterated_Local_Search($X_0, omega, beta, eta, gamma$)\

        if $f(X_0) > f(X^*)$#i\
          $X^* arrow.l X_0$#d#d\
      
      return $X^*$
    ]
  ]
]

#slide(
  session: "LMSILS",
  title: "Reduction"
)[
  考虑集合 $S$ 中的元素 $s_i$
  
  如果对于 $forall e_j in s_i$，我们有 $sum_(e_j in s_i) a_j lt.eq b_i$，换而言之，选择 $s_i$ 不会带来任何的正收益（甚至在没有计算组的代价的情况下），那么显然我们在任何情况下都不可能选择 $s_i$ ，因此，我们可以将 $s_i$ 直接删除。

  #only(2)[
    于是，我们可以得到如下的简化后的问题：
    $I^prime = (E, S_0, G)$
  ]
]

#slide(
  session: "LMSILS",
  title: "Learning Driven Initialization"
)[
  #only((1, 2))[
    文章中的学习，指代从历史解中学习出更可能在最优解中的那部分

    我们通过一个向量 $eta in bb(R)^(|S_0|)$ 来实现，其中，向量的分量 $eta_i$ 表示 $s_i$ 在最优解#footnote[在论文中，其表述为 “下一次的初始解” ]中的概率（此概率最开始均为 $0.5$），概率会通过在局部搜索中进行更新。
  ]

  #only(2)[
    而另一个参数 $epsilon.alt$ 用于控制贪心的概率，我们根据此概率进行贪心的选择顶点进入解集中，从而初始化一个解。

    具体来说，初始化的算法如下所示：
  ]

  #only((3, 4))[
    #algo(
      title: "Learning_Driven_Initialization",
      parameters: ([Instance $I^prime$, $eta$, $epsilon.alt$],),
    )[
      $X_0 arrow.l emptyset.rev$\
      $S^prime arrow.l S_0$\
      while $S^prime != emptyset.rev$ #i\
        $"index"$ = -1 \
        if #pin(3) rand(0, 1) < $epsilon.alt$#pin(4)#i \
          index = $op("arg max", 
          limits: #true)_limits(i in [|S^prime|]) eta_i$#d \
        else #i\
          index = rand(1, $|S^prime|$)#d\
        
        $S^prime arrow.l S^prime - {s_"index"}$\

        if #pin(5)$sum_(e_i in s_("index") and e_i in.not union.big_(s_l in X_0)s_l) a_i - b_("index") > 0$ && rand(0, 1) < $eta_("index")$ #pin(6) #i\
          $X_0 arrow.l X_0 union {s_("index")}$#d#d\
    ]  
    #pinit-highlight(3, 4)
    #only(4)[
      #pinit-highlight(5, 6, fill: rgb(0, 0, 255, 20))
    ]
  ]

  #only(5)[
    加入解集的条件为：
    + $sum_(e_i in s_("index") and e_i in.not union.big_(s_l in X_0)s_l) a_i - b_("index") > 0$
    + rand(0, 1) < $eta_("index")$


    注意条件1所计算的是 *新* 被覆盖的元素 $e_i$ 所带来的利润

    本质上来说是以 $eta_("index")$ 的概率将为解集带来正收益的 $s_("index")$ 加入到解集中

    显然，构造初始解的时间复杂度为 $cal(O)(n^2)$

  ]
]

#slide(
  session: "LMSILS",
  title: "ILS"
)[

  #only(1)[
    构造完初始解后，进入到迭代局部搜索的过程，这个过程通过迭代执行一个两阶段的禁忌局部搜索算法完成

    整体的框架如下所示, 其中，$omega$ 表示迭代搜索的深度，$beta$ 表示禁忌搜索的深度，$gamma$ 表示扰动系数
  ]

  #only(2)[
    
    #algo(
      title: "ILS",
      parameters: ([$X_0$, $omega$, $beta$ ,$eta$, $epsilon.alt$, $gamma$],),
      breakable: true,
      row-gutter: 4mm,
      )[
        $X arrow.l X_0$\
        $X_"best" arrow.l X$\
        non_improve $arrow.l 0$\
        while non_improve < $omega$#i\
          $X arrow.l $ TwoPhase_LocalSearch(X, $beta$)\
          if $f(X) > f(X_"best")$#i\
            Update $eta "and" gamma$\
            $X_"best" arrow.l X$\
            non_improve $arrow.l 0$#d\
          else #i\
            non_improve $arrow.l$ non_improve + 1#d\
          $X arrow.l$ Perturbation($X_"best", gamma$)
      ]

  ]

  #only(3)[
    可以发现，主要问题集中在：
    + 两阶段的局部搜索过程
    + 如何更新 $eta$ 和 $epsilon.alt$
    + 如何做扰动
  ]

]

#slide(
  session: "LMSILS",
  title: "Two Phase Local Search"
)[
  #only(1)[
    我们首先引入一个算子 _Flip_，$"Flip"(s_i)$ 表示为将集合 $S_0$ 中的 $s_i$ 的状态进行反转，也就是说：

    如果 $s_i$ 在解集 $X$ 中，那么我们将其移除，否则，我们将 $s_i$ 加入到解集 $X$ 中
  ]

  #only((1, 2))[
    我们将通过 _Flip_ 算子变化后的解集用 $X xor "Flip"(X, i)$ 来表示
  ]
  
  #only((2, 3))[
    那么，一个可行解的邻域就可以显然的表示为：
    $cal(N)(X) = {X xor "Flip"(X, i), s_i in S_0}$

    于是，我们可以得到如下的两阶段局部搜索算法#footnote[注意，这里是分阶段进行的，我们首先进行翻转，然后再进行交换，而不是两个过程交替进行]：
    + 从翻转一次的邻域 $cal(N)_1(X)$ 中找到目标函数值最大的一个可行解，记为 $X^prime$，并更新最优解（如果 $X^prime$ 更优的话）
    + 从翻转两次的领域中 #pin(1)$cal(N)_2(X)$ #pin(2) 中找到目标函数值最大的一个可行解，记为 $X^prime$，并更新最优解（如果 $X^prime$ 更优的话）

    #only(3)[
      #pinit-highlight(1, 2)
      这里的 $cal(N)_2(X)$ 可以看作是一次交换的过程，使用 _Flip_ 算子表示为： $cal(N)_2(X) = {X xor "Flip"(X, i) xor "Flip"(X, j), s_i in X, s_j in.not X}$
    ]
  ]

  #only(4)[
    #set text(size: .9em)
    #grid(
     columns: (50%, 50%),
     column-gutter: 5mm,
     algo(
      title: "TwoPhase_LocalSearch",
      parameters: ([$X$, $beta$],),
     )[
      $X_b arrow.l X$\
      non_improve $arrow.l 0$\
      while non_improve = 0#i\
        non_improve $arrow.l 1$\
        $X arrow.l $ Flip_Tabu_Search($X$, $beta$)\
        $X arrow.l $ Swap_Search($X$)\
        if $f(X) > f(X_b)$#i\
          $X_b arrow.l X$\
          non_improve $arrow.l 0$#d#d\
     ],
     text(size: .8em)[
      #grid(
        rows: (70%, 30%),
        algo(
          title: "Flip_Tabu_Search",
          parameters: ([$X$, $beta$],),
          
        )[
          $X_b arrow.l X$\
          non_improve $arrow.l 0$\
          while non_improve $lt.eq beta$#i\
            $X^prime arrow.l cal(N)_1(X)$\
            $X arrow.l X^prime$\
            Update tabu list\
            if $f(X) > f(X_b)$#i\
              $X_b arrow.l X$\
              non_improve $arrow.l 0$#d\
            else#i\
              non_improve $arrow.l$ non_improve + 1#d#d\

            
        ],
        algo(
          title: "Swap_Search",
          parameters: ([$X$],),
        )[
          non_improve $arrow.l 1$\
          while non_improve = 0 #i\
            $X^prime arrow.l cal(N)_2(X)$\
            if ...
        ]
     ) 
     ]      
    )
  ]

  #only(5)[
    问题在与：
    + 禁忌搜索是如何工作的
    + 如何减小时间复杂度
  ]
]

#slide(
  session: "LMSILS",
  title: "Tabu Search"
)[
  #only(1)[
  我们只在第一阶段存在禁忌搜索，而这里有两种禁忌搜索策略：
    + 搜索深度的禁忌
    + 禁忌列表的禁忌

  对于深度的禁忌，十分容易理解，本质上就是多少次解没有更新，那么直接退出。
  ]

  #only(2)[
    第二种禁忌显然是为了避免我们重复访问邻域的解，于是，我们使用一个向量 $T in RR^n$，这个向量用于记录哪些子集已经使用过 _Flip_ 算子，其中：

    $T_i = cases(
      "Iter" + "rand"(0, 5) ", if" s_i "is added to " X,
      "Iter" + |S_0| ", if" s_i "is removed from " X, 
    )$

    这里，Iter 为当前的迭代数（也就是 `non_improve` 的值）

    禁忌策略为：如果当前的 $"Iter" < T_i$，除非翻转 $s_i$ 所获得的可行解比 $X_"best"$ 更好，否则 $s_i$ 被禁忌。
  ]
]

#slide(
  session: "LMSILS",
  title: "Fast Evaluation"
)[
  #only(1)[
    我们如何快速计算出 _Flip_ 算子为目标函数所带来的变化？

    在这里，我们维护一个向量 $delta in RR^n$，其中 $delta_i$ 表示 $s_i$ 在 _Flip_ 算子下的变化，也就是说：

    $Delta f("Flip"(X, i)) = f(X xor "Flip"(X, i)) - f(X) = delta_i$

    其计算公式为：
]

  #only((1, 2))[  
    $delta_i  = cases(
    sum_(e_j in s_i, |R_j sect X| = 0)a_j - b_i - theta_1 times c_k ", if" s_i in.not X,
    -sum_(e_j in s_i, |R_j sect X| = 1)a_j + b_i + theta_2 times c_k ", if" s_i in X, 
    )$

    而 $theta_1 = cases(
      1 ", if" g_k sect X = emptyset.rev,
      0 ", otherwise"
    )$, $theta_2 = cases(
    1 ", if " g_k sect X = s_i,
      0 ", otherwise" 
    )$, $e_j$ 表示 $s_i$ 中的元素，$R_j$ 表示含有 $e_j$ 的 $s_i$ 的并
  ]

  #only(2)[
    简而言之，当我们需要对 $s_i$ 进行一次翻转操作时，我们做如下操作：
    + $delta_i = -delta_i$
    + $forall s_j in g_k:(s_i in g_k)$，$delta_j = cases(
      delta_j - c_k ", if " (X sect g_k = {s_i} and s_i in X) or (X sect g_k = {s_j} and s_i in.not X),
      delta_j + c_k ", if " (X sect g_k = {s_i, s_j} and s_i in X) or (X sect g_k = emptyset.rev and s_i in.not X),
    )$
    + 对所有与 $s_i$ 中有相同元素 $e_j$ 的集合 $s_l$，
    $delta_l = cases(
      delta_l - a_j ", if " (X sect R_j = {s_i} and s_i in X) or (X sect R_j = {s_l} and s_i in.not X),
      delta_l + a_j ", if " (X sect R_j = {s_l, s_i} and s_i in X) or (X sect R_j = emptyset.rev and s_i in.not X),
    )$
  ]
  #only(3)[
    可以发现，维护 $delta$ 的时间复杂度为 $cal(O)(n times m)$
  ]
]

#slide(
  session: "LMSILS",
  title: "Update Learning Parameters"
)[
  #only((1, 2))[
    #grid(
      columns: 2,
      column-gutter: 5em,
      text(size: .9em)[
        我们回到算法框架：

        #only(2)[
          当结束两阶段局部搜索后\
          如果我们得到了一个更好的解\
          $X$，我们根据如下规则更新\
          $eta, epsilon.alt$

          其中 $eta_i$ 表示下一次初始化时\
          $s_i$ 在解中的概率

          $gamma$ 表示扰动系数
        ]

      ],
      text(size: .9em)[
        #algo(
      title: "ILS",
      parameters: ([$X_0$, $omega$, $beta$ ,$eta$, $epsilon.alt$, $gamma$],),
      breakable: true,
      row-gutter: 4mm,
      )[
        $X arrow.l X_0$\
        $X_"best" arrow.l X$\
        non_improve $arrow.l 0$\
        while non_improve < $omega$#i\
          $X arrow.l $ TwoPhase_LocalSearch(X, $beta$)\
          if $f(X) > f(X_"best")$#i\
            Update $eta "and" gamma$\
            $X_"best" arrow.l X$\
            non_improve $arrow.l 0$#d\
          else #i\
            non_improve $arrow.l$ non_improve + 1#d\
          $X arrow.l$ Perturbation($X_"best", gamma$)
        ]
      ]
    )
  ]
  #only(3)[
    更新的原理为：如果 $X$ 优于 $X_"best"$，则提高当前解 $X$ 中 $s_i$ 被选中的概率：

    #set align(center)
    $eta_i = cases(
     phi.alt_1 + (1 - phi.alt_1) times eta_i ", if" s_i in X and s_i in X_"best",
     phi.alt_2 + (1 - phi.alt_2) times eta_i ", if" s_i in X and s_i in.not X_"best",
     (1 - phi.alt_1) times eta_i ", if" s_i in.not X and s_i in.not X_"best",
     (1 - phi.alt_2) times eta_i ", if" s_i in.not X and s_i in X_"best",
    )$
    
    #set align(left)
    其中，$phi.alt_1 = 0.2, phi.alt_2 = 0.3$，并且，我们为此概率添加了平滑技术，用以避免历史信息的过度影响：

    #set align(center)
    $eta_i = cases(
      phi.alt_3 + (1 - phi.alt_3) times eta_i ", if" eta_i < 1- alpha,
      (1 - phi.alt_3) times eta_i ", if" eta_i > alpha
    )$

    #set align(left)
    这里的 $alpha = 0.95, phi.alt_3 = 0.3$
  ]

  #only(4)[
    关于扰动系数的更新，首先我们先看扰动的过程是什么样的
  ]
]

#slide(
  session: "LMSILS",
  title: "Perturbation"
)[
  #only((1, 2, 4, 6))[文中提出了两种扰动类型：
  + `Set_Perturbation`
  + `Group_Perturbation`
  ]

  #only(2)[
    `Set_Perturbation` 的做法为：
    + 令 $X = X_("best")$
    + 以概率 $p = 0.3$ 删除最优解 $X$ 的每个元素 $s_i$，设 $h$ 表示被删除的元素个数
    + 随机从 $S_0$ 中选择 $h$ 个元素，如果选择的元素不在 $X$ 中的话，则将其加入，否则跳过。
  ]

  #only(3)[
    #figure(
      image("fig/set_perturbation.png", height: 80%, fit: "contain"),
      caption: [$X_("best") = {s_2, s_3, s_5, s_6} arrow.r X = {s_2, s_3, s_6, s_9}$] 
    )
  ]

  #only(4)[
    `Group_Perturbation` 首先定义集合 $Z = {g_k|g_k sect X eq.not emptyset.rev, g_k in G}$
    + 令 $X = X_("best")$
    + 从 $Z$ 中随机选择 $max(p times |Z|, 1)$ 个元素，我们用 $z_j$ 来表示这些组
    + 假设 $z_j sect X_("best") = s_i$，那么我们从 $X$ 中删除这些元素
    + 随机从 $G - Z$ 中选择 $max(p times |Z|, 1)$ 个组
    + 从这些组中，随机翻转 $floor((|X_"best"|)/(|Z|))$ 个元素 $s_k$

    过程如下图所示
  ]

  #only(5)[
    #figure(
      image("fig/group_perturbation.png", height: 80%, fit: "contain"),
      caption: [$Z = {g_1, g_2} arrow.r "choose" g_1 arrow.r "choose" G-Z = {g_3}$] 
    )
  ]

  #only(6)[
    算法表示为：
    #algo(
      title: "Perturbation",
      parameters: ([$X$, $gamma = {gamma_1, gamma_2}$],),
    )[
      if rand(0, 1) < $gamma_1$ #i\
        $X arrow.l$ Set_Perturbation($X_"best"$)#d\
      else #i\
        $X arrow.l$ Group_Perturbation($X_"best"$)#d\
    ]
    这里的 $sum_(t=1)^2 gamma_t = 1$，最开始时 $gamma_t = 1/2$
  ]

]

#slide(
  session: "LMSILS",
  title: "Update Perturbation Ratio"
)[
  #only(1)[

    而对于扰动系数 $gamma in RR^2$，其更新规则如下：
    
    #set align(center)
    $gamma_t = (d_0 + d_t) / (2 times d_0 + d_1 + d_2)$

    #set align(left)
    其中 $t in {1, 2}$ 是扰动策略的编号，$d_0$ 为适应参数，$d_t$ 是采用第 $t$ 种扰动策略更新 $X_"best"$ 的次数

    文中，$d_0 = 50$

  ]
]

#slide(
  session: "LMSILS",
  title: "Experimental Evaluation"
)[
  #only(1)[
  实例：
    + 10个小型实例（$A^*, B^*$）， $|E| = 1000, |S| in [3493, 82635], |G| in [100, 300]$
    + 10个中型实例（$C^*, D^*$），$|E| = 5192, |S| in {6633, 117274}, |G| in {31, 62}$
    + 10个大型实例（$E^*, F^*$），$|E| = 15625, |S| in [10325, 462666], |G| in {96, 100}$

  对比算法为：
    + MILP(CPLEX)
    + ITS
    + Parallel ITS
    + LMSILS(this paper)
  ]
  #only(2)[
    #figure(
      image("fig/small-instance.png", height: 80%, fit: "contain"),
      caption: [$A^*, B^*$ 小型实例] 
    )
  ]
  #only(3)[
    #figure(
      image("fig/medium-instance.png", height: 80%, fit: "contain"),
      caption: [$C^*, D^*$ 中型实例] 
    )
  ]
  #only(4)[
    #figure(
      image("fig/big-instance.png", height: 80%, fit: "contain"),
      caption: [$E^*, F^*$ 大型实例] 
    )
  ]
]

