import dev.ullmann.lumo.TableGameIntent;
import java.util.LinkedHashMap;
import java.util.Map;

/** Executed against the production Java validator, without Android substitutes. */
public final class TableGameIntentContract {
    private static int checks;

    private static Map<String, Object> input(String action) {
        Map<String, Object> value = new LinkedHashMap<>();
        value.put("token", "0123456789abcdef0123456789abcdef");
        value.put("roundId", "fedcba9876543210fedcba9876543210");
        value.put("revision", 4);
        value.put("sequence", 9L);
        value.put("action", action);
        return value;
    }

    private static void check(boolean condition, String label) {
        checks++;
        if (!condition) throw new AssertionError(label);
    }

    public static void main(String[] args) {
        for (String game : new String[]{"memory", "quiz"}) {
            for (String action : new String[]{"pause", "resume", "exit", "restart"}) {
                check(TableGameIntent.valid(game, input(action)), game + " " + action);
                Map<String, Object> injected = input(action);
                injected.put("stars", 5000);
                check(!TableGameIntent.valid(game, injected), "Renderer cannot award stars");
            }
        }
        for (int index : new int[]{0, 7, 23}) {
            Map<String, Object> value = input("flip"); value.put("index", index);
            check(TableGameIntent.valid("memory", value), "Valid memory card index");
            check(!TableGameIntent.valid("quiz", value), "Memory intent cannot enter quiz");
        }
        for (Object index : new Object[]{-1, 24, 1.0, true, "3", null, Long.MAX_VALUE}) {
            Map<String, Object> value = input("flip"); value.put("index", index);
            check(!TableGameIntent.valid("memory", value), "Reject invalid memory index");
        }
        for (String level : new String[]{"leicht", "mittel", "schwer", "knifflig", "profi"}) {
            Map<String, Object> value = input("difficulty"); value.put("difficulty", level);
            check(TableGameIntent.valid("memory", value), "Existing difficulty vocabulary");
        }
        for (String pack : new String[]{"alle", "tiere", "weltall", "garten"}) {
            Map<String, Object> value = input("pack"); value.put("pack", pack);
            check(TableGameIntent.valid("memory", value), "Existing pack vocabulary");
        }
        for (int option = 0; option < 4; option++) {
            Map<String, Object> value = input("select"); value.put("option", option);
            check(TableGameIntent.valid("quiz", value), "Four quiz options");
            check(!TableGameIntent.valid("memory", value), "Quiz intent cannot enter memory");
        }
        for (String action : new String[]{"reveal", "next"}) {
            check(TableGameIntent.valid("quiz", input(action)), "Quiz progression");
            check(!TableGameIntent.valid("memory", input(action)), "No quiz progress in memory");
        }
        for (String joker : new String[]{"fiftyFifty", "audience", "callLumo"}) {
            Map<String, Object> value = input("joker"); value.put("joker", joker);
            check(TableGameIntent.valid("quiz", value), "Existing joker vocabulary");
        }
        for (String subject : new String[]{"alle", "Deutsch", "Mathe", "Sachunterricht"}) {
            Map<String, Object> value = input("subject"); value.put("subject", subject);
            check(TableGameIntent.valid("quiz", value), "Existing subject vocabulary");
        }
        for (String key : new String[]{"token", "roundId", "revision", "sequence", "action"}) {
            Map<String, Object> value = input("pause"); value.remove(key);
            check(!TableGameIntent.valid("quiz", value), "Envelope field is mandatory");
        }
        for (String key : new String[]{"revision", "sequence"}) {
            for (Object invalid : new Object[]{0, -1, 1000000001L, 1.0, true, "1", null}) {
                Map<String, Object> value = input("pause"); value.put(key, invalid);
                check(!TableGameIntent.valid("quiz", value), "Strict bounded integers");
            }
        }
        for (String key : new String[]{"token", "roundId"}) {
            for (Object invalid : new Object[]{"", "0123456789abcdef0123456789abcde", "../profile", "ABCDEF0123456789ABCDEF0123456789", 123, null}) {
                Map<String, Object> value = input("pause"); value.put(key, invalid);
                check(!TableGameIntent.valid("quiz", value), "Strict token shape");
            }
        }
        for (String game : new String[]{"cards", "connect_four", "../../quiz", "Quiz", ""}) {
            check(!TableGameIntent.valid(game, input("pause")), "No other channel accepted");
        }
        check(!TableGameIntent.valid(null, input("pause")), "Null game rejected");
        check(!TableGameIntent.valid("quiz", null), "Null input rejected");
        check(!TableGameIntent.valid("quiz", input("reward")), "No renderer reward action");
        check(!TableGameIntent.valid("quiz", input("select")), "Option required");
        Map<String, Object> wrong = input("select"); wrong.put("option", 4);
        check(!TableGameIntent.valid("quiz", wrong), "Only four quiz options");
        Map<String, Object> extra = input("next"); extra.put("owner", "another-child");
        check(!TableGameIntent.valid("quiz", extra), "No owner override");
        System.out.println("[TableGameIntentContract] PASS checks=" + checks);
    }
}
