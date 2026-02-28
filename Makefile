SWIFT ?= swift
TARGET ?= Nibble
SCRATCH_PATH ?= $(HOME)/Library/Caches/nibble-spm-build

.PHONY: build run release clean

build:
	$(SWIFT) build --scratch-path "$(SCRATCH_PATH)"

run:
	$(SWIFT) run --scratch-path "$(SCRATCH_PATH)" $(TARGET)

release:
	$(SWIFT) build -c release --scratch-path "$(SCRATCH_PATH)"

clean:
	rm -rf "$(SCRATCH_PATH)"
