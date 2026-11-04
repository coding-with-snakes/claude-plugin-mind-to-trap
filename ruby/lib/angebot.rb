# Erkennt Antworten, die mit einem Angebot oder einer Vorgabe zum nächsten Schritt enden, und reicht
# die Rückmeldung pro Session über eine Datei in $TMPDIR an den nächsten Prompt weiter.
# Läuft mit der macOS-System-Ruby (2.6).
require "json"
require "tmpdir"

Encoding.default_external = Encoding::UTF_8

module Angebot
  module_function

  # Formulierungen, mit denen eine Antwort ein ungefragtes Angebot macht.
  MUSTER = /\b(soll ich|sollen wir|möchtest du|willst du|wollen wir|als nächstes|nächste[rn]? schritt|jetzt\b[^.\n]{0,40}prüf\w*|next step|want me to|shall i|should i|would you like|let me know)\b/i
  MAX_DATEI = 1024
  MAX_PUNKTE = 3
  LISTENZEILE = /^\s*(?:\d+\.|[-*])\s/
  ALTE_AUSWAHL = "1 einzeln · 2 Liste · 3 Todo"
  LESEN = 262_144
  # Kurzfassung der wichtigsten Regeln aus fokus.md; steht bei jedem Prompt direkt vor der Frage.
  ERINNERUNG = "Fokus: Erste Zeile ist die Antwort. Nur das Gefragte: Lösungsvorschläge nur auf Aufforderung, " \
               "Nebenbefunde höchstens ein Satz am Ende. Mehr als 3 Punkte nie als Liste, sondern „<n> Punkte“ " \
               "mit der Auswahl 1. Einzeln anzeigen, 2. Alle anzeigen, 3. Als Todo-Task. Keine Angebote am Ende."

  # Gibt die Angebots-Formulierung im letzten Absatz zurück, sonst nil.
  # Eine Antwort, die nur aus einer kurzen Rückfrage besteht, gilt nicht als Angebot.
  def am_schluss(text)
    text = text.to_s.strip
    absaetze = text.split(/\n\s*\n/)
    nur_rueckfrage = absaetze.size == 1 && text.end_with?("?") && text.split(/\s+/).size <= 40
    return nil if nur_rueckfrage

    absaetze.last.to_s[MUSTER]
  end

  # Gibt den Grund zurück, wenn die Antwort eine blockierte Regel verletzt, sonst nil.
  def verstoss(text)
    text = text.to_s
    if text.include?(ALTE_AUSWAHL)
      return "Die Auswahl steht im alten Format. Regel 2: „<n> Punkte“ und die Zeilen „1. Einzeln anzeigen“, „2. Alle anzeigen“, „3. Als Todo-Task“."
    end

    lauf = 0
    text.each_line do |zeile|
      lauf = zeile.match?(LISTENZEILE) ? lauf + 1 : 0
      return "Die Antwort listet mehr als #{MAX_PUNKTE} Punkte. Regel 1.9: zeige nur „<n> Punkte“ mit der Auswahl aus Regel 2." if lauf > MAX_PUNKTE
    end
    nil
  end

  # Wahr, wenn der letzte Prompt des Devs „2“ war („Alle anzeigen“); dann ist eine lange Liste erlaubt.
  def alle_angezeigt?(transcript)
    st = File.lstat(transcript.to_s)
    return false unless st.file? && st.owned?

    ende = File.open(transcript, File::RDONLY | File::NOFOLLOW) { |f| f.seek([st.size - LESEN, 0].max); f.read }
    prompt = nil
    ende.to_s.force_encoding(Encoding::UTF_8).scrub.each_line do |zeile|
      eintrag = JSON.parse(zeile) rescue next
      inhalt = eintrag["type"] == "user" ? eintrag.dig("message", "content") : nil
      inhalt = Array(inhalt).map { |b| b.is_a?(Hash) ? b["text"] : b }.compact.join if inhalt
      prompt = inhalt unless inhalt.nil? || inhalt.empty?
    end
    prompt.to_s.strip.match?(/\A2\.?\z/)
  rescue SystemCallError, TypeError
    false
  end

  # Eine Datei pro Session; die Session-ID wird auf sichere Zeichen beschränkt.
  def datei(session_id)
    id = session_id.to_s.gsub(/[^A-Za-z0-9-]/, "")[0, 64]
    return nil if id.empty?

    File.join(Dir.tmpdir, "mind_the_trap-#{id}.txt")
  end

  # Schreibt ohne Symlinks zu folgen.
  def schreiben(pfad, inhalt)
    File.open(pfad, File::WRONLY | File::CREAT | File::TRUNC | File::NOFOLLOW, 0o600) { |f| f.write(inhalt) }
    true
  rescue SystemCallError
    false
  end

  # Liest nur eine eigene, reguläre Datei (keinen Symlink) und löscht sie danach.
  def abholen(pfad)
    st = File.lstat(pfad)
    return nil unless st.file? && st.owned? && st.size <= MAX_DATEI

    inhalt = File.open(pfad, File::RDONLY | File::NOFOLLOW) { |f| f.read(MAX_DATEI) }
    File.delete(pfad)
    inhalt.to_s.force_encoding(Encoding::UTF_8).scrub.gsub(/[[:cntrl:]]/, " ").strip
  rescue SystemCallError
    nil
  end
end
