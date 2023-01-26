from flatrtree.rtree import RTree

class HilbertBuilder:
    def add(self, ref: int, minx: float, miny: float, maxx: float, maxy: float): ...
    def finish(self, degree: int) -> RTree: ...

class OMTBuilder:
    def add(self, ref: int, minx: float, miny: float, maxx: float, maxy: float): ...
    def finish(self, degree: int) -> RTree: ...

def geodetic_box_dist(
    plon: float,
    plat: float,
    minlon: float,
    minlat: float,
    maxlon: float,
    maxlat: float,
) -> float: ...
def planar_box_dist(
    px: float,
    py: float,
    minx: float,
    miny: float,
    maxx: float,
    maxy: float,
) -> float: ...
