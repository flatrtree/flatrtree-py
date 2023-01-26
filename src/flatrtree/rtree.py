from heapq import heappop, heappush
from typing import Callable, Iterator, List, Optional, Tuple


class RTree:
    __slots__ = ("count", "refs", "boxes")

    def __init__(self, count: int, refs: List[int], boxes: List[float]):
        self.count = count
        self.refs = refs
        self.boxes = boxes

    def search(
        self, minx: float, miny: float, maxx: float, maxy: float
    ) -> Iterator[int]:
        if self.count == 0:
            return

        root_ref_idx = len(self.refs) - 2
        queue: List[int] = [root_ref_idx]

        while len(queue) > 0:
            ref_idx = queue.pop()
            for child_node_idx in range(self.refs[ref_idx], self.refs[ref_idx + 1], 4):
                if not (
                    maxx < self.boxes[child_node_idx]
                    or maxy < self.boxes[child_node_idx + 1]
                    or minx > self.boxes[child_node_idx + 2]
                    or miny > self.boxes[child_node_idx + 3]
                ):
                    child_ref_idx = child_node_idx // 4
                    if child_ref_idx < self.count:
                        yield self.refs[child_ref_idx]
                    else:
                        queue.append(child_ref_idx)

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
    ) -> Iterator[Tuple[int, float]]:
        if self.count == 0:
            return

        root_ref_idx = len(self.refs) - 2
        queue: List[Tuple[float, int]] = [(0, root_ref_idx)]

        while len(queue) > 0:
            _, ref_idx = heappop(queue)
            for child_node_idx in range(self.refs[ref_idx], self.refs[ref_idx + 1], 4):
                child_ref_idx = child_node_idx // 4
                if child_ref_idx < self.count and item_dist is not None:
                    dist = item_dist(x, y, self.refs[child_ref_idx])
                else:
                    dist = box_dist(
                        x,
                        y,
                        self.boxes[child_node_idx],
                        self.boxes[child_node_idx + 1],
                        self.boxes[child_node_idx + 2],
                        self.boxes[child_node_idx + 3],
                    )
                heappush(queue, (dist, child_ref_idx))

            while len(queue) > 0 and queue[0][1] < self.count:
                dist, leaf_ref_idx = heappop(queue)
                yield self.refs[leaf_ref_idx], dist
