cimport libc.math as math

earth_radius = 6371e3  # meters
twoPI = 2 * math.pi
halfPI = math.pi / 2


def geodetic_box_dist(
    plon: float,
    plat: float,
    minlon: float,
    minlat: float,
    maxlon: float,
    maxlat: float,
) -> float:
    return earth_radius * _point_rect_dist_geodetic_rad(
        (plon * math.pi) / 180,
        (plat * math.pi) / 180,
        (minlon * math.pi) / 180,
        (minlat * math.pi) / 180,
        (maxlon * math.pi) / 180,
        (maxlat * math.pi) / 180,
    )


# Copyright (c) 2016 Josh Baker

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

cdef double _point_rect_dist_geodetic_rad(
    double pX,
    double pY,
    double minX,
    double minY,
    double maxX,
    double maxY,
):
    # Simple case, point or invalid rect
    if minY >= maxY and minX >= maxX:
        return _dist_rad(minX, minY, pX, pY)

    if minX <= pX and pX <= maxX:
        # q is between the bounding meridians of r
        # hence, q is north, south or within r
        if minY <= pY and pY <= maxY:  # Inside
            return 0

        if pY < minY:  # South
            return minY - pY

        return pY - maxY  # North

    # determine if q is closer to the east or west edge of r to select edge for
    # tests below
    cdef double dX_east, dX_west

    dX_east = minX - pX
    dX_west = pX - maxX
    if dX_east < 0:
        dX_east += twoPI

    if dX_west < 0:
        dX_west += twoPI

    cdef double dX, edgeX

    if dX_east <= dX_west:
        dX = dX_east
        edgeX = minX
    else:
        dX = dX_west
        edgeX = maxX

    cdef double sin_dX, cos_dX, tan_pY

    sin_dX = math.sin(dX)
    cos_dX = math.cos(dX)
    tan_pY = math.tan(pY)

    if dX >= halfPI:
        # If Δλ > 90 degrees (1/2 pi in radians) we're in one of the corners
        # (NW/SW or NE/SE depending on the edge selected). Compare against the
        # center line to decide which case we fall into
        if tan_pY >= math.tan((maxY + minY) / 2) * cos_dX:
            return _dist_rad(pX, pY, edgeX, maxY)  # North corner
        return _dist_rad(pX, pY, edgeX, minY)  # South corner

    if tan_pY >= math.tan(maxY) * cos_dX:
        return _dist_rad(pX, pY, edgeX, maxY)  # North corner

    if tan_pY <= math.tan(minY) * cos_dX:
        return _dist_rad(pX, pY, edgeX, minY)  # South corner

    # We're to the East or West of the rect, compute distance using cross-track
    # Note that this is a simplification of the cross track distance formula
    # valid since the track in question is a meridian.
    return math.asin(math.cos(pY) * sin_dX)


# distance on the unit sphere computed using Haversine formula
cdef double _dist_rad(double aX, double aY, double bX, double bY):
    if aY == bY and aX == bX:
        return 0

    cdef dX, dY, sin_dY, sin_dX, cos_aY, cos_bY

    dY = aY - bY
    dX = aX - bX
    sin_dY = math.sin(dY / 2)
    sin_dX = math.sin(dX / 2)
    cos_aY = math.cos(aY)
    cos_bY = math.cos(bY)

    return 2 * math.asin(math.sqrt(sin_dY * sin_dY + sin_dX * sin_dX * cos_aY * cos_bY))


def planar_box_dist(
    px: float,
    py: float,
    minx: float,
    miny: float,
    maxx: float,
    maxy: float,
) -> float:
    cdef double dx, dy

    if px < minx:
        dx = minx - px
    elif px <= maxx:
        dx = 0
    else:
        dx = px - maxx

    if py < miny:
        dy = miny - py
    elif py <= maxy:
        dy = 0
    else:
        dy = py - maxy

    return dx * dx + dy * dy
