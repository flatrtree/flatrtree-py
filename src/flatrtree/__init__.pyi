from typing import Callable, Iterator, List, Optional, Tuple

DEFAULT_DEGREE: int

class RTree:
    def __init__(self, count: int, refs: List[int], boxes: List[float]): ...
    def search(
        self, minx: float, miny: float, maxx: float, maxy: float
    ) -> Iterator[int]: ...
    def neighbors(
        self,
        x: float,
        y: float,
        box_dist: Callable[
            # x, y, minx, miny, maxx, maxy
            [float, float, float, float, float, float],
            float,  # dist
        ],
        item_dist: Optional[
            Callable[
                # x, y, ref
                [float, float, int],
                float,  # dist
            ]
        ] = None,
    ) -> Iterator[Tuple[int, float]]: ...

def serialize(rtree: RTree, precision: int) -> bytes: ...
def deserialize(data: bytes) -> RTree: ...

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
