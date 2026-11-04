#!/usr/bin/env ruby
# Stop-Hook: blockiert Antworten mit einer Liste ab 4 Punkten oder dem alten Auswahlformat, damit Claude
# sie neu formuliert. Merkt sich ausserdem, wenn eine Antwort mit einem Angebot oder einer Vorgabe zum
# nächsten Schritt endete; das meldet der nächste Prompt, ohne zu blockieren.
require_relative "../lib/angebot"

eingabe = JSON.parse($stdin.read) rescue {}
exit if eingabe["stop_hook_active"]

grund = Angebot.verstoss(eingabe["last_assistant_message"])
if grund && !Angebot.alle_angezeigt?(eingabe["transcript_path"])
  puts JSON.generate("decision" => "block", "reason" => grund)
  exit
end

treffer = Angebot.am_schluss(eingabe["last_assistant_message"])
datei = Angebot.datei(eingabe["session_id"])
exit unless treffer && datei

Angebot.schreiben(datei, "Rückmeldung: Die letzte Antwort endete mit einem Angebot oder einer Vorgabe zum " \
                         "nächsten Schritt („#{treffer}“). Regeln 1.3 und 2: Antworten enden mit dem Inhalt.")
