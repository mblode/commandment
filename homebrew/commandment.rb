cask "commandment" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/mblode/commandment/releases/download/v#{version}/Commandment-#{version}.dmg"
  name "Commandment"
  desc "macOS menu bar dictation app using OpenAI transcription"
  homepage "https://github.com/mblode/commandment"

  depends_on macos: ">= :sequoia"

  app "Commandment.app"

  zap trash: [
    "~/Library/Preferences/co.blode.commandment.plist",
    "~/Library/Application Support/co.blode.commandment",
  ]
end
