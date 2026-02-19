SCHEME = Commandment
CONFIGURATION = Release
DERIVED_DATA = /tmp/commandment-build
ARCHIVE_PATH = $(DERIVED_DATA)/Commandment.xcarchive
EXPORT_PATH = $(DERIVED_DATA)/export
APP_NAME = Commandment
DMG_PATH = $(DERIVED_DATA)/$(APP_NAME).dmg
BUNDLE_ID = co.blode.commandment
VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")

CODESIGN_IDENTITY ?= Developer ID Application
TEAM_ID ?= $(APPLE_TEAM_ID)

.PHONY: build archive export dmg notarize clean

build:
	xcodebuild -scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		MARKETING_VERSION=$(VERSION) \
		build

test:
	xcodebuild -scheme $(SCHEME) \
		-configuration Debug \
		-destination 'platform=macOS' \
		-derivedDataPath $(DERIVED_DATA) \
		MARKETING_VERSION=$(VERSION) \
		test

archive:
	xcodebuild -scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		-archivePath $(ARCHIVE_PATH) \
		CODE_SIGN_STYLE=Manual \
		CODE_SIGN_IDENTITY="$(CODESIGN_IDENTITY)" \
		DEVELOPMENT_TEAM="$(TEAM_ID)" \
		MARKETING_VERSION=$(VERSION) \
		archive

export: archive
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n\
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
	<plist version="1.0">\n\
	<dict>\n\
		<key>method</key>\n\
		<string>developer-id</string>\n\
		<key>teamID</key>\n\
		<string>$(TEAM_ID)</string>\n\
		<key>signingStyle</key>\n\
		<string>manual</string>\n\
		<key>signingCertificate</key>\n\
		<string>Developer ID Application</string>\n\
	</dict>\n\
	</plist>' > $(DERIVED_DATA)/ExportOptions.plist
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist $(DERIVED_DATA)/ExportOptions.plist

dmg: export
	@rm -f $(DMG_PATH)
	create-dmg \
		--volname "$(APP_NAME)" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon-size 128 \
		--icon "$(APP_NAME).app" 150 190 \
		--app-drop-link 450 190 \
		--hide-extension "$(APP_NAME).app" \
		--no-internet-enable \
		$(DMG_PATH) \
		$(EXPORT_PATH)/$(APP_NAME).app || test -f $(DMG_PATH)
	@echo "DMG created at $(DMG_PATH)"

notarize: dmg
	xcrun notarytool submit $(DMG_PATH) \
		--apple-id "$(NOTARIZE_APPLE_ID)" \
		--password "$(NOTARIZE_PASSWORD)" \
		--team-id "$(TEAM_ID)" \
		--wait
	xcrun stapler staple $(DMG_PATH)
	@echo "Notarized: $(DMG_PATH)"

clean:
	rm -rf $(DERIVED_DATA)
