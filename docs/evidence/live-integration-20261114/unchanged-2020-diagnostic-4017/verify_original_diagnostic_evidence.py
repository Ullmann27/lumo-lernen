import json,pathlib,hashlib,xml.etree.ElementTree as ET
from PIL import Image
root=pathlib.Path("/workspace/scratch/909ddb52fe7b/unchanged-2020-diagnostic-results")
def strict(path):
    def pairs(items):
        out={}
        for k,v in items:
            if k in out: raise ValueError("duplicate JSON key "+k)
            out[k]=v
        return out
    return json.loads(path.read_text(),object_pairs_hook=pairs,parse_constant=lambda x: (_ for _ in ()).throw(ValueError("invalid JSON number "+x)))
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
viewed={
 "main":["13_atelier_zehnerbruecke.png","21_stage_select_gecko_velo-7.png","21_lumo_kart_real_race.png","21_continue/21_race_driving_late_2.png","23_zurueck_in_flutter.png"],
 "update2017":["21_stage_select_gecko_velo-7.png","21_race_hud_0.png","21_race_driving_late_2.png","23_zurueck_in_flutter.png","updated-profile-offline.png","fold-cover.png","fold-open.png","fold-landscape.png"]
}
review={"schema":1,"run_id":43612493152,"run_attempt":1,"qa_source":"4017a94dd4a859f7b571e9b6a1f0208695e5e815","qa_tree":"7680b8ab9b32d526b365ad2376092da267f0063b","apk_source":"1e22d2455937e2640d1e44e153d290746f3afe49","apk_source_tree":"7fcc3748f8178bff91176ff27f11f7e86ca165ca","native_source":"e9a9f60f20403ffa6b2b26d1437f958b2704d2aa","apk_sha256":"e65662ccc91366177a80bf6c6d43d364d9908836eb50bbe43625725d6010ab4b","cases":{},"limitations":["Isolated observer diagnostic; not final seven-job release acceptance.","Separate direct Village and Connect Four probes are not part of these diagnostic cases and produced no evidence here.","No physical ARM64 device, audio output, GPU frame-time/60-FPS measurement, or completed two-lap race reward.","Update baseline contains no populated writing/journal preferences; their content preservation is not claimed."],"verification_scope":"Read-only validation of the already downloaded original evidence; no test rerun, emulator, APK rebuild, or new toolchain verification."}
for case in ("main","update2017"):
    croot=root/case
    orig=croot/"originals"
    sub="main" if case=="main" else "update"
    receipt=strict(orig/"diagnostic-result.json")
    assert receipt["status"]=="PASS" and receipt["probe_exit_code"]==0 and receipt["postflight_binding_exit_code"]==0 and receipt["seven_job_acceptance"] is False
    rr=receipt["original_result"];reportpath=orig/rr["path"]
    assert reportpath.stat().st_size==rr["bytes"] and digest(reportpath)==rr["sha256"]
    report=strict(reportpath);assert report["status"]=="PASS" and report["fatal_crashes"]==0
    before=strict(orig/"candidate-and-probe-binding.json");after=strict(orig/"candidate-and-probe-binding-after.json")
    assert before==after
    assert before["status"]=="BOUND" and before["apk"]["apk_sha256"]==review["apk_sha256"]
    assert before["git_sources"]["qa"]["commit"]==review["qa_source"] and before["git_sources"]["qa"]["tree"]==review["qa_tree"]
    assert before["git_sources"]["candidate"]["commit"]==review["apk_source"] and before["git_sources"]["candidate"]["tree"]==review["apk_source_tree"]
    assert before["candidate_build"]["native_source"]==review["native_source"]
    assert before["diagnostic_qa"]["run_id"]==review["run_id"] and before["diagnostic_qa"]["run_attempt"]==1
    readiness=strict(orig/sub/"21_stage_select_gecko_velo-surface-readiness.json")
    assert readiness["status"]=="TOUCH_SENT" and readiness["exact_caption_required"] is True and readiness["timeout_seconds"]==150
    assert readiness["elapsed_seconds"]<=150
    swipes=[]
    references=0
    for frame in readiness["frames"]:
        fp=orig/sub/frame["source"]
        assert fp.stat().st_size==frame["source_bytes"] and digest(fp)==frame["source_sha256"]
        assert list(Image.open(fp).size)==frame["pixels"]
        rec=frame.get("missing_caption_recovery",{})
        for entry in rec.get("ocr_sources",[]):
            op=orig/sub/entry["file"]
            assert op.stat().st_size==entry["bytes"] and digest(op)==entry["sha256"]
            references+=1
        if "pixel_source" in rec:
            pixel=rec["pixel_source"];pp=orig/sub/pixel["file"]
            assert pp.stat().st_size==pixel["bytes"] and digest(pp)==pixel["sha256"]
            assert list(Image.open(pp).size)==pixel["pixels"]
            assert len(rec["bars"])==5
            references+=1
        if rec.get("status")=="SWIPE_SENT":swipes.append({k:rec[k] for k in ("swipe_number","gesture","anchor_kind")})
    assert len(swipes)<=5
    final=readiness["frames"][-1]["target"]
    assert final["stable_observed_target"] is True and final["target_geometry_valid"] is True
    images=[]
    for name in viewed[case]:
        ip=orig/sub/name
        images.append({"path":sub+"/"+name,"bytes":ip.stat().st_size,"sha256":digest(ip),"pixels":list(Image.open(ip).size),"actually_viewed":True})
    facts={"original_report":rr,"receipt_pass":True,"before_after_binding_identical":True,"garage_elapsed_seconds":readiness["elapsed_seconds"],"observed_swipes":swipes,"referenced_ocr_pixel_files_checked":references,"final_target_bounds":readiness["final_observed_bounds"],"target_touch":readiness["touch"],"reviewed_original_images":images}
    if case=="main":
        assert len(report["steps"])==21 and all(s["ok"] is True for s in report["steps"])
        steps={s["step"]:s for s in report["steps"]}
        assert steps["start-kart-race"]["confirmed_selection"]["selected_kart"]=="gecko_velo"
        continue_report=strict(orig/sub/"21_continue/21_continue-result.json")
        assert continue_report["progress"]["distance_gain_after_continue"]>0
        facts.update({"steps_passed":list(steps),"confirmed_race_selection":steps["start-kart-race"]["confirmed_selection"],"race_distance_gain":steps["race-drive"]["native_progress"]["distance_gain"],"continue_distance_gain":continue_report["progress"]["distance_gain_after_continue"],"learning_keys_compared":steps["learning-state-after-kart"]["learning_keys_compared"]})
    else:
        assert report["candidate_source"]==review["apk_source"] and report["offline"] is True
        phases=[report["after_update"],report["after_kart"],report["after_restart"],*report["fold"].values()]
        assert all(x["learning_keys_compared"]==7 and x["correct_answers_preserved"]==1 and x["earned_stars"]==1 and x["earned_xp"]==5 and not x["learning_keys_added"] for x in phases)
        keys=[e.get("name") for e in ET.fromstring((orig/sub/"before-update-preferences.xml").read_text())]
        protected=[k for k in keys if "writing" in k.lower() or "journal" in k.lower()]
        assert not protected
        facts.update({"installation":report["installation"],"preserved_phases":["after_update","after_kart","after_restart","fold_cover","fold_open","fold_landscape"],"learning_keys_compared":7,"correct_answers_preserved":1,"earned_stars":1,"earned_xp":5,"populated_writing_or_journal_keys":protected,"confirmed_race_selection":report["native_tour"]["race"]["confirmed_selection"],"race_distance_gain":report["native_tour"]["drive"]["native_progress"]["distance_gain"]})
    review["cases"][case]=facts
