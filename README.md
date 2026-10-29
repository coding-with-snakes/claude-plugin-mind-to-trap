# mind_the_trap

Psychologische und organisatorische Leitplanken für Claude Code, unabhängig von einem Task-System.

## Ziel

Claude soll den Dev nicht ablenken und ihm keine Überlegungen abnehmen. Der Dev führt und denkt, Claude liefert zu: kompakt, ohne Nebenbefunde, ohne ungefragte Vorschläge, Entscheidungen bleiben beim Dev.

## Installation (macOS)

```sh
claude plugin marketplace add ~/dev/claude-plugins/mind_the_trap
claude plugin install mind_the_trap@mind_the_trap
```

Das Plugin bringt den Output Style „Fokus“ (automatisch aktiv) und zwei Hooks mit. Danach neue Claude-Session starten.

Der Style überschreibt einen eigenen `outputStyle` des Users, solange das Plugin aktiv ist; pro Session gilt nur ein Output Style.

## Was Claude befolgt

- Kern zuerst, keine Floskeln, höchstens ein neuer Punkt pro Antwort; weitere über `1 einzeln · 2 Liste · 3 Todo`.
- Keine Angebote und keine Vorgaben zum nächsten Schritt; ein Stop-Hook meldet sie beim nächsten Prompt.
- Offene Fragen bekommen eine präzisierende Rückfrage; Antwort erst nach „mach trotzdem“.
- Höchstens eine Entscheidung pro Antwort; pauschale Freigaben („mach das“) erst nach bestätigter Liste.
- Aussagen mit Beleg oder „(vermutet)“.

Die vollständigen Regeln stehen in [`output-styles/fokus.md`](output-styles/fokus.md).

## Probleme

Prather et al. (2024), *The Widening Gap: The Benefits and Harms of Generative AI for Novice Programmers*, ICER 2024, [doi:10.1145/3632620.3671116](https://doi.org/10.1145/3632620.3671116), beschreiben Fallen, in die Programmieranfänger mit KI geraten (für erfahrene Devs nicht belegt):

| Falle | Stand | Wie |
|---|---|---|
| Interruption | reduziert | Keine Nebenbefunde, Optionslisten oder Angebote; ein Punkt pro Antwort; Stop-Hook meldet Angebote |
| Mislead | reduziert | Aussagen mit Beleg oder „(vermutet)“ |
| Assumption | teilweise | Offene Fragen werden präzisiert. Ein ausdrückliches Abschlusskriterium fehlt |
| Illusion of Competence | teilweise | Der Dev muss Fragen präzisieren und damit selbst denken; sein Verständnis wird nicht geprüft |
| Achievement, Progression | nicht gelöst | Nichts bremst nach gescheiterten Fix-Versuchen oder erkennt, wenn der Dev den Anschluss verliert |

Location und Task-Wechsel löst das Task-System [`goal`](../goal).

## Tests

```sh
ruby --disable-gems test/hooks_test.rb   # Angebotserkennung, Weitergabe pro Session, Symlinks
```
