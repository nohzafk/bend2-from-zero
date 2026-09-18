# The law of the parallel Life step.
#
# The parallel step is a fork/join tree: a leaf serially computes `blk` cells,
# a join concatenates the two halves. The law says the tree produces exactly
# the cells that one plain sequential loop over the same range would produce,
# in the same order. It is the same claim demos/pure_par_sum makes about its
# parallel sum, with a list of cells in place of a number.
#
# Written by hand, not by the AI. PROOF.bend proves it.
import Base
import ./life_par.bend as Par

# LAW: for any depth d, grid g of width w and height h, block size blk and
# starting cell k, the tree covers the cells_in(d, blk) cells from k on and
# yields them in order. (cells_in(d, blk) is 2^d * blk, computed by the same
# recursion the tree uses rather than by a multiplication.)
law tree_is_serial:
  for +d: Nat
  for +g: List<&2, Nat>
  for +w: Nat
  for +h: Nat
  for +blk: Nat
  for +k: Nat
  {Par.tree_cells(d, g, w, h, blk, k) == Par.block(g, w, h, Par.cells_in(d, blk), k) : List<&2, Nat>}