review["visual_findings"]=[
 "Main original Atelier image shows the complete seven-plus-five ten-frame task with visible controls and model-check button.",
 "Both original garage target frames show a complete Gecko Velo caption above the workshop overlay; actual saved new-race data confirms the selected kart independently.",
 "Main continuation driving image shows the original fox and green Gecko kart, unobstructed roadway, lap 1/2, and a visible 177 km/h reading.",
 "Update late driving image shows the original fox and green Gecko kart, unobstructed roadway, lap 1/2, and a visible 157 km/h reading.",
 "Both return images show the Flutter games world. A visible Village portal does not prove that its native scene was entered.",
 "Update profile and all three Fold-format images display one star and five of 400 XP; those figures are independently tied to the preserved original preferences.",
 "Update initial race HUD frame contains a nearby grey opponent partly blocking the lower camera view; the later driving frame clears that obstruction. No all-frame occlusion-free claim is made.",
 "Main file 21_lumo_kart_real_race.png is the track introduction, not an active-drive proof; the separate continuation driving image supplies that proof.",
 "The Fold landscape image shows clipped off-screen central content and shortened sidebar profile text in its initial viewport; no all-controls-in-one-frame claim is made."
]
out=root/"observed-original-review.json";out.write_text(json.dumps(review,indent=2,sort_keys=True)+"\n")
print(json.dumps({"review":str(out),"sha256":digest(out),"images_viewed":sum(len(x) for x in viewed.values()),"cases":{c:{"swipes":v["observed_swipes"],"target_touch":v["target_touch"]} for c,v in review["cases"].items()}}))
