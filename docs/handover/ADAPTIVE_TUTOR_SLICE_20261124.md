# LUMO adaptive tutor: first implementation slice (24.11.2026)

Base: a0fdd4031ba9a5637d9b943729a5f0df794071bc (2080 integration branch).
No main merge, APK, release, package/signature, Godot pin, journal or writing trainer change.

- One strict arithmetic parser shared by the existing live tutor and teacher error analysis: complete whole-number expressions only; verify the supplied answer; reject decimals, fractions and ambiguous fragments.
- Carry and borrow feedback is a hypothesis supported by the current task and given answer; no claim to know the child's thoughts. Existing pattern labels are retained.
- Existing local tutor fallback adapts requested mistake explanations; test-review remains blocked.
- Voluntary place-value assistance for verified +/- problems up to 100: tens, intermediate ten boundary, remaining ones; explicit help request; no final-answer button, auto-grading, reward, profile or new persistent state. The original task owns final answer and learning evidence. Existing small-number and multiplication aids remain.
- Added parser/feedback/teacher/tutor tests and widget/bridge tests. CI results must be checked on the exact commit. No physical device, 3D Godot scene, microphone, new model or learning-outcome claim.
- Next: verify the existing dialogue ownership contracts and connect separate visual learning scenes, without bypassing parent permissions or duplicating the tutor engine.
