package dev.ullmann.lumo;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;

/** Local, bounded explanations of an already checked lesson. No scoring API. */
public final class LumoLearningDialogLogic {
    private LumoLearningDialogLogic() {}

    public static final class Context {
        public final String kind;
        public final int a, b, extra;
        public final String word, plantPart, explanation;
        public final List<String> syllables, patternUnit;

        public Context(String kind, int a, int b, int extra, String word,
                       String plantPart, String explanation, List<String> syllables,
                       List<String> patternUnit) {
            this.kind = kind;
            this.a = a;
            this.b = b;
            this.extra = extra;
            this.word = word;
            this.plantPart = plantPart;
            this.explanation = explanation;
            this.syllables = Collections.unmodifiableList(new ArrayList<>(syllables));
            this.patternUnit = Collections.unmodifiableList(new ArrayList<>(patternUnit));
        }
    }

    public static final class Reply {
        public final String text, action, objectId;
        public final boolean slower;
        Reply(String text, String action, String objectId, boolean slower) {
            this.text = text;
            this.action = action;
            this.objectId = objectId;
            this.slower = slower;
        }
    }

    public static boolean isStop(String input) {
        String q = normalized(input).replaceAll("[.!?]+$", "");
        return q.matches("(?:bitte )?(?:stopp?|halt|pause|aufhören|sei still)(?: bitte)?");
    }

    private static String normalized(String input) {
        return input == null ? "" : input.toLowerCase(Locale.GERMAN).trim().replaceAll("\\s+", " ");
    }

    public static Reply answer(Context c, String input, String requestedAction) {
        String q = normalized(input);
        if (isStop(q) || "stop".equals(requestedAction)) {
            return new Reply("", "stop", "", false);
        }
        boolean slow = "slower".equals(requestedAction) ||
            q.matches(".*(?:langsam|nicht so schnell|zu schnell|schritt für schritt).*" );
        String action = slow ? "slower" :
            ("repeat".equals(requestedAction) || q.matches(".*(?:noch einmal|nochmal|wiederhol).*"))
                ? "repeat" : "hint".equals(requestedAction) ? "hint" : "explain";
        if (q.matches(".*(?:ich meinte|ich meine|falsch verstanden|verhört).*")) {
            return new Reply("Ändere deine Antwort in der Aufgabe. Du entscheidest mit „Prüfen“, " +
                "welche Antwort gezählt wird.", action, "task_prompt", slow);
        }
        switch (c.kind) {
            case "bridge_ten":
            case "addition":
                if (c.a > 0 && c.a < 10 && c.b > 0 && c.b <= 10 && c.a + c.b > 10) {
                    int missing = 10 - c.a;
                    int remainder = c.b - missing;
                    return new Reply("Im Zehnerfeld liegen " + c.a + ". Bis zehn fehlen " + missing +
                        ", denn 10 minus " + c.a + " ist " + missing + ". Deshalb nehmen wir zuerst " +
                        missing + " von den " + c.b + ". Danach bleiben " + remainder + " übrig.",
                        action, "bridge_two", slow);
                }
                return new Reply("Lege zuerst die " + c.a + " Objekte hin. Füge dann " + c.b +
                    " hinzu. Zähle alle Objekte gemeinsam, ohne eines doppelt zu zählen.", action, "ten_frame", slow);
            case "subtract_ten":
                return new Reply("Am Anfang liegen " + c.a + " Objekte. Nimm " + c.b +
                    " davon weg. Die übrigen Objekte zeigen, was nach dem Wegnehmen bleibt.", action, "task_model", slow);
            case "equal_groups":
                return new Reply("Wir bilden " + c.a + " gleich große Gruppen. In jede Gruppe kommen " + c.b +
                    " Objekte. Zähle die Gruppen nacheinander. Jede Gruppe muss gleich viele enthalten.", action, "task_model", slow);
            case "equal_sharing":
                return new Reply("Verteile " + c.a + " Objekte auf " + c.b +
                    " Gruppen. Gib jeder Gruppe reihum ein Objekt. Am Ende sollen alle gleich viele haben.", action, "task_model", slow);
            case "bridge_hundred":
                int next = (c.a / 100 + 1) * 100;
                return new Reply("Von " + c.a + " bis " + next + " fehlen " + (next - c.a) +
                    ". Ergänze zuerst diesen Teil. Von den " + c.b +
                    " bleibt dann noch ein zweiter Teil zum Hinzufügen.", action, "task_model", slow);
            case "fraction_parts":
                return new Reply("Das Ganze ist in " + c.b + " gleich große Teile geteilt. " +
                    "Die untere Zahl zählt alle Teile. Die obere Zahl zählt nur die markierten. " +
                    "Die Größe der Teile bleibt gleich.", action, "task_model", slow);
            case "syllables":
                if (!c.syllables.isEmpty() && String.join("", c.syllables).equals(c.word)) {
                    return new Reply(c.word + " hat diese Sprechstücke: " + String.join(" – ", c.syllables) +
                        ". Sprich jedes Stück mit und klatsche dazu einmal. Wir zählen Sprechstücke, nicht Buchstaben.",
                        action, "syllable_0", slow);
                }
                break;
            case "pattern":
                if (!c.patternUnit.isEmpty()) {
                    List<String> labels = new ArrayList<>();
                    for (String shape : c.patternUnit) labels.add(shapeName(shape));
                    return new Reply("Schau auf die Gruppe " + String.join(" – ", labels) +
                        ". Dieselbe Gruppe kommt danach noch einmal. Suche den Anfang der nächsten Gruppe. " +
                        "Du wählst selbst, welche Form weitergeht.", action, "pattern_group", slow);
                }
                break;
            case "plant_parts":
                String explanation;
                switch (c.plantPart) {
                    case "root": explanation = "Die Wurzel hält die Pflanze in der Erde und nimmt Wasser auf."; break;
                    case "stem": explanation = "Der Stängel trägt die Pflanze und leitet Wasser nach oben."; break;
                    case "leaf": explanation = "Die Blätter nutzen Licht. Damit kann die Pflanze eigene Nahrung herstellen."; break;
                    default: explanation = "Aus den Blüten vieler Pflanzen können Früchte mit Samen entstehen.";
                }
                return new Reply(explanation + " Schau dir diesen Pflanzenteil an.", action, "task_model", slow);
            default:
                break;
        }
        String help = c.explanation == null ? "" : c.explanation.trim();
        if (help.isEmpty()) help = "Lies zuerst die Frage. Schau dann auf das Lernobjekt und die Antwortmöglichkeiten. " +
            "Du kannst deine Antwort in der Aufgabe selbst prüfen.";
        return new Reply(help, action, "task_prompt", slow);
    }

    private static String shapeName(String value) {
        String shape = value.substring(value.lastIndexOf('_') + 1);
        switch (shape) {
            case "circle": return "Kreis";
            case "square": return "Quadrat";
            case "triangle": return "Dreieck";
            case "star": return "Stern";
            case "heart": return "Herz";
            case "diamond": return "Raute";
            default: return value;
        }
    }
}
