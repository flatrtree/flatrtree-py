import unittest

from flatrtree import deserialize, serialize
from tests.utils import create_test_cases


class SerializationTest(unittest.TestCase):
    def setUp(self):
        self.test_cases = create_test_cases()

    def test_serialization_roundtrip(self):
        for tc in self.test_cases:
            with self.subTest(tc.name):
                out = deserialize(serialize(tc.index, 5))

                self.assertEqual(tc.index.count, out.count)
                self.assertEqual(tc.index.refs, out.refs)
                self.assertEqual(tc.index.boxes, out.boxes)

    def test_empty(self):
        index = deserialize(b"")
        self.assertEqual(0, index.count)
        self.assertEqual(0, len(index.refs))
        self.assertEqual(0, len(index.boxes))
