# gpu — `!` 与 Metal

在函数名后加 `!`，就是把这次调用交给 GPU：

```python
pow2!(26n)     # GPU
pow2(26n)      # CPU，但仍然是多核并行
```

## 编译产物长什么样

`bend file.bend -o name` 在原生产物旁边多生成一个 `name.gpu`：

```
$ file gpu/pow2_gpu.gpu
... MetalLib executable (MacOS) ... applegpu_g15s
```

那是 **Metal 内核**，`name` 本身是主机程序，两个一起跑。

编译路径是 **Bend → C → clang**。可以直接读生成的 C：
`mandelbrot/main.c` 有 4174 行，来自 6427 字节的 `main.bend`。
它同时含 `#ifdef __METAL_VERSION__`，所以**同一份 C 既编出 CPU 版也编出 Metal 版**。

## ⚠️ 每个 `!` 程序要先交约 85ms 的「入场费」

**这是这个目录最重要的一个数字，也是最初量错的原因。**

写一个几乎不干活的 `!` 程序来量地板：同样的 fork-join 树，只要 `pow2!(2n)`，结果是 4。

```
gpu_floor   pow2!(2n)      = 4          82 – 91 ms
pow2_gpu    pow2!(26n) = 67108864       89 – 96 ms
```

**6700 万次加法和 4 几乎一样贵。** 所以那 85ms 基本全是入场，不是干活。

同一进程里调两次也只多几毫秒：

```
gpu_twice   pow2!(25n) + pow2!(26n)     97 – 114 ms
```

所以它是**每个进程一次**的固定成本，不是每次调用的税。

而且它**不是内核编译** —— 尽管 stderr 那行 `compiling the GPU program (...)` 会让人这么以为。
`gpu_floor` 的内核极小，和 mandelbrot 的大内核一样贵。花掉的是 Metal 运行时本身：
device、command queue、pipeline state。

（`gpu_floor` / `gpu_twice` 就是这两个探针，源码留在本目录。）

## 三个负载：原始数字

全部原生编译，每个配置跑三遍。`cpu` 默认用满所有核，`--threads 1` 是单核基准。

| 负载 | CPU 1 线程 | CPU 10 线程 | GPU | 校验和 |
|---|---|---|---|---|
| `pow2` 2^26 次加法 | 0.226 s | 0.049 s（8 线程） | 0.089 – 0.096 s | 67108864 |
| `mandelbrot` 4096² × 51 | 5.103 – 5.116 s | 0.722 s | 0.108 – 0.127 s | 3101455856 |
| `queens` N=17 搜索 | 6.058 – 6.112 s | 0.854 – 0.859 s | 1.338 – 1.420 s | 2063750025 |

校验和都和源码注释里记录的期望值一致，所以这不是「跑了个假的」。

## 扣除入场费之后，结论全部变形

| 负载 | GPU 总计 | 减掉 85ms | CPU 10 线程 | 谁真的赢 |
|---|---|---|---|---|
| `pow2` | 0.093 s | **低于噪声** | 0.049 s | 算术几乎是白送的，你只是在付进门费 |
| `mandelbrot` | 0.118 s | **~0.03 s** | 0.722 s | **GPU，约 20×** |
| `queens` | 1.38 s | **~1.29 s** | 0.855 s | CPU，而且差得不小 |

- **pow2 不是「GPU 算得慢」。** 2^26 次加法在 GPU 上快到测不出来。让 `pow2!(26n)` 端到端输掉的是那扇 85ms 的门。
  > **更正（2026-09-18）**：这个 README 原来写的是「开销全在 fork/join 的调度上」。**这是错的。**
  > fork-join 恰恰是 CPU 做得好的事；`gpu_floor` 里已经没有任何 fork-join 可做了，照样付 85ms。
- **mandelbrot 的胜利比看上去大得多。** 常被引用的「7.6×」低估了硬件也高估了价格。诚实的两个数字是：
  ~30ms 的 GPU 工作 对 722ms 的 10 核 CPU 工作，外加一笔真实应用只付一次的固定门费。
- **queens 是真的输。** ~1.29s 的 GPU 工作 对 0.855s，和指南那句分歧型负载的说法一致。

一句话：**GPU 的墙钟数字不是关于 GPU 的陈述，而是关于「GPU + 一笔不随工作量缩小的固定成本」的陈述。
想知道你在量哪一个，就写一个什么都不干的程序去量它。**

## 量的时候注意

- 宿主二进制**每次运行都会重新编译/装载 Metal 内核**，并往 stderr 打一行
  `bend: compiling the GPU program (... .gpu is missing or stale)`。
  这行不是错误，但别把它 `grep` 掉 —— 那个开销已经算在上面的 GPU 数字里。
- GPU 数字**第一次跑会明显偏慢**。第一次量 mandelbrot 得到 0.226 s，重复跑稳定在 0.108 s。
  所有数字都该跑三遍再记。
- `gpu/mandelbrot/gpu.gpu` 目前在磁盘上不存在（`gpu` 二进制每次运行都重建内核，且不回写）。
  重新跑一次 `bend main.bend -o gpu` 会重新生成它。

## 文件

| 路径 | 说明 |
|---|---|
| `gpu_floor.bend` / `gpu_twice.bend` | **量入场费的两个探针** |
| `pow2_gpu.bend` + `pow2_gpu` + `pow2_gpu.gpu` | 最小的 `!` 例子 |
| `mandelbrot/` | 4096² 逃逸时间渲染，均匀数值负载的代表 |
| `queens/` | N 皇后穷举搜索，分歧负载的代表 |

`mandelbrot/` 和 `queens/` 里的 `main.bend` 是与上游
`bend/bench/runtime/{mandelbrot,queens}/main.bend` **逐字节相同**的拷贝。

## 怎么重新编出两个二进制

CLI **没有** `--gpu` 开关（`bend --help` 只有 `-o` / `--checkup` / `--publish`）。两条路分开：

```sh
# GPU 版：默认构建，同时产出主机程序和 Metal 内核
bend main.bend -o gpu            # → gpu + gpu.gpu

# CPU 版：先让 bend 吐 C，再自己用 clang 编（这样不链 Metal）
bend main.bend -o main.c
clang -O2 main.c -o cpu -lm
```

## 跑

```sh
bend gpu_floor.bend -o gpu_floor && ./gpu_floor    # 入场费：~85ms，结果是 4
./mandelbrot/gpu                                   # 0.108 s
./queens/cpu --threads 10                          # 0.855 s
```
