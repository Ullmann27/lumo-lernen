# Native47: enger Runner-Branchvertrag

Basis ist Native `47ca642aad9290c9ba274b08e7dadfc953854d4f`. Der tatsächliche vollständige Native-Lauf `43607369276` scheiterte an der alten Studio-only-Assertion. Das Originalprotokoll bleibt in `qa/native47-new-worlds-failure-20261114/original-job.log`; `review.json` bindet seinen vollständigen Hash und die relevanten Originalzeilen.

Nur `tools/tests/test_nextgen_runner.py` ist geändert. Die bestehende Methode verlangt jetzt genau Studio und Feature, den vollständigen Same-repository-Archivguard und die tatsächliche Source-/Run-Bindung. Die übrigen Assertions, alle 16 Testdefinitionen, der Workflow und die Harnesses bleiben unverändert. Die benachbarte Suche fand genau die eine überholte Literalstelle.

Der gezielte bestehende Workflowfall besteht. Der vollständige bestehende 16er-Lauf besteht mit 16/16, 0 Skip, 148,878 Sekunden und Exit 0. Der Einzelfall gehört bereits zu diesen 16 und wird nicht addiert. Sämtliche Rohlogs und Ausführungsdaten liegen in `evidence/`. Keine echten Szenen wurden dafür neu gerendert; die vorhandenen Orchestrierungsfixtures sind synthetisch.

Der neue Quellblob `799a068b20f446e14f6bafe42cffb186fc3e8189` wurde in `Ullmann27/lumo-godot` erzeugt und vollständig als UTF-8 bytegleich zurückgelesen. `confirmed-tree-inputs.json` ist die einzelne Integrationszeile. Kein Tree, Commit, Ref, PR oder CI-Lauf wurde verändert. Die vollständige neue Native-CI-Abnahme steht noch aus.
