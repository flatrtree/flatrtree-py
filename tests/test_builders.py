import unittest

from flatrtree import HilbertBuilder, OMTBuilder


class HilbertBuilderTest(unittest.TestCase):
    def test_invalid_degree(self):
        for builder_cls in (HilbertBuilder, OMTBuilder):
            for invalid_degree in (-1, 0, 1):
                builder = builder_cls()
                builder.add(0, 0, 0, 0, 0)

                with self.assertRaisesRegex(ValueError, "degree < 2"):
                    builder.finish(invalid_degree)
