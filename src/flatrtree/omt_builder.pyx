cimport libc.math as math
from libcpp cimport bool
from libcpp.limits cimport numeric_limits
from libcpp.pair cimport pair
from libcpp.stack cimport stack
from libcpp.vector cimport vector

from flatrtree.rtree import RTree


cdef struct Item:
    long long ref
    double minx
    double miny
    double maxx
    double maxy


cdef bool item_minx_comp(const Item &a, const Item &b):
    return a.minx < b.minx


cdef bool item_miny_comp(const Item &a, const Item &b):
    return a.miny < b.miny


cdef class OMTBuilder:
    cdef long count
    cdef vector[Item] items
    cdef vector[vector[long]] node_sizes
    cdef vector[vector[double]] node_boxes

    def __cinit__(self):
        self.count = 0

    cpdef void add(self, long long ref, double minx, double miny, double maxx, double maxy):
        self.count += 1
        self.items.push_back(Item(ref, minx, miny, maxx, maxy))

    cpdef finish(self, long degree):
        if degree < 2:
            raise ValueError("degree < 2")

        if self.count == 0:
            return RTree(0, [], [])

        cdef target_height = max(<long>(math.ceil(math.log(self.count) / math.log(degree))), 1)
        self.node_sizes.resize(target_height)
        self.node_boxes.resize(target_height)

        self._build(degree, 0, self.count, target_height-1)
        return self._pack()

    cdef _build(self, long degree, long start, long end, long level):
        cdef N = end - start
        cdef child_count = <long>math.ceil(N / math.pow(degree, level))

        cdef minx = numeric_limits[double].infinity()
        cdef miny = numeric_limits[double].infinity()
        cdef maxx = -numeric_limits[double].infinity()
        cdef maxy = -numeric_limits[double].infinity()

        if N <= child_count:
            for i in range(start, end):
                minx = math.fmin(minx, self.items[i].minx)
                miny = math.fmin(miny, self.items[i].miny)
                maxx = math.fmax(maxx, self.items[i].maxx)
                maxy = math.fmax(maxy, self.items[i].maxy)

            self._add_node(level, N, minx, miny, maxx, maxy)
            return minx, miny, maxx, maxy

        cdef long node_size = 0
        cdef long node_capacity = <long>math.ceil(N / <double>child_count)
        cdef long slice_capacity = <long>(node_capacity * math.ceil(math.sqrt(child_count)))
        cdef long slice_start, slice_end, child_start, child_end

        sort_items(self.items, start, end, slice_capacity, &item_minx_comp)

        for slice_start in range(start, end, slice_capacity):
            slice_end = min(slice_start + slice_capacity, end)

            sort_items(self.items, slice_start, slice_end, node_capacity, &item_miny_comp)

            for child_start in range(slice_start, slice_end, node_capacity):
                child_end = min(child_start + node_capacity, slice_end)

                child_minx, child_miny, child_maxx, child_maxy = self._build(
                    degree,
                    child_start,
                    child_end,
                    level-1,
                )

                minx = math.fmin(minx, child_minx)
                miny = math.fmin(miny, child_miny)
                maxx = math.fmax(maxx, child_maxx)
                maxy = math.fmax(maxy, child_maxy)
                node_size += 1

        self._add_node(level, node_size, minx, miny, maxx, maxy)
        return minx, miny, maxx, maxy

    cdef _pack(self):
        cdef vector[long long] refs
        cdef vector[double] boxes

        refs.reserve(self.count)
        boxes.reserve(4 * self.count)

        for i in range(self.count):
            refs.push_back(self.items[i].ref)
            boxes.push_back(self.items[i].minx)
            boxes.push_back(self.items[i].miny)
            boxes.push_back(self.items[i].maxx)
            boxes.push_back(self.items[i].maxy)

        cdef long long ref = 0
        refs.push_back(ref)

        for level in range(self.node_sizes.size()):
            for i in range(self.node_sizes[level].size()):
                ref += 4 * self.node_sizes[level][i]
                refs.push_back(ref)
                boxes.push_back(self.node_boxes[level][i*4])
                boxes.push_back(self.node_boxes[level][i*4+1])
                boxes.push_back(self.node_boxes[level][i*4+2])
                boxes.push_back(self.node_boxes[level][i*4+3])

        return RTree(self.count, refs, boxes)

    cdef void _add_node(self, long level, long size, double minx, double miny, double maxx, double maxy):
        self.node_sizes[level].push_back(size)
        self.node_boxes[level].push_back(minx)
        self.node_boxes[level].push_back(miny)
        self.node_boxes[level].push_back(maxx)
        self.node_boxes[level].push_back(maxy)


cdef extern from "floyd_rivest_select.h" namespace "miniselect" nogil:
    inline void floyd_rivest_select[Iter, Compare](Iter, Iter, Iter, Compare)


ctypedef bool (*item_cmp_type)(const Item&, const Item&)
ctypedef pair[long, long] span


# This is a port of the algorithm used by RBush (https://github.com/mourner/rbush)
cdef void sort_items(vector[Item] &items, long left, long right, long n, item_cmp_type item_comp):
    cdef stack[span] s
    cdef long mid

    s.push(span(left, right))

    while not s.empty():
        p = s.top()
        s.pop()

        left = p.first
        right = p.second

        if right - left <= n:
            continue

        mid = left + <long>math.ceil((right - left) / n / 2) * n

        floyd_rivest_select(
            items.begin() + left,
            items.begin() + mid,
            items.begin() + right,
            item_comp,
        )

        s.push(span(left, mid))
        s.push(span(mid, right))
