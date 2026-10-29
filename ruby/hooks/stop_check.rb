#!/usr/bin/env ruby
# Stop-Hook: merkt sich, wenn eine Antwort mit einem Angebot oder einer Vorgabe zum nächsten Schritt
# endete. Blockiert bewusst nicht – eine erzwungene Nachbesserung würde nur zusätzlichen Text erzeugen.
require_relative "../lib/angebot"

eingabe = JSON.parse($stdin.read) rescue {}
exit if eingabe["stop_hook_active"]

treffer = Angebot.am_schluss(eingabe["last_assistant_message"])
datei = Angebot.datei(eingabe["session_id"])
exit unless treffer && datei

Angebot.schreiben(datei, "Rückmeldung: Die letzte Antwort endete mit einem Angebot oder einer Vorgabe zum " \
                         "nächsten Schritt („#{treffer}“). Regeln 1.3 und 2: Antworten enden mit dem Inhalt.")
