# Vân Mộng Tu Tiên

Một cultivation survivor top-down với vòng chơi hoàn chỉnh `Title → Sơn môn → Chọn ải → Tâm pháp → Chiến đấu → Phần thưởng → Sơn môn`. Hồ sơ JSON lưu Linh Ngọc, thành tích, bestiary, ba ải được mở khóa, ba tâm pháp và ba nhánh công pháp vĩnh viễn. Combat vẫn giữ run bốn phút, đột phá trong trận và boss Thiên Giác.

> Engine note: `project.godot` giữ feature baseline `4.4` để bảo toàn fixture cũ, nhưng native/import/Web evidence hiện được chạy bằng Godot `4.6.2.stable.official.71f334935`. Dự án mới nên dùng policy 1.0 của plugin và bắt đầu từ Godot 4.6.2; fixture này không phải tuyên bố commercial-release-ready cuối cùng.

Visual layer hiện dùng hướng **restrained cinematic xianxia**: ít container, bề mặt mực–sơn mài ổn định, typography/focus rõ và asset chỉ xuất hiện khi có vai trò riêng. Bộ `PREMIUM-001` cung cấp ba sigil phi kiếm/hộ thể/tụ linh độc lập, không frame/bevel/clasp; Hub và Công Pháp có live rank preview. Combat có VFX tiến hóa thật theo cấp: thêm kiếm hộ thân/fan/trail, thêm lớp ngọc giáp/phù trận/hit shard, hoặc thêm vortex/tendril/beam hút linh khí. Ba môi trường vẫn có plate riêng. Score ambient 32 giây cùng SFX được tổng hợp sẵn, tách bus Music/SFX và có volume/reduced-motion/screen-shake.

Đây là một **commercial-oriented full vertical slice**, chưa phải tuyên bố release/commercial-ready cuối cùng: native automation, screenshot QA, mobile multi-touch, responsive 16:9–21:9, Godot 4.6.2 Web export và served Chromium smoke đã có evidence; Firefox/Safari, audio output review, thiết bị iOS/Android thật và lượt chơi tay đủ bốn phút vẫn cần nghiệm thu.

Game lấy logical viewport **1600x900**, window override **1280x720** và dùng stretch `expand`: arena mở rộng thật trên màn hình 18:9–21:9, plate được center-crop cover thay vì kéo méo, còn menu 16:9 được căn giữa và scale đồng nhất. Mobile ưu tiên landscape; portrait hiện một rotate-device guard. Một ván kéo dài 4 phút; Thiên Ma xuất hiện ở 2:30.

## Chạy game

1. Cài **Godot 4.6.2** hoặc dùng binary tương thích đã được project/CI pin.
2. Trong Project Manager, chọn **Import** và mở `project.godot` trong thư mục này.
3. Nhấn **F6/F5** hoặc nút Run Project.

Có thể chạy bằng CLI khi Godot nằm trong `PATH`:

```bash
godot --path examples/van-mong-tu-tien --editor
# hoặc chạy trực tiếp
godot --path examples/van-mong-tu-tien
# nếu dùng binary portable đã tải trong workspace (macOS Apple Silicon/Intel)
./.tools/godot/Godot.app/Contents/MacOS/Godot --path examples/van-mong-tu-tien
```

`godot` / `godot4` không nhất thiết có sẵn trên `PATH`; kiểm thử hiện dùng binary chính thức 4.6.2 trong Codex cache. Các suite `smoke_meta_profile`, `smoke_runtime`, `smoke_frontend_flow`, `smoke_audio`, `smoke_long_run`, `smoke_cultivation_vfx`, `smoke_mobile_support` và `smoke_responsive_layout` đều PASS. Evidence gồm toàn bộ meta screen trong `production/playtests/frontend/`, combat/breakthrough trong `production/playtests/overhaul/`, mobile controls/portrait guard trong `production/playtests/mobile-support/` và 21:9 Hub/combat trong `production/playtests/responsive/`.

## Điều khiển

- `WASD` hoặc phím mũi tên: di chuyển
- `Space`: Chấn Khí / Kiếm Trận, kỹ năng chủ động có hồi chiêu
- `P`: tạm dừng / tiếp tục
- `R`: bắt đầu lại bất cứ lúc nào
- `Enter`: bắt đầu từ màn hình mở đầu
- Chuột: chọn một trong ba công pháp khi lên cấp (UI hiện cũng hỗ trợ `1` / `2` / `3`)
- Tay cầm: left stick di chuyển, `A` xác nhận/Kiếm Trận, `Start` tạm dừng, `Y` thử lại; UI có focus hiển thị rõ
- Mobile landscape: joystick trái đa chạm, `Linh Bạo` bên phải và pause ở top-center; tất cả target tối thiểu 64 px, nằm trong notch/title-safe area. Portrait bị chặn bằng hướng dẫn xoay máy thay vì để UI vỡ.

## Vòng chơi

