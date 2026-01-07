#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  template: "article",
  title: [A Survey],
  info: [MaxSAT-XOR / PB-XOR / CryptoTool],
  author: "Virgil",
  time: datetime.today().display(),
  // abstract: [摘要内容],
  // keywords: ("关键词1", "关键词2", "关键词3"),
  font-size: 12pt,
  content-depth: 2,
  matheq-depth: 2,
  counter-depth: 2,
  cb-counter-depth: 2,
  header: true,
  lang: "zh",
  par-indent: 2em,
  par-leading: 1em,
  par-spacing: 1em,
)

= CNF-XOR 的优化版本

#note(subname: "#SAT 为什么引入了 XOR")[
  考虑 ApproxMC4，算法中存在基于哈希的过滤（Hashing-based Partitioning），通过引入 XOR 语句来，将解空间做划分。

  ApproxMC4 不断向 SAT 求解器发送 $"CNF" and "XORs"$ 的查询来探索 Model。如果一个子空间内的解较为稠密，那么增加多个 XOR 约束。
]

#newpara()

Ermon 等人提出的 WISH 算法@ermon2013optimization 证明了，可以通过解决一系列“MaxSAT + 随机 XOR 约束”的问题，来近似推算出复杂的积分值。于是，GaussMaxHS@soos2021gaussian 以 MaxHS 为基础，通过集成高斯消元法（Gaussian Elimination），使其能够在搜索过程的每一个层级（而不只是顶层）处理 XOR 约束。


IGMaxHS@lubke2024igmaxhs 为了解决量子计算中的纠错（Error Correction），引入了一个支持增量式求解的 MaxSAT+XOR 求解器（GuassianMaxHS 的增量式版本），即在不重启求解器的情况下，可以不断往里添加新约束。

= PB-XOR

LinPB@yang2021engineering


= 密码

#claim(subname: [会议时间#footnote[https://ccfddl.top/]])[

  未截稿：
  - #link("https://crypto.iacr.org/2026/")[
      CRYPTO 2026 (美密会)： 2026-02-13 19:59:59
    ]

  已截稿：

  - #link("https://asiacrypt.iacr.org/2025/")[
      ASIACRYPT 2025 (亚密会)： 2025-05-16 19:59:59
    ]

  - #link("https://eurocrypt.iacr.org/2026/")[
      EUROCRYPT 2026 (欧密会)：2025-10-03 19:59:59
    ]
]

#note(subname: "Benchmark")[

  - #link("https://github.com/void-zxh/SAT4CryptoBench")[SAT4CryptoBench]

  - #link("https://cryptanalysisbench.github.io/SATbench/")[The SAT Cryptanalysis Benchmarks Suite]
]

== 调研

单独的密码工具似乎比较少，例如 WDSAT#cite(<trimoska2020parity>)，求解 ANF 好用（ANF 对于密码形式友好，转为 CNF+XOR 会增加子句长度与个数）。

以及一些编码/攻击方式，例如对于AES的旁路攻击#cite(<dubrova2024solving>)。

#pagebreak()

#bibliography("ref.bib")
