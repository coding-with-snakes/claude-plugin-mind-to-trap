#!/usr/bin/env ruby
# Prüft die Angebotserkennung und die Weitergabe der Rückmeldung in einem temporären Verzeichnis.
# Aufruf: ruby --disable-gems test/hooks_test.rb
require "fileutils"
require "open3"
require "tmpdir"
require_relative "../ruby/lib/angebot"

ROOT = File.expand_path("..", __dir__)

$fehler = 0
def pruefe(name, ok)
  puts "#{ok ? 'ok    ' : 'FEHLER'} #{name}"
  $fehler += 1 unless ok
end

Dir.mktmpdir do |tmp|
  env = { "TMPDIR" => tmp, "HOME" => tmp, "PATH" => ENV["PATH"] }
  lauf = lambda do |skript, eingabe|
    out, = Open3.capture2(env, "ruby", "--disable-gems", File.join(ROOT, skript),
                          stdin_data: JSON.generate(eingabe), unsetenv_others: true)
    out
  end

  # Eine Rückmeldung mit Umlauten erreicht den nächsten Prompt genau einmal.
  lauf.call("ruby/hooks/stop_check.rb", "session_id" => "s1", "last_assistant_message" => "Fertig.\n\nMöchtest du mehr?")
  out = lauf.call("ruby/hooks/rueckmeldung.rb", "session_id" => "s1")
  pruefe("Rückmeldung mit Umlauten erreicht Claude", out.include?("Möchtest du"))
  pruefe("Rückmeldung wird danach gelöscht", !lauf.call("ruby/hooks/rueckmeldung.rb", "session_id" => "s1").include?("Möchtest du"))
  pruefe("Erinnerung kommt bei jedem Prompt", lauf.call("ruby/hooks/rueckmeldung.rb", "session_id" => "s1").include?("Mehr als 3 Punkte"))

  # Rückmeldungen bleiben in ihrer Session.
  lauf.call("ruby/hooks/stop_check.rb", "session_id" => "s2", "last_assistant_message" => "Fertig.\n\nSoll ich weiter?")
  pruefe("andere Session sieht die Rückmeldung nicht", !lauf.call("ruby/hooks/rueckmeldung.rb", "session_id" => "s3").include?("Rückmeldung:"))

  # Der Stop-Hook schreibt nicht durch einen Symlink.
  geheim = File.join(tmp, "geheim")
  File.write(geheim, "GEHEIM")
  File.symlink(geheim, File.join(tmp, "mind_the_trap-s4.txt"))
  lauf.call("ruby/hooks/stop_check.rb", "session_id" => "s4", "last_assistant_message" => "Fertig.\n\nSoll ich weiter?")
  pruefe("Stop-Hook überschreibt Symlink-Ziel nicht", File.read(geheim) == "GEHEIM")
  pruefe("Symlink wird nicht gelesen", !lauf.call("ruby/hooks/rueckmeldung.rb", "session_id" => "s4").include?("GEHEIM"))

  # Eine reine Rückfrage gilt nicht als Angebot, ein angehängtes Angebot und eine Vorgabe schon.
  pruefe("kurze Rückfrage wird nicht gemeldet", Angebot.am_schluss("Willst du die Ursache finden oder schon den Fix?").nil?)
  pruefe("angehängtes Angebot wird gemeldet", !Angebot.am_schluss("Der Fix ist drin.\n\nWillst du auch die Tests?").nil?)
  pruefe("Vorgabe zum nächsten Schritt wird gemeldet", !Angebot.am_schluss("Fertig.\n\nNächster Schritt: Session neu starten.").nil?)
  pruefe("normaler Schluss wird nicht gemeldet", Angebot.am_schluss("Fertig.\n\nDie Regel greift ab sofort.").nil?)

  # Der Stop-Hook blockiert Listen ab 4 Punkten und das alte Auswahlformat, ausser nach „2“.
  vier = "1. a\n2. b\n3. c\n4. d"
  pruefe("Liste mit 4 Punkten wird blockiert", lauf.call("ruby/hooks/stop_check.rb", "session_id" => "s5", "last_assistant_message" => vier).include?('"decision":"block"'))
  pruefe("Liste mit 3 Punkten wird nicht blockiert", lauf.call("ruby/hooks/stop_check.rb", "session_id" => "s5", "last_assistant_message" => "1. a\n2. b\n3. c").empty?)
  pruefe("altes Auswahlformat wird blockiert", lauf.call("ruby/hooks/stop_check.rb", "session_id" => "s5", "last_assistant_message" => "Noch 2 Punkte: 1 einzeln · 2 Liste · 3 Todo").include?('"decision":"block"'))
  pruefe("stop_hook_active blockiert nicht erneut", lauf.call("ruby/hooks/stop_check.rb", "session_id" => "s5", "stop_hook_active" => true, "last_assistant_message" => vier).empty?)
  transkript = File.join(tmp, "t.jsonl")
  File.write(transkript, JSON.generate("type" => "user", "message" => { "role" => "user", "content" => "2" }) + "\n" +
                         JSON.generate("type" => "user", "message" => { "role" => "user", "content" => [{ "type" => "tool_result", "content" => "x" }] }) + "\n")
  pruefe("Liste nach „2“ ist erlaubt", lauf.call("ruby/hooks/stop_check.rb", "session_id" => "s5", "transcript_path" => transkript, "last_assistant_message" => vier).empty?)
end

puts $fehler.zero? ? "Alle Tests bestanden." : "#{$fehler} Test(s) fehlgeschlagen."
exit($fehler.zero? ? 0 : 1)
