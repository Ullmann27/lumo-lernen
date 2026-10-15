# ChatGPT Generated LUMO Asset Boards — live media manifest

These are the **actual generated image bytes**, not only prompt descriptions. They were generated for Heinz' LUMO visual/game-production work and are to be used as visual/model/material/animation references.

## Mandatory usage
1. Download every board below before declaring an asset gap.
2. Keep the boards as reference material under `assets/lumo_generated/reference_boards/` or an equivalent non-runtime reference folder.
3. Extract only clearly useful individual references into production assets; do not ship a whole collage as UI/gameplay.
4. Do not use flat PNG road/character art as fake 3D where real meshes/rigging are required.
5. For Lumo motion: the boards/keyframes define pose/timing/style; final free movement must come from the runtime animation system / rig.
6. If a needed visual is still missing after checking all boards + existing repo assets, post a structured `ASSET_REQUEST` (template below) instead of inventing a low-quality substitute.

## Generated boards
- **board_01** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/c2deab88-41d7-4877-be6f-395af998635d.png
- **board_02** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/711e6842-2ffc-4b84-bd79-ea50fbd3aa46.png
- **board_03** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/9ea4dae2-a98b-42aa-be2f-1c91aacafe0c.png
- **board_04** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/faef4440-3e93-4f05-b665-233ad5cbd434.png
- **board_05** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/538d1859-1a05-4c62-94ec-1f71d64e7cde.png
- **board_06** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/7d52b44e-9949-418a-a610-76078c8d8535.png
- **board_07** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/738c7d56-2790-44a5-9375-4643054a77ce.png
- **board_08** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/e011a0fe-7597-4007-8a22-6a7630dd8d67.png
- **board_09** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/ac22adf7-8aeb-4c71-af73-9e47f4f9625c.png
- **board_10** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/fd5f4bbd-5b3e-466c-a7c0-e50d9c0e42c8.png
- **board_11** — https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/68a0967e-28a4-4fe4-a149-b4a3b7211185.png

## ASSET_REQUEST protocol
```
ASSET_REQUEST
owner: <Sonnet/Opus/Luna/etc>
target_repo: <repo>
target_path: <exact desired path>
asset_type: <character pose / background / prop / track landmark / VFX / UI / model reference>
view: <front / 3/4 / side / top / landscape / etc>
dimensions: <px or aspect>
alpha: <transparent / opaque>
reference: <exact board/key-art filename>
what_is_missing: <precise delta>
runtime_use: <where it will appear>
blocking: <yes/no; only dependent subtask waits>
```

## Notification rule
Every new `ASSET_REQUEST` must be posted in **issue #177** and linked from the active implementation thread. Do not silently downgrade quality because an asset is missing. Continue on all independent tasks.

## Quality rule
Heinz explicitly rejects "close enough" output. If runtime still has a major visual delta to the target, status is `VISUAL_GAP / NOT FINISHED`.
