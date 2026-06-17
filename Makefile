.PHONY: build run bundle open install clean

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

# Install the app into /Applications (so it's not tied to this source tree).
install: bundle
	rm -rf /Applications/SitStandMove.app
	cp -R dist/SitStandMove.app /Applications/
	@echo "Installed to /Applications/SitStandMove.app"
	@echo "Launch it, then right-click the menu bar icon -> Launch at Login to auto-start."

clean:
	swift package clean
	rm -rf dist
