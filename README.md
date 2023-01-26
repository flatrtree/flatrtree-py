# Flatrtree - Python

Flatrtree is a serialization format and set of libraries for reading and writing R-trees. It's directly inspired by [Flatbush](https://github.com/mourner/flatbush) and [FlatGeobuf](https://github.com/flatgeobuf/flatgeobuf), and aims to make tiny, portable R-trees accessible in new contexts.

- Store R-trees to disk or transport them over a network.
- Build R-trees in one language and query them in another.
- Query R-trees before reading the data they index.

## Installation

```console
$ pip install --pre flatrtree
```

## Usage

Flatrtree separates building and querying behavior. The builder doesn’t know how to query an index and the index doesn’t know how it was built. This is inspired by [FlatBuffers](https://google.github.io/flatbuffers/).

```python
import flatrtree

# Add items to a builder object
builder = flatrtree.HilbertBuilder() # or OMTBuilder or your own
for i, item in enumerate(items):
    # The first argument is an integer reference to the item being indexed
    builder.add(i, item.minx, item.miny, item.maxx, item.maxy)

degree = 10 # node capacity

# Create an R-tree object from the builder
rtree = builder.finish(degree)

# Search for items that intersect a bounding box
for i in rtree.search(minx, miny, maxx, maxy):
    item = items[i]
    # ...

# Supply a function for calculating the distance between bounding boxes
# Planar and geodetic functions are included in the library
box_dist = flatrtree.planar_box_dist

# Find the nearest neighbors with a custom halt condition
for i, dist in rtree.neighbors(x, y, box_dist):
    if dist > maxDist:
        break
    item = item[i]
    dist # units match the given box distance function
```

## Serialization

Flatrtree uses [protocol buffers](https://protobuf.dev/) for serialization, taking advantage of varint encoding to reduce the output size in bytes. There are many tradeoffs to explore for serialization and this seems like a good place to start. It wouldn’t be hard to roll your own format with something like FlatBuffers if that better fit your needs.

```python
# Specify the level of decimal precision you need.
# The output size will decrease as precision decreases.
precision = 7

# Serialize to bytes for storage and/or transport.
data = flatrtree.serialize(rtree, precision)

# Load the R-tree from bytes.
rtree = flatrtree.deserialize(data)
```

## Example Usage

This example builds an R-tree from a newline-delimited GeoJSON file and stores it to disk. The R-tree holds the offset of each feature from the beginning of the file.

```python
import json
import flatrtree
from shapely.geometry import shape

builder = flatrtree.HilbertBuilder()

with open("us-block-groups.json") as f:
    pos = f.tell()
    line = f.readline()

    while line:
        feature = json.loads(line)
        geom = shape(feature["geometry"])
        minx, miny, maxx, maxy = geom.bounds

        builder.add(pos, minx, miny, maxx, maxy)

        pos = f.tell()
        line = f.readline()


rtree = builder.finish(flatrtree.DEFAULT_DEGREE)

with open("us-block-groups.json.idx", "wb") as f:
    f.write(flatrtree.serialize(rtree, precision=6))
```

The next example reads the R-tree from disk and searches by a bounding box to find the relevant features. By seeking directly to the GeoJSON features returned by the search, we only read and parse the required data.

```python
import json
import flatrtree

with open("us-block-groups.json.idx", "rb") as f:
    rtree = flatrtree.deserialize(f.read())

results = []
with open("tests/us-block-groups.json") as f:
    minx, miny, maxx, maxy = -96.985931, 32.630123, -96.571198, 32.914180
    for pos in rtree.search(minx, miny, maxx, maxy):
        f.seek(pos)
        feature = json.loads(f.readline())
        results.append(feature)
```

The next example finds all neighbors with bounds intersecting a radius of the given point.

```python
import json
import flatrtree

with open("us-block-groups.json.idx", "rb") as f:
    rtree = flatrtree.deserialize(f.read())

neighbors = []
with open("us-block-groups.json") as f:
    x, y = -96.985931, 32.630123
    for pos, meters in rtree.neighbors(x, y, flatrtree.geodetic_box_dist):
        if meters > 500:
            break
        f.seek(pos)
        feature = json.loads(f.readline())
        neighbors.append(feature)
```
