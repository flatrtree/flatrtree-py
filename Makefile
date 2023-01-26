SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.PHONY: default clean proto


PY_PATH=src/flatrtree/internal
PY_PROTO_PATH=$(PY_PATH)/flatrtree_pb2.py
PYI_PROTO_PATH=$(PY_PATH)/flatrtree_pb2.pyi


default: proto

clean:
	rm -rf $(PY_PROTO_PATH) $(PYI_PROTO_PATH)

proto: $(PY_PROTO_PATH) $(PYI_PROTO_PATH)

$(PY_PROTO_PATH): $(PYI_PROTO_PATH)

$(PYI_PROTO_PATH):
	protoc -I=spec/ \
		--python_out=$(PY_PATH) \
		--pyi_out=$(PY_PATH) \
		flatrtree.proto
