cimport libc.math as math
from libcpp cimport bool
from libcpp.algorithm cimport sort
from libcpp.limits cimport numeric_limits
from libcpp.vector cimport vector

from flatrtree.rtree import RTree


cdef struct Item:
    long long ref
    double minx
    double miny
    double maxx
    double maxy
    unsigned long hilbert


cdef bool item_comp(const Item &a, const Item &b):
    return a.hilbert < b.hilbert


cdef class HilbertBuilder:
    cdef long count
    cdef vector[Item] items
    cdef double minx, miny, maxx, maxy

    def __cinit__(self):
        self.count = 0
        self.minx = numeric_limits[double].infinity()
        self.miny = numeric_limits[double].infinity()
        self.maxx = -numeric_limits[double].infinity()
        self.maxy = -numeric_limits[double].infinity()

    cpdef void add(self, long long ref, double minx, double miny, double maxx, double maxy):
        self.count += 1
        self.items.push_back(Item(ref, minx, miny, maxx, maxy, 0))
        self.minx = math.fmin(self.minx, minx)
        self.miny = math.fmin(self.miny, miny)
        self.maxx = math.fmax(self.maxx, maxx)
        self.maxy = math.fmax(self.maxy, maxy)

    cpdef finish(self, long degree):
        if degree < 2:
            raise ValueError("degree < 2")

        if self.count == 0:
            return RTree(0, [], [])

        self._sort(degree)
        return self._pack(degree)

    cdef void _sort(self, long degree):
        if self.count <= degree:
            return

        cdef double xscale = 0
        cdef double yscale = 0

        cdef double width = self.maxx - self.minx
        if width > 0:
            xscale = 65535 / width

        cdef double height = self.maxy - self.miny
        if height > 0:
            yscale = 65535 / height

        cdef double midx, midy
        cdef unsigned long x, y
        for i in range(self.count):
            midx = (self.items[i].maxx + self.items[i].minx) / 2
            midy = (self.items[i].maxy + self.items[i].miny) / 2
            x = math.lround(xscale * (midx - self.minx))
            y = math.lround(yscale * (midy - self.miny))
            self.items[i].hilbert = hilbert(x, y)

        # Note: I wasn't able to get a perf gain with partial sorting. Any ideas?
        sort(self.items.begin(), self.items.end(), &item_comp)

    cdef _pack(self, long degree):
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

        cdef long num_nodes, count, j
        count = self.count
        num_nodes = count

        cdef long long start, end
        start, end = 0, boxes.size()
        refs.push_back(start)

        cdef double node_minx, node_miny, node_maxx, node_maxy

        while True:
            while start < end:
                node_minx = numeric_limits[double].infinity()
                node_miny = numeric_limits[double].infinity()
                node_maxx = -numeric_limits[double].infinity()
                node_maxy = -numeric_limits[double].infinity()

                j = 0
                while j < degree and start < end:
                    node_minx = math.fmin(node_minx, boxes[start])
                    node_miny = math.fmin(node_miny, boxes[start+1])
                    node_maxx = math.fmax(node_maxx, boxes[start+2])
                    node_maxy = math.fmax(node_maxy, boxes[start+3])
                    start += 4
                    j += 1

                refs.push_back(start)
                boxes.push_back(node_minx)
                boxes.push_back(node_miny)
                boxes.push_back(node_maxx)
                boxes.push_back(node_maxy)

            count = <long>(math.ceil(count / degree))
            num_nodes += count
            end = num_nodes * 4
            if count == 1:
                break

        return RTree(self.count, refs, boxes)


# Based on public domain code at https://github.com/rawrunprotected/hilbert_curves
cdef unsigned long hilbert(unsigned long x, unsigned long y):
    cdef unsigned long a, b, c, d
    a = x ^ y
    b = 0xFFFF ^ a
    c = 0xFFFF ^ (x | y)
    d = x & (y ^ 0xFFFF)

    cdef unsigned long A, B, C, D
    A = a | (b >> 1)
    B = (a >> 1) ^ a
    C = ((c >> 1) ^ (b & (d >> 1))) ^ c
    D = ((a & (c >> 1)) ^ (d >> 1)) ^ d

    a = A
    b = B
    c = C
    d = D
    A = (a & (a >> 2)) ^ (b & (b >> 2))
    B = (a & (b >> 2)) ^ (b & ((a ^ b) >> 2))
    C ^= (a & (c >> 2)) ^ (b & (d >> 2))
    D ^= (b & (c >> 2)) ^ ((a ^ b) & (d >> 2))

    a = A
    b = B
    c = C
    d = D
    A = (a & (a >> 4)) ^ (b & (b >> 4))
    B = (a & (b >> 4)) ^ (b & ((a ^ b) >> 4))
    C ^= (a & (c >> 4)) ^ (b & (d >> 4))
    D ^= (b & (c >> 4)) ^ ((a ^ b) & (d >> 4))

    a = A
    b = B
    c = C
    d = D
    C ^= (a & (c >> 8)) ^ (b & (d >> 8))
    D ^= (b & (c >> 8)) ^ ((a ^ b) & (d >> 8))

    a = C ^ (C >> 1)
    b = D ^ (D >> 1)

    cdef unsigned long i0, i1
    i0 = x ^ y
    i1 = b | (0xFFFF ^ (i0 | a))

    return (interleave(i1) << 1) | interleave(i0)


cdef inline interleave(unsigned long x):
    x = (x | (x << 8)) & 0x00FF00FF
    x = (x | (x << 4)) & 0x0F0F0F0F
    x = (x | (x << 2)) & 0x33333333
    x = (x | (x << 1)) & 0x55555555
    return x
