"""Run the production local native dialogue with a real JDK, no Android mocks."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class LearningDialogLogicTest(unittest.TestCase):
    def test_checked_examples_and_interruptions(self):
        self.assertIsNotNone(shutil.which("javac"), "A real JDK is required")
        source = r'''
package dev.ullmann.lumo;
import java.util.*;
public class LearningDialogProbe {
  static int checks = 0;
  static void require(boolean condition, String message) {
    checks++;
    if (!condition) throw new AssertionError(message);
  }
  static LumoLearningDialogLogic.Context context(String kind, int a, int b,
      String word, List<String> syllables, List<String> pattern, String help) {
    return new LumoLearningDialogLogic.Context(kind, a, b, 0, word, "root", help, syllables, pattern);
  }
  public static void main(String[] args) {
    var bridge = context("bridge_ten", 8, 5, "", List.of(), List.of(), "");
    var why = LumoLearningDialogLogic.answer(bridge, "Warum zuerst zwei?", "explain");
    require(why.text.contains("10 minus 8 ist 2"), "Explain why exactly two");
    require(why.text.contains("bleiben 3 übrig"), "Keep the remaining three");
    require(why.objectId.equals("bridge_two"), "Address the rendered bridge object");
    var seven = LumoLearningDialogLogic.answer(context("bridge_ten", 7, 5, "", List.of(), List.of(), ""),
        "Warum zuerst zwei?", "explain");
    require(seven.text.contains("10 minus 7 ist 3"), "Do not blindly agree with a misheard number");
    require(seven.text.contains("bleiben 2 übrig"), "Compute the current task's remainder");
    var slow = LumoLearningDialogLogic.answer(bridge, "Bitte langsamer", "explain");
    require(slow.slower && slow.text.equals(why.text), "Slow down the same checked explanation");
    for (String stop : List.of("Stopp", "Stop!", "Bitte stopp", "Halt bitte", "Pause", "Aufhören")) {
      var reply = LumoLearningDialogLogic.answer(bridge, stop, "explain");
      require(reply.action.equals("stop") && reply.text.isEmpty(), "Stop must not start another utterance");
    }
    require(!LumoLearningDialogLogic.isStop("Warum stoppt der Bus?"), "A question is not a stop command");
    var correction = LumoLearningDialogLogic.answer(bridge, "Nein, ich meinte dreizehn", "explain");
    require(correction.text.contains("Prüfen") && !correction.text.contains("richtig"), "Correction is not a score");
    var syllables = new ArrayList<>(List.of("Ba", "na", "ne"));
    var banana = context("syllables", 0, 0, "Banane", syllables, List.of(), "");
    syllables.clear();
    var word = LumoLearningDialogLogic.answer(banana, "Noch einmal langsamer", "repeat");
    require(word.text.contains("Ba – na – ne") && word.slower, "Use the original checked syllables");
    require(word.objectId.equals("syllable_0"), "Point at the first syllable");
    var pattern = LumoLearningDialogLogic.answer(context("pattern", 0, 0, "", List.of(),
        List.of("circle", "triangle"), ""), "Gib mir einen Hinweis", "hint");
    require(pattern.text.contains("Kreis – Dreieck"), "Explain the recurring group");
    require(pattern.objectId.equals("pattern_group"), "Highlight the group, not a submitted answer");
    require(pattern.text.contains("Du wählst selbst"), "Leave the choice to the child");
    var card = LumoLearningDialogLogic.answer(context("task_card", 0, 0, "", List.of(), List.of(),
        "Suche zuerst das Namenwort."), "Wie geht das anders?", "hint");
    require(card.text.equals("Suche zuerst das Namenwort."), "Generic scenes use the current checked hint");
    System.out.println("PASS " + checks + " production dialogue checks");
  }
}
'''
        with tempfile.TemporaryDirectory(prefix="lumo-dialog-probe-") as temporary:
            directory = Path(temporary)
            probe = directory / "LearningDialogProbe.java"
            probe.write_text(source, encoding="utf-8")
            production = ROOT / "tools/auto_install/LumoLearningDialogLogic.java"
            subprocess.run(["javac", "-encoding", "UTF-8", "-d", str(directory),
                            str(production), str(probe)], check=True, capture_output=True)
            result = subprocess.run(["java", "-cp", str(directory),
                                     "dev.ullmann.lumo.LearningDialogProbe"],
                                    check=True, capture_output=True, text=True)
            self.assertIn("PASS 20 production dialogue checks", result.stdout)


if __name__ == "__main__":
    unittest.main()
