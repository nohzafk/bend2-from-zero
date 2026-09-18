# gpu — `!` 与 Metal

在函数名后加 `!`，就是把这次调用交给 GPU：

```python
pow2!(26n)     # GPU
pow2(26n)      # CPU，但仍然是多核并行
```

## 编译产物长什么样

`bend file.bend -o name` 在原生产物旁边多生成一个 `name.gpu`：

```
$ file parallel/../gpu/pow2_gpu.gpu
... MetalLib executable (MacOS) ... applegpu_g15s
```

那是 **Metal 内核**，`name` 本身是主机程序，两个一起跑。

编译路径是 **Bend → C → clang**。可以直接读生成的 C：
`mandelbrot/main.c` 有 4174 行，来自 6427 字节的 `main.bend`。
它同时含 `#ifdef __METAL_VERSION__`，所以**同一份 C 既编出 CPU 版也编出 Metal 版**
—— `cpu` 和 `gpu` 两个二进制就是这么来的。

## 结论：GPU 不是白拿的

三个负载，全部原生编译。`cpu` 默认就用满所有核，`--threads 1` 是单核基准。
每个配置跑三遍，下表是稳定后的值：

| 负载 | CPU 1 线程 | CPU 10 线程 | GPU | GPU vs 10 核 |
|---|---|---|---|---|
| `pow2` 2^26 次加法 | 0.23 s | 0.04 s（8 线程） | 0.085 s | ❌ 慢 2.1× |
| `mandelbrot` 4096² × 51 轮 | 5.13 s | 0.72 s | **0.095 s** | ✅ **快 7.6×** |
| `queens` N=17 搜索 | 6.07 s | 0.85 s | 1.36 s | ❌ 慢 1.6× |

三个负载的校验和都和源码里记录的期望值一致（`3101455856` / `2063750025`），
所以这不是"跑了个假的"，是同一个计算在两块硬件上比。

**量的时候要注意两件事：**

- 宿主二进制**每次运行都会重新编译/装载 Metal 内核**，并往 stderr 打一行
  `bend: compiling the GPU program (... .gpu is missing or stale)`。
  这行不是错误，但别把它 `grep` 掉 —— 那个开销已经算在上面的 GPU 数字里。
- GPU 数字**第一次跑会明显偏慢**。我第一次量 mandelbrot 得到 0.226 s，
  重复跑稳定在 0.095 s，差 2.4 倍。所有数字都该跑三遍再记。

这正是指南里那句话，现在有数字了：

> The GPU shines on uniform numeric work like mandelbrot or nbody;
> divergent work like n-queens stays faster on the CPU.

- **pow2 输** —— 2^26 个任务每个只做 1 次加法，开销全在 fork/join 的调度上
- **mandelbrot 赢** —— 每个像素跑满 51 轮同样的算术，指令流完全统一
- **queens 输** —— 搜索树提前剪枝，各分支工作量天差地别，是分歧型负载

这是这个仓库里唯一一个"官方说法被我们自己量出来"的地方。

## 文件

| 路径 | 说明 |
|---|---|
| `pow2_gpu.bend` + `pow2_gpu` + `pow2_gpu.gpu` | 最小的 `!` 例子 |
| `mandelbrot/` | 4096² 逃逸时间渲染，均匀数值负载的代表 |
| `queens/` | N 皇后穷举搜索，分歧负载的代表 |

`mandelbrot/` 和 `queens/` 里的 `main.bend` 是与上游
`bend/bench/runtime/{mandelbrot,queens}/main.bend` **逐字节相同**的拷贝，
搬过来是为了让编译产物和源码放在一起。

## 跑

```sh
./gpu/mandelbrot/gpu                 # 0.095 s
./gpu/queens/cpu --threads 10        # 0.85 s
./gpu/pow2_gpu                       # 0.085 s
```
