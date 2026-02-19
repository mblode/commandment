cask "commandment" do
  version "0.1.0"
  sha256 "d4bbee645f0ab6f55042622e010d680e04b5f2bb8b93fe1674f2c1b7b2b83e20"

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
