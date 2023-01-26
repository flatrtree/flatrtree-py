from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Iterable as _Iterable, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class RTree(_message.Message):
    __slots__ = ["boxes", "count", "precision", "refs"]
    BOXES_FIELD_NUMBER: _ClassVar[int]
    COUNT_FIELD_NUMBER: _ClassVar[int]
    PRECISION_FIELD_NUMBER: _ClassVar[int]
    REFS_FIELD_NUMBER: _ClassVar[int]
    boxes: _containers.RepeatedScalarFieldContainer[int]
    count: int
    precision: int
    refs: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, count: _Optional[int] = ..., refs: _Optional[_Iterable[int]] = ..., boxes: _Optional[_Iterable[int]] = ..., precision: _Optional[int] = ...) -> None: ...
