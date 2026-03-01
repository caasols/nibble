SWIFT ?= swift
TARGET ?= Nibble
SCRATCH_PATH ?= $(HOME)/Library/Caches/nibble-spm-build

.PHONY: build run app release release-hygiene-test lint lint-fix lint-check clean

build:
	$(SWIFT) build --scratch-path "$(SCRATCH_PATH)"

run:
	$(SWIFT) run --scratch-path "$(SCRATCH_PATH)" $(TARGET)

app:
	chmod +x build.sh
	SCRATCH_PATH="$(SCRATCH_PATH)" ./build.sh

release:
	$(SWIFT) build -c release --scratch-path "$(SCRATCH_PATH)"

release-hygiene-test:
	chmod +x scripts/release/check-artifact-hygiene.sh scripts/release/check-artifact-hygiene.test.sh
	scripts/release/check-artifact-hygiene.test.sh

lint:
	swiftlint lint

lint-fix:
	swiftformat . && swiftlint lint --fix && swiftlint lint

lint-check:
	swiftformat --lint . && swiftlint lint

clean:
	rm -rf "$(SCRATCH_PATH)"
