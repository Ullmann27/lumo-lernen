# Separate Pause-Caption CI attachment

This two-file source pack is based on published QA 0d7ea79cd02b921ed685abc79b27df8a5f6b4ccb, tree 863c4b45bcd6a564070ca128565688bde7e1ed11. It follows the separate unchanged nine-path Pause source freeze 3387f3240023ee63c4eb23c62f7d694e27e5041096c3b52a537e84d14123bc7b.

The actual Console-Start contract job receives a distinct mandatory invocation of tools.android_qa.tests.test_kart_continue_caption, with its full combined output in pause-caption-contracts.log. Existing pipefail propagation, an exact nine-test count and exact OK are mandatory. The existing always-uploaded contracts artifact gains this original log. All six previous groups, including their exact counts 86/7/9/6/9/121, are byte-preserved. The future mandatory total is 247 only when the actual jobs execute; no new PASS is claimed here.

The existing workflow test keeps exactly nine methods. Two methods gain assertions for the new real command/count/log and the already installed Pillow dependency; every previous assertion remains. The complete three-renderer Android job is byte-identical to its QA0d version. There is no new device run, APK build, retry, source binding relaxation or new installation.

Source import review confirms that the new test itself uses Python's standard library and the real PNG inspection uses the already installed Pillow 12.3.0. Existing uiautomator2 remains unchanged. Two exact original import dependencies from QA0d are saved separately as read-only provenance; no dependency source is proposed for modification. Import/materialization and execution remain future checkpoint validation.

No tests or actionlint were run during preparation. Root alone owns the source checkpoint, subsequent scoped validation and any CI activation. Both original failed Android results and the independent GMS/shader blockers remain unchanged.
