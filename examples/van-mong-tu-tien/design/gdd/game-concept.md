# Game Concept: Vân Mộng Tu Tiên

Status: Verified  
Release evidence boundary: implemented as a bounded native candidate; Web, physical-device and manual release gates remain pending  
Engine target: Godot 4.4 + Web export  
Logical viewport: 1600x900, 16:9; window override 1280x720  
MVP session: 4 minutes

Implementation note (2026-07-29): the shipped candidate intentionally expanded beyond this original MVP baseline with a complete title/hub/stage/loadout/results journey, persistent techniques, codex, achievements, settings, controller focus and mobile touch support. The original cut line below remains the design history, not the current feature inventory.

## Elevator Pitch

`Vân Mộng Tu Tiên` là game hành động sinh tồn góc nhìn từ trên xuống: người chơi điều khiển một kiếm tu giữa biển mây thủy mặc, né linh thú, để phi kiếm tự động trừ tà và chọn ba đạo duyên mỗi lần đột phá. Trong một ván 4 phút, người chơi đi qua năm mốc **Phàm Nhân → Luyện Khí → Trúc Cơ → Kim Đan → Nguyên Anh** và đối đầu đại linh thú xuất hiện ở 2:30.

## Core Fantasy

Từ một tu sĩ mong manh, người chơi nhanh chóng trở thành tâm điểm của một kiếm trận ngày càng rực rỡ: thân pháp quyết định sống còn, lựa chọn đạo duyên định hình sức mạnh, và cảnh giới mới phải được cảm nhận ngay qua nhịp chiến đấu lẫn phản hồi thị giác.

## Unique Hook

Nhịp sinh tồn kiểu arena cộng với một hành trình tu tiên cô đọng: mỗi lần lên cấp là một lần **đột phá** có ba lựa chọn rõ ràng, còn năm mốc cảnh giới làm đường cong sức mạnh hiện rõ trong đúng bốn phút.

## Player Experience

Primary MDA aesthetic: challenge/competence — đọc khoảng trống và lướt giữa vòng vây.  
Secondary aesthetics: fantasy, progression, discovery through build choices.  
Target player: người thích survivor-like ngắn, dễ vào, điều khiển một tay bàn phím và có bản sắc Á Đông.

## Core Loop

**30 seconds:** di chuyển tránh áp sát → phi kiếm tự tìm mục tiêu → dùng Kiếm Trận bằng `Space` khi bị vây → nhặt linh khí → nhận phản hồi sát thương, hạ địch và hồi chiêu.  
**4 minutes:** tăng cấp, chọn một trong ba đạo duyên, đổi cảnh giới, ứng phó mật độ linh thú tăng dần, đối đầu boss và kết thúc ván.  
**Session:** Màn Danh Hiệu → chơi → chiến thắng hoặc tọa hóa → nhấn `R` để lập tức tái nhập Vân Mộng.  
**Long term:** MVP không có meta-progression; mục tiêu lặp lại là thử tổ hợp đạo duyên và cải thiện khả năng né/định thời Kiếm Trận.

## Session Arc

| Thời gian | Nhịp | Ý đồ |
|---|---|---|
| 0:00–1:15 | Học di chuyển, phi kiếm tự động và những lần đột phá đầu | Onboarding không cần hộp thoại |
| 1:15–1:55 | Sự kiện áp lực đầu tiên, địch mạnh hơn và build bắt đầu định hình | Kiểm tra sức mạnh giữa ván |
| 1:55–2:30 | Đợt áp lực thứ hai, nhiều hướng áp sát | Chuẩn bị cho cao trào |
| 2:30–4:00 | Đại linh thú xuất hiện cùng đám đông có kiểm soát | Cao trào, hai đường thắng |
| 4:00 | Thắng nếu còn sống; hạ boss sớm cũng thắng | Kết thúc dứt khoát |

## Pillars

1. **Nhất bộ nhất kiếm** — di chuyển luôn là quyết định chủ động, còn phi kiếm tự động giữ nhịp tấn công.  
   Design test: nếu một tính năng buộc người chơi ngừng đọc không gian khi đang chiến đấu, nó không thuộc MVP.
