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

  # Gibt die Angebots-Formulierung im letzten Absatz zurück, sonst nil.
  # Eine Antwort, die nur aus einer kurzen Rückfrage besteht, gilt nicht als Angebot.
  def am_schluss(text)
    text = text.to_s.strip
    absaetze = text.split(/\n\s*\n/)
    nur_rueckfrage = absaetze.size == 1 && text.end_with?("?") && text.split(/\s+/).size <= 40
    return nil if nur_rueckfrage

    absaetze.last.to_s[MUSTER]
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
