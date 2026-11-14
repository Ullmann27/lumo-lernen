# Separate follow-up: connect the existing native games hub

Base: Host `0b7bacadd3cdc45d22a8e038c5df50ba8b739d62`, Native `baf148b03a7a32c6ad9f737d731f900eb9113ea1`.

The new entry exposes the existing Godot games scene through the guarded Flutter launcher. It keeps all eleven existing tiles, child ownership checks, reward persistence, launch exclusion and return handling. Android gains exactly the `games` allowlist member. The two Flutter product files and entry test are byte-identical to Producer PR504; MainActivity applies only its one-line intent to our current host.

This is an isolated follow-up branch. It does not move the active C4 source or claim a new APK. Source qualification on this combined base is pending. A read-only two-job workflow checks the genuine entry and existing routes, then compiles the actual Kotlin/Java host and preserves original outputs. Actionlint passed after correcting the job-level environment context. The failed initial lint observation is preserved explicitly; its raw tool stdout was not separately saved.

Producer Run43603768152 passed six actual Flutter tests and actual host compilation. Its analyzer reported147 existing issues under its nonfatal-warning policy. These are producer-source facts, not evidence of executing the new combined source. The independent native source review confirms games boot and on-screen return without new native product code.

PR505 is excluded. Its original current change-review log contains2423passes,202skips and3failures. No native-C4 opt-in behavior, navigation expectations or protected games-flow tests are changed here.

The complete originals archive includes the source patch, original producer comparisons, full focus logs, full failing505log, source preimages and current proposed files. All members were compared to their actual inputs. This checkpoint must receive its own focused results before integration; complete APK/device/update acceptance remains separate.