2. **Đột phá hữu hình** — mỗi lựa chọn phải làm số liệu hoặc hành vi chiến đấu thay đổi ngay trong vài giây.  
   Design test: một đạo duyên không có phản hồi dễ nhận biết sẽ bị cắt hoặc gộp.
3. **Bốn phút thành đạo** — ván có mở đầu, leo thang và cao trào boss rõ ràng, không có thời gian chết.  
   Design test: nội dung không phục vụ đường cong 0:00–4:00 được hoãn.
4. **Thủy mặc dễ đọc** — chất liệu mực tàu tạo bản sắc nhưng an toàn, nguy hiểm và phần thưởng phải phân biệt trong một cái liếc mắt.  
   Design test: readability thắng chi tiết trang trí.

## Anti-Pillars

- Không phải RPG dài hơi có trang bị, nhiệm vụ hay lưu tiến trình, vì MVP chỉ kiểm chứng một ván sinh tồn trọn vẹn.
- Không phải bullet hell dày đặc, vì nguy hiểm chính là vị trí của linh thú và khoảng trống di chuyển.
- Không phải game bấm liên tục nhiều kỹ năng, vì chỉ có một kỹ năng chủ động; phi kiếm tự động làm nền cho thân pháp.
- Không dùng tài sản tạo sinh làm điều kiện để gameplay chạy; key art là lớp trình bày, còn playfield dùng đồ họa thủ tục.

## Visual Identity Anchor

One-line visual rule: **tranh thủy mặc sống dậy trên giấy dó, với ngọc quang lam là an toàn và chu sa đỏ là hiểm họa**.  
Shape language: nhân vật/phi kiếm thanh, tam giác và vòng tròn có trật tự; linh thú là khối mực hữu cơ có gai, sừng hoặc vuốt.  
Color philosophy: nền ngà và mực chàm ít bão hòa; cyan-jade cho người chơi/phần thưởng; vermilion cho địch/sát thương; gold cho đột phá.  
Motion/feedback feel: nét mực có độ trễ nhẹ, slash sắc và nhanh, số/flash ngắn, rung camera rất tiết chế.

## MVP Hypothesis

The MVP proves: **một arena tu tiên 4 phút với tự động tấn công + một kỹ năng chủ động + lựa chọn đột phá có tạo được nhịp “né, gom linh khí, thành đạo” dễ hiểu và đáng chơi lại hay không.**

Required:

- Di chuyển 8 hướng bằng WASD/mũi tên trong arena logical 1600x900, hiển thị 1280x720.
- Phi kiếm tự động tìm mục tiêu và Kiếm Trận chủ động bằng `Space` có hồi chiêu rõ ràng.
- Linh thú rơi linh khí; thanh XP; mỗi cấp đưa ra ba thẻ đạo duyên và tạm dừng chiến đấu.
- Năm mốc: Phàm Nhân → Luyện Khí → Trúc Cơ → Kim Đan → Nguyên Anh.
- Boss xuất hiện lúc 2:30; thắng ở 4:00 hoặc khi boss bị hạ; thua khi HP về 0.
- HUD, pause bằng `P`, restart bằng `R`, màn thắng/thua bằng tiếng Việt.
- Đồ họa thủy mặc thủ tục trong code và một splash/key-art GPT Image được quản lý qua manifest.

Not in MVP:

- Save/meta progression, tài khoản, bảng xếp hạng, multiplayer.
- Gamepad/touch, remapping UI, nhiều nhân vật, nhiều bản đồ, trang bị và cốt truyện dài.
- Animation sprite sheet hoặc shader hậu kỳ nặng.
- Nhạc nền tạo sinh hay voice-over; audio chỉ là cue nhẹ nếu kịp.

## MVP Success Signals

