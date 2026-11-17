package dev.ullmann.lumo;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/** The exact public input vocabulary shared by the real Android table games. */
public final class TableGameIntent {
    private static final Pattern TOKEN = Pattern.compile("[a-f0-9]{32}");
    private static final Set<String> BASE = new HashSet<>(Arrays.asList(
            "token", "roundId", "revision", "sequence", "action"));

    private TableGameIntent() {}

    private static boolean number(Object value, long low, long high) {
        if (!(value instanceof Integer) && !(value instanceof Long)) return false;
        long v = ((Number) value).longValue();
        return v >= low && v <= high;
    }

    private static boolean token(Object value) {
        return value instanceof String && TOKEN.matcher((String) value).matches();
    }

    private static boolean oneOf(Object value, String... values) {
        return value instanceof String && Arrays.asList(values).contains(value);
    }

    public static boolean valid(String game, Map<String, Object> request) {
        if (!oneOf(game, "memory", "quiz") || request == null
                || !token(request.get("token")) || !token(request.get("roundId"))
                || !number(request.get("revision"), 1, 1_000_000_000L)
                || !number(request.get("sequence"), 1, 1_000_000_000L)
                || !(request.get("action") instanceof String)) return false;
        String action = (String) request.get("action");
        Set<String> keys = new HashSet<>(BASE);
        switch (action) {
            case "pause": case "resume": case "exit": case "restart":
                break;
            case "flip":
                if (!game.equals("memory") || !number(request.get("index"), 0, 23)) return false;
                keys.add("index"); break;
            case "difficulty":
                if (!game.equals("memory") || !oneOf(request.get("difficulty"),
                        "leicht", "mittel", "schwer", "knifflig", "profi")) return false;
                keys.add("difficulty"); break;
            case "pack":
                if (!game.equals("memory") || !oneOf(request.get("pack"),
                        "alle", "tiere", "weltall", "garten")) return false;
                keys.add("pack"); break;
            case "select":
                if (!game.equals("quiz") || !number(request.get("option"), 0, 3)) return false;
                keys.add("option"); break;
            case "reveal": case "next":
                if (!game.equals("quiz")) return false;
                break;
            case "joker":
                if (!game.equals("quiz") || !oneOf(request.get("joker"),
                        "fiftyFifty", "audience", "callLumo")) return false;
                keys.add("joker"); break;
            case "subject":
                if (!game.equals("quiz") || !oneOf(request.get("subject"),
                        "alle", "Deutsch", "Mathe", "Sachunterricht")) return false;
                keys.add("subject"); break;
            default:
                return false;
        }
        return request.keySet().equals(keys);
    }
}
