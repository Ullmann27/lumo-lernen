#!/usr/bin/env python3
"""Machine-verifiable bounds for LUMO's agent-task tree. No agent is started."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
p = root / "docs/agent-network/agent_tree.json"
data = json.loads(p.read_text(encoding="utf-8"))
nodes = data["nodes"]
by_id = {x["id"]: x for x in nodes}
assert len(nodes) == len(by_id) == data["max_total_tasks"] == 30
assert (data["root_agents"], data["max_depth"], data["max_concurrent_sessions"]) == (3, 3, 3)
for flag in ("allow_infinite_delegation", "allow_automatic_merge", "allow_publication_without_owner", "allow_paid_services_without_approval"):
    assert data[flag] is False, flag
assert data["mode"] == "PLANNED_NOT_RUNNING"
assert [sum(1 for n in nodes if n["depth"] == depth) for depth in (1, 2, 3)] == [3, 9, 18]
for item in nodes:
    assert item["id"] and item["mission"] and item["team"]
    actual_children = [n for n in nodes if n["parent"] == item["id"]]
    assert len(actual_children) == item["children_limit"]
    if item["parent"] is None:
        assert item["depth"] == 1
    else:
        parent = by_id[item["parent"]]
        assert parent["depth"] == item["depth"] - 1
        assert parent["team"] == item["team"]
for name in ("orchestrator", "learning-director", "3d-director", "release-director"):
    f = root / ".github/agents" / ("lumo-" + name + ".agent.md")
    contents = f.read_text(encoding="utf-8")
    assert contents.startswith("---\nname: lumo-" + name + "\n")
    assert "\ndescription: " in contents and "\ntarget: github-copilot\n---\n" in contents
print(json.dumps({"result": "PASS", "bounded_jobs": len(nodes), "leads": 3,
"subtasks": 9, "implementation_and_qa": 18,
"concurrent_cap": 3, "actual_started_agents": 0}, indent=2))
