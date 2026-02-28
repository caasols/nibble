SWIFT ?= swift
TARGET ?= Nibble
SCRATCH_PATH ?= $(HOME)/Library/Caches/nibble-spm-build

.PHONY: build run app release clean

build:
	$(SWIFT) build --scratch-path "$(SCRATCH_PATH)"

run:
	$(SWIFT) run --scratch-path "$(SCRATCH_PATH)" $(TARGET)

app:
	chmod +x build.sh
	SCRATCH_PATH="$(SCRATCH_PATH)" ./build.sh

release:
	$(SWIFT) build -c release --scratch-path "$(SCRATCH_PATH)"

clean:
	rm -rf "$(SCRATCH_PATH)"