- Từ sơn môn, chọn một trong ba ải và một trong ba tâm pháp có modifier thật.
- Phi kiếm tự tìm mục tiêu gần nhất.
- Yêu vật rơi linh khí; thu đủ để lên cấp và chọn một trong ba công pháp.
- Cảnh giới tiến từ Phàm Nhân qua Luyện Khí, Trúc Cơ, Kim Đan và Nguyên Anh.
- Ma triều và tà tu tinh anh xuất hiện theo mốc thời gian.
- Thiên Ma xuất hiện ở giây 150, có huyết trận báo trước. Hạ boss sớm hoặc sống đến phút thứ 4 để phi thăng.
- Kết quả cộng Linh Ngọc, mở ải/bestiary/achievement, sau đó trở lại sơn môn hoặc thử lại.

## Cấu trúc

- `scenes/main.tscn`: ghép world/player, combat HUD và front end nhiều màn.
- `scripts/core`: event bus, cấu hình JSON và đảm bảo InputMap.
- `scripts/meta/meta_profile.gd`: save/migration, unlock, reward, techniques, codex, achievements và settings.
- `scripts/gameplay`: vòng lặp chính, player, enemy/boss, phi kiếm, linh khí, hiệu ứng, bridge texture runtime (`runtime_visuals.gd`) và VFX rank-aware (`cultivation_vfx.gd`).
- `scripts/gameplay/ink_background.gd`: chọn plate riêng cho Vân Mộng/Huyết Vân/Thiên Môn; fallback ink khi texture vắng.
- `scripts/ui/frontend.gd`: Title, Hub, Stage, Loadout, Techniques, Codex, Achievements, Settings và Results.
- `scripts/ui/hud.gd`, `raster_button.gd`, `cultivation_*.gd`: cinematic controls, combat HUD và breakthrough cards không kéo giãn ornament.
- `scripts/ui/mobile_*.gd`, `rotate_device_overlay.gd`: multi-touch, safe-area/notch, mobile lifecycle và portrait guard.
- `scripts/audio/audio_director.gd`: score/SFX procedural, bus Music/SFX và event bridge.
- `resources/tuning/game_balance.json`: nhịp spawn, chỉ số, cảnh giới và thời lượng run.

## Web export

Preset `Web` đã có trong `export_presets.cfg`. Sau khi cài đúng Godot 4.6.2 Web export templates, chạy `godot --headless --path . --export-release Web build/web/index.html` rồi phục vụ toàn bộ thư mục output qua HTTP. Godot 4 Web dùng Compatibility/WebGL 2.0; dự án nhắm đường export single-thread mặc định. Canvas focus, WASD/mũi tên, Space, P, R, Enter, chọn thẻ bằng chuột/1/2/3 và layout landscape đã có Chromium evidence.

Lệnh export và served Chromium smoke đã chạy bằng Godot 4.6.2. Các matrix Firefox/Safari, audio unlock/output, thiết bị thật và manual balance pass vẫn **chưa được xác minh**.

Tài liệu Godot 4.6 chính thức:

- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/4.6/classes/class_characterbody2d.html
- https://docs.godotengine.org/en/4.6/classes/class_inputeventkey.html
- https://docs.godotengine.org/en/4.6/classes/class_audiostreamwav.html

## Design và kiến trúc

- `design/gdd/game-concept.md`: fantasy, pillars, scope và fun hypothesis.
- `design/gdd/systems-index.md` cùng `design/gdd/system-*.md`: rule, tuning, dependency và acceptance của 5 hệ thống MVP.
- `design/art/art-bible.md`: procedural ink-wash language và key-art direction.
- `design/assets/asset-manifest.yaml`: provenance/acceptance của key art, sprite/FX/arena đã chấp nhận và lớp UI runtime.
- `design/assets/godot-import-manifest.yaml`: mapping từ output đã xử lý sang bridge runtime và scene/script đích.
- `docs/architecture/architecture.md`: ownership, data/input/Web boundaries và risks.
- `docs/architecture/adr-0001-engine-web.md`: quyết định Godot 4.4/Web và nguồn chính thức.
- `docs/architecture/control-manifest.md`: 8 input actions canonical và context routing.
- `production/stories/STORY-0001-playable-cultivation-arena.md`: implementation/verification gate.
- `production/session-state/active.md`: trạng thái handoff hiện tại.

`KEYART-001`, hub/stage plates, sprite/FX và `PREMIUM-001` đã được tích hợp; contact-sheet QA và prompt provenance nằm cùng runtime asset. `UIKIT-002/003` chỉ còn là legacy source/fallback và không còn điều khiển hình thái chính của Hub, HUD hay breakthrough. Trạng thái phát hành toàn game vẫn bị giữ cho đến khi Web, thiết bị thật và manual verification hoàn tất.

Màu mực đậm, giấy sáng, ngọc bích và vàng được dùng với độ tương phản cao; thông tin quan trọng luôn có chữ hoặc thanh trạng thái thay vì chỉ dựa vào màu.
