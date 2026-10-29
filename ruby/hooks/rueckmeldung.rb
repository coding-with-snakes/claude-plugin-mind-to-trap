#!/usr/bin/env ruby
# UserPromptSubmit-Hook: gibt die Rückmeldung des Stop-Hooks einmal an Claude weiter.
require_relative "../lib/angebot"

eingabe = JSON.parse($stdin.read) rescue {}
datei = Angebot.datei(eingabe["session_id"])
inhalt = datei && Angebot.abholen(datei)
exit if inhalt.nil? || inhalt.empty?

puts JSON.generate("hookSpecificOutput" => { "hookEventName" => "UserPromptSubmit", "additionalContext" => inhalt[0, 300] })
