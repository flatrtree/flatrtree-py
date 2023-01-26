import math
import unittest
from collections import defaultdict

from flatrtree import HilbertBuilder, geodetic_box_dist, planar_box_dist
from tests.utils import create_test_cases


class TestRTree(unittest.TestCase):
    def setUp(self):
        self.test_cases = create_test_cases()

    def test_tree_structure(self):
        for tc in self.test_cases:
            with self.subTest(tc.name):
                for node_index in range(0, len(tc.index.boxes), 4):
                    ref_index = node_index // 4

                    minx = tc.index.boxes[node_index]
                    miny = tc.index.boxes[node_index + 1]
                    maxx = tc.index.boxes[node_index + 2]
                    maxy = tc.index.boxes[node_index + 3]

                    self.assertLessEqual(minx, maxx, tc.name)
                    self.assertLessEqual(miny, maxy, tc.name)

                    if ref_index < tc.index.count:
                        ref = tc.index.refs[ref_index]
                        self.assertEqual(minx, tc.items[ref * 4], tc.name)
                        self.assertEqual(miny, tc.items[ref * 4 + 1], tc.name)
                        self.assertEqual(maxx, tc.items[ref * 4 + 2], tc.name)
                        self.assertEqual(maxy, tc.items[ref * 4 + 3], tc.name)
                    else:
                        start = tc.index.refs[ref_index]
                        end = tc.index.refs[ref_index + 1]
                        for child_node_index in range(start, end, 4):
                            child_minx = tc.index.boxes[child_node_index]
                            child_miny = tc.index.boxes[child_node_index + 1]
                            child_maxx = tc.index.boxes[child_node_index + 2]
                            child_maxy = tc.index.boxes[child_node_index + 3]
                            self.assertLessEqual(minx, child_minx, tc.name)
                            self.assertLessEqual(miny, child_miny, tc.name)
                            self.assertGreaterEqual(maxx, child_maxx, tc.name)
                            self.assertGreaterEqual(maxy, child_maxy, tc.name)

    def test_search(self):
        for tc in self.test_cases:
            with self.subTest(tc.name):
                for i in range(tc.count):
                    minx = tc.items[i * 4]
                    miny = tc.items[i * 4 + 1]
                    maxx = tc.items[i * 4 + 2]
                    maxy = tc.items[i * 4 + 3]

                    actual = list(tc.index.search(minx, miny, maxx, maxy))

                    expected = []
                    for j in range(tc.count):
                        if maxx < tc.items[j * 4]:
                            continue
                        if maxy < tc.items[j * 4 + 1]:
                            continue
                        if minx > tc.items[j * 4 + 2]:
                            continue
                        if miny > tc.items[j * 4 + 3]:
                            continue
                        expected.append(j)

                    actual.sort()
                    expected.sort()

                    self.assertEqual(actual, expected)

    def test_search_everything(self):
        for tc in self.test_cases:
            with self.subTest(tc.name):
                refs = list(tc.index.search(-math.inf, -math.inf, math.inf, math.inf))
                self.assertEqual(tc.index.count, len(refs))
                self.assertEqual(len(refs), len(set(refs)))

    def test_search_early_termination(self):
        for tc in self.test_cases:
            with self.subTest(tc.name):
                # cutoff the test search at about 1/4 of the items
                cutoff = math.ceil(tc.index.count / 4)

                count = 0
                for _ in tc.index.search(-math.inf, -math.inf, math.inf, math.inf):
                    count += 1
                    if count == cutoff:
                        break

                self.assertEqual(cutoff, count)

    def test_neighbors(self):
        for tc in self.test_cases:
            with self.subTest(tc.name):
                for box_dist_func in (planar_box_dist, geodetic_box_dist):
                    for i in range(tc.count):
                        midx = (tc.items[i * 4] + tc.items[i * 4 + 2]) / 2
                        midy = (tc.items[i * 4 + 1] + tc.items[i * 4 + 3]) / 2

                        expected_refs_by_dist = defaultdict(list)
                        for j in range(tc.count):
                            d = box_dist_func(midx, midy, *tc.items[j * 4 : j * 4 + 4])
                            expected_refs_by_dist[d].append(j)

                        actual_refs_by_dist = defaultdict(list)
                        for ref, dist in tc.index.neighbors(midx, midy, box_dist_func):
                            actual_refs_by_dist[dist].append(ref)

                        self.assertEqual(
                            list(sorted(expected_refs_by_dist.keys())),
                            list(sorted(actual_refs_by_dist.keys())),
                        )

                        for dist in expected_refs_by_dist:
                            expected_refs_by_dist[dist].sort()
                            actual_refs_by_dist[dist].sort()
                            self.assertEqual(
                                expected_refs_by_dist[dist], actual_refs_by_dist[dist]
                            )

    def test_neighbors_early_termination(self):
        for tc in self.test_cases:
            with self.subTest(tc.name):
                # cutoff the test search at about 1/4 of the items
                cutoff = math.ceil(tc.index.count / 4)

                count = 0
                for _ in tc.index.neighbors(0, 0, planar_box_dist):
                    count += 1
                    if count == cutoff:
                        break

                self.assertEqual(cutoff, count)

    def test_neighbors_with_item_dist(self):
        builder = HilbertBuilder()

        p_x = -112.084665
        p_y = 33.470112

        boxes = [
            # closest bounding box, farthest actual distance
            [-112.108612, 33.451423, -112.082519, 33.473262],
            # farthest bounding box, closest actual distance
            [-112.080888, 33.472976, -112.073764, 33.473048],
        ]

        distances = [
            1.204e07,
            1.203e07,
        ]

        def item_dist(lon: float, lat: float, ref: int) -> float:
            return distances[ref]

        for i, box in enumerate(boxes):
            builder.add(i, box[0], box[1], box[2], box[3])

        index = builder.finish(8)

        self.assertEqual(
            [0, 1], [ref for ref, _ in index.neighbors(p_x, p_y, geodetic_box_dist)]
        )

        self.assertEqual(
            [1, 0],
            [ref for ref, _ in index.neighbors(p_x, p_y, geodetic_box_dist, item_dist)],
        )


if __name__ == "__main__":
    unittest.main()
