#!/usr/bin/env python
import platform

from Cython.Build import cythonize
from setuptools import Extension, setup


ext_modules = cythonize(
    [
        Extension(
            "flatrtree.box_dist",
            ["src/flatrtree/box_dist.pyx"],
            language="c",
            extra_compile_args=["-O3"],
        ),
        Extension(
            "flatrtree.hilbert_builder",
            ["src/flatrtree/hilbert_builder.pyx"],
            language="c++",
            extra_compile_args=["-O3"],
        ),
        Extension(
            "flatrtree.omt_builder",
            sources=["src/flatrtree/omt_builder.pyx"],
            language="c++",
            extra_compile_args=["-O3", "-std=c++11"],
        ),
    ],
    compiler_directives={"language_level": 3},
)

if platform.python_implementation() == "CPython":
    # Only run mypyc on CPython, not PyPy, etc.
    from mypyc.build import mypycify

    ext_modules += mypycify(
        ["src/flatrtree/rtree.py", "src/flatrtree/serialization.py"]
    )

setup(ext_modules=ext_modules)
