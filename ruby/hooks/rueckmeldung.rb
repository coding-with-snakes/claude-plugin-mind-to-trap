#!/usr/bin/env ruby
# UserPromptSubmit-Hook: erinnert bei jedem Prompt an die wichtigsten Regeln und gibt die Rückmeldung
# des Stop-Hooks einmal an Claude weiter.
require_relative "../lib/angebot"

eingabe = JSON.parse($stdin.read) rescue {}
datei = Angebot.datei(eingabe["session_id"])
inhalt = datei && Angebot.abholen(datei)
kontext = [Angebot::ERINNERUNG, inhalt.to_s[0, 300]].reject(&:empty?).join("\n")

puts JSON.generate("hookSpecificOutput" => { "hookEventName" => "UserPromptSubmit", "additionalContext" => kontext })
