import math

from flatrtree.internal import flatrtree_pb2
from flatrtree.rtree import RTree


def serialize(rtree: RTree, precision: int) -> bytes:
    scale = math.pow(10, precision)
    msg = flatrtree_pb2.RTree(
        count=rtree.count,
        refs=rtree.refs,
        boxes=(round(c * scale) for c in rtree.boxes),
        precision=precision,
    )
    return msg.SerializeToString()


def deserialize(data: bytes) -> RTree:
    msg = flatrtree_pb2.RTree()
    msg.ParseFromString(data)
    scale = math.pow(10, msg.precision)
    return RTree(
        count=msg.count,
        refs=list(msg.refs),
        boxes=[float(c) / scale for c in msg.boxes],
    )
