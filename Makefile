.PHONY: check test

VESSEL_BIN := $(shell vessel bin)
VESSEL_SOURCES := $(shell vessel sources 2>/dev/null)

check:
	# Just checks the syntax of the files.
	find internal src -type f -name '*.mo' -exec $(VESSEL_BIN)/moc $(VESSEL_SOURCES) --check {} +

test:
    # Make sure to add `--package core` to the `moc` if you want to test the core library.
	find test -type f -name '*.mo' -exec $(VESSEL_BIN)/moc $(VESSEL_SOURCES) --package core src -r {} +
