.PHONY: build run bundle open clean

# Compile a debug build.
build:
	swift build

# Run straight from the command line (no bundle). Ctrl-C to stop.
run:
	swift run

# Build a release .app bundle into dist/.
bundle:
	./scripts/bundle.sh

# Build the bundle and launch it.
open: bundle
	open dist/SitStandMove.app

clean:
	swift package clean
	rm -rf dist