- Người chơi mới hiểu cách di chuyển, nhận biết phi kiếm tự động và dùng `Space` trong 30 giây đầu mà không cần tutorial modal.
- Ít nhất một lần đột phá xảy ra trong 90 giây đầu ở tuning mặc định.
- Ba thẻ đều mô tả được hiệu quả trong một câu và không có lựa chọn vô tác dụng.
- Một ván luôn kết thúc bằng victory/defeat trong tối đa 4 phút, không kẹt state.
- 60 FPS mục tiêu trên trình duyệt desktop tầm trung; không cần thread support.

## Risks

Design: auto-attack có thể khiến người chơi thụ động; giải pháp là áp lực vị trí và định thời Kiếm Trận.  
Technical: Web export, focus bàn phím, audio autoplay và performance chưa được xác minh khi Godot CLI/export template vắng mặt.  
Art/assets: ink-wash thủ tục có thể giảm tương phản; luôn test ở kích thước gameplay, không chỉ splash.  
Production: card pool và biến thể địch dễ phình phạm vi; MVP giữ một nền tảng linh thú, một biến thể nhanh và một boss.  
QA/playtest: đường cong XP/spawn cần ít nhất ba lượt test đầy đủ 4 phút sau khi có export chạy được.

## Six-Role Review

- Creative: fantasy, tên cảnh giới và visual hook thống nhất.
- Game Design: core loop, win/loss và tuning knobs đều đo được.
- Art: procedural playfield không phụ thuộc key art; palette có vai trò gameplay.
- Technical: Godot 4.4 Compatibility + GDScript phù hợp Web MVP, nhưng export chưa được xác minh.
- Production: chỉ một arena, một active skill, ba realm và một boss.
- QA: fun hypothesis kiểm được trong một lượt 4 phút và các state có acceptance criteria riêng.

## Next Step

Thực hiện `STORY-0001-playable-cultivation-arena` theo systems index và architecture; sau đó chạy Godot 4.4 validation + Web export/browser smoke test khi CLI và export templates có sẵn.

## PLAYER_READY Expansion Contract — 2026-07-30

The original MVP above remains design history. The active product target now extends the same four-minute arena and sect hub instead of replacing them.

### Expanded core fantasy

Người chơi không chỉ né và tăng sát thương: họ dựng một **kiếm vực năm pháp môn**, săn pháp bảo, ghép công pháp–trang bị–linh thú thành một build có bản sắc, rồi mang chiến lợi phẩm về sơn môn để mở lựa chọn mới cho lần nhập thế tiếp theo.

### Expanded loops

- 30 seconds: read threats, reposition, manage up to five active skill cooldowns, collect qi and loot, trigger the right skill into its startup/active/recovery window.
- Four-minute run: reach at most level 20, unlock/rank five active skills, take passives that create tag synergy, survive phase pressure and claim an encounter-scaled reward bundle.
- Session: configure doctrine, equipment and one spirit beast → run → resolve loot/equipment decisions → return to the sect or retry.
- Long term: improve techniques with prerequisites, evolve spirit-beast bonds, refine equipment and unlock synergistic loadouts without invalidating player skill.

### Expanded pillars

1. **Ngũ pháp thành trận** — five equipped skills must create cadence and spatial decisions, not five copies of damage.
2. **Vạn vật tương sinh** — skill tags, doctrine, equipment and spirit-beast bonds combine into legible synergies.
3. **Chiến lợi phẩm có lựa chọn** — every durable reward supports compare/equip/refine/salvage decisions; no dead inventory menu.
4. **Đột phá hữu hình** — rank 3 and rank 5 change behavior, silhouette, timing, VFX and SFX, not only numbers.
5. **Thủy mặc dễ đọc** — enemy telegraphs always outrank player ornament and loot celebration.

### Expanded exclusions

- Still no accounts, cloud save, multiplayer, leaderboards, live events or monetization in the bounded player-ready candidate.
- No open-world quest simulation or NPC relationship sandbox; the project stays a replayable arena-plus-sect game.
- No copied Quỷ Cốc Bát Hoang art, layout, terminology, iconography, VFX or trade dress.
