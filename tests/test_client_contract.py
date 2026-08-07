from __future__ import annotations

import hashlib
import re
import unittest
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "client"


class FlutterClientContractTests(unittest.TestCase):
    def test_client_package_declares_expected_release(self) -> None:
        pubspec = (CLIENT / "pubspec.yaml").read_text(encoding="utf-8")
        editor = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        main_menu = (
            CLIENT / "lib" / "src" / "screens" / "main_menu_screen.dart"
        ).read_text(encoding="utf-8")
        manual = (
            CLIENT / "lib" / "src" / "widgets" / "game_manual.dart"
        ).read_text(encoding="utf-8")
        widget_test = (CLIENT / "test" / "widget_test.dart").read_text(
            encoding="utf-8"
        )

        self.assertIn("version: 0.8.10+62", pubspec)
        self.assertIn("await tester.ensureVisible(profileBack);", widget_test)
        self.assertIn("await tester.pumpAndSettle();\n      await tester.tap(profileBack);", widget_test)
        self.assertIn("final horizontalScrollable = find.ancestor(", widget_test)
        self.assertNotIn("final horizontalScrollable = find.byWidgetPredicate(\n    (widget)", widget_test)
        self.assertIn("${widget.mode.title} • v0.8.10", editor)
        self.assertIn("ANA MERKEZ VE MENÜ DÜZENİ • v0.8.10", main_menu)
        self.assertIn("PROJECT RELAY • v0.8.10", manual)
        self.assertIn("audioplayers:", pubspec)
        self.assertIn("assets/sounds/", pubspec)
        self.assertIn("flame:", pubspec)
        self.assertIn("flutter_riverpod:", pubspec)
        self.assertIn("flutter_secure_storage:", pubspec)
        self.assertNotIn("ProviderListenable<BoardEditorState>", editor)
        self.assertIn(
            "NotifierProvider<BoardController, BoardEditorState> get _boardProvider",
            editor,
        )
        self.assertNotIn("_boardNotifierProvider", editor)

    def test_module_palette_stack_has_finite_height(self) -> None:
        palette = (
            CLIENT / "lib" / "src" / "widgets" / "module_palette.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("height: dense ? 46 : compact ? 44 : 66,", palette)
        self.assertIn("math.min(235.0, compactTileWidth)", palette)
        self.assertIn("alignment: WrapAlignment.center", palette)
        self.assertIn("this.compact = false", palette)
        self.assertIn("compact: true", (CLIENT / "lib" / "src" / "screens" / "editor_screen.dart").read_text(encoding="utf-8"))
        self.assertIn("child: Stack(", palette)
        self.assertNotIn("BoxConstraints(minHeight: 74)", palette)

    def test_replay_labels_and_new_game_action_are_emphasized(self) -> None:
        replay_game = (
            CLIENT / "lib" / "src" / "game" / "replay_game.dart"
        ).read_text(encoding="utf-8")
        controls = (
            CLIENT / "lib" / "src" / "widgets" / "replay_playback_controls.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("size: 14,", replay_game)
        self.assertIn("fontWeight: FontWeight.w900", replay_game)
        self.assertIn("maxWidth: rect.width", replay_game)
        self.assertIn("this.primaryActionLabel = 'YENİ OYUN'", controls)
        self.assertIn("child: Text(primaryActionLabel)", controls)
        self.assertIn("fontSize: 14", controls)
        self.assertIn("letterSpacing: 0.8", controls)

    def test_v049_to_v0413_ui_regression_contract_is_preserved(self) -> None:
        palette = (
            CLIENT / "lib" / "src" / "widgets" / "module_palette.dart"
        ).read_text(encoding="utf-8")
        board = (
            CLIENT / "lib" / "src" / "widgets" / "circuit_board.dart"
        ).read_text(encoding="utf-8")
        editor = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        replay_game = (
            CLIENT / "lib" / "src" / "game" / "replay_game.dart"
        ).read_text(encoding="utf-8")
        replay_screen = (
            CLIENT / "lib" / "src" / "screens" / "replay_screen.dart"
        ).read_text(encoding="utf-8")
        controls = (
            CLIENT / "lib" / "src" / "widgets" / "replay_playback_controls.dart"
        ).read_text(encoding="utf-8")
        controls_test = (
            CLIENT / "test" / "replay_playback_controls_test.dart"
        ).read_text(encoding="utf-8")

        # v0.4.9: bilgi palete taşınır, devre kartı simge-only kalır.
        self.assertIn("palette-module-properties-${module.kind.wireValue}", palette)
        self.assertIn("module-icon-${module.id}", board)
        self.assertNotIn("module-name-${module.id}", board)
        self.assertNotIn("module-stat-badges-${module.id}", board)
        self.assertIn("tooltip: '90° döndür'", board)
        self.assertIn("'ÇEKİRDEK KAPISI'", board)

        # v0.4.10: geniş editör, ayrı geri kartı ve sade sunucu sunumu.
        self.assertIn("BoxConstraints(maxWidth: 1360)", editor)
        self.assertIn("math.min(520.0", editor)
        self.assertIn("'SAVAŞA BAŞLA'", editor)
        self.assertIn("editor-menu-back-card", editor)
        self.assertNotIn("SUNUCU YETKİLİ SAVAŞ", editor)

        # v0.4.11 + v0.4.13: sonlu Stack; v0.6.0 UI rev1 kompakt palet.
        self.assertIn("height: dense ? 46 : compact ? 44 : 66,", palette)
        self.assertIn("child: Stack(", palette)
        self.assertIn("math.min(235.0, compactTileWidth)", palette)
        self.assertIn("alignment: WrapAlignment.center", palette)

        # v0.4.12 + v0.4.13: tek ekran savaş geometrisi ve güçlü etiketler.
        self.assertIn("maxBoardExtent = 488", replay_game)
        self.assertIn("clamp(540.0, 620.0)", replay_screen)
        self.assertIn("leftBoard.right + 14", replay_screen)
        self.assertIn("BoxConstraints(maxWidth: 540)", replay_screen)
        self.assertIn("size: 14,", replay_game)
        self.assertIn("fontWeight: FontWeight.w900", replay_game)
        self.assertIn("width: 220,", controls)
        self.assertIn("height: 40,", controls)
        self.assertIn("minimumSize: Size.zero", controls)
        self.assertIn("tapTargetSize: MaterialTapTargetSize.shrinkWrap", controls)
        self.assertNotIn("minimumSize: const Size(220, 40)", controls)
        self.assertIn("this.primaryActionLabel = 'YENİ OYUN'", controls)
        self.assertIn("child: Text(primaryActionLabel)", controls)
        self.assertNotIn("Icons.add_circle_outline", controls)

        # FittedBox dönüşümleri piksel merkezlerinde makine hassasiyeti farkı yaratabilir.
        self.assertIn("closeTo(playbackButtonCenterY, 0.001)", controls_test)

        # VisualDensity.compact minimum genişliği 8 px küçültebildiği için
        # 220×40 ölçü dış SizedBox ile kesin olarak korunur.
        self.assertIn("width: 220,", controls)
        self.assertIn("height: 40,", controls)
        self.assertIn("minimumSize: Size.zero", controls)
        self.assertIn("tapTargetSize: MaterialTapTargetSize.shrinkWrap", controls)
        self.assertNotIn("minimumSize: const Size(220, 40)", controls)

    def test_flutter_regression_fixtures_follow_v050_contract(self) -> None:
        controls = (
            CLIENT
            / "lib"
            / "src"
            / "widgets"
            / "replay_playback_controls.dart"
        ).read_text(encoding="utf-8")
        sound_test = (
            CLIENT / "test" / "event_sound_player_test.dart"
        ).read_text(encoding="utf-8")
        formatter_test = (
            CLIENT / "test" / "replay_event_formatter_test.dart"
        ).read_text(encoding="utf-8")
        geometry_test = (
            CLIENT / "test" / "circuit_trace_geometry_test.dart"
        ).read_text(encoding="utf-8")
        widget_test = (
            CLIENT / "test" / "widget_test.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("'created_at':", sound_test)
        self.assertGreaterEqual(formatter_test.count("'created_at':"), 2)
        self.assertIn(
            "çekirdek kapısındaki yerleşik modül yalnız simgeyle gösterilir",
            geometry_test,
        )
        self.assertNotIn(
            "çekirdek kapısında modül adı özellik etiketlerinin üstünde kalır",
            geometry_test,
        )
        self.assertIn("LayoutBuilder(", controls)
        self.assertIn("constraints.maxWidth >= 500", controls)
        self.assertIn("fit: BoxFit.scaleDown", controls)
        self.assertIn("await tester.ensureVisible(editorBack);", widget_test)
        self.assertIn(
            "profile-section-match-history",
            widget_test,
        )
        self.assertIn(
            "play-mode-career",
            widget_test,
        )

    def test_v060_progression_foundation_is_visible_and_temporary(self) -> None:
        api = (
            CLIENT / "lib" / "src" / "api" / "relay_api.dart"
        ).read_text(encoding="utf-8")
        models = (
            CLIENT / "lib" / "src" / "models" / "relay_models.dart"
        ).read_text(encoding="utf-8")
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        replay = (
            CLIENT / "lib" / "src" / "screens" / "replay_screen.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("progressionProvider", api)
        self.assertIn("/api/v1/me/progression", api)
        self.assertIn("claimDailyMission", api)
        self.assertIn("claimAchievement", api)
        self.assertIn("class ProgressionSnapshot", models)
        self.assertIn("class BoosterMastery", models)
        self.assertIn("class ProgressionReward", models)
        self.assertIn("class CareerRunSnapshot", models)
        self.assertIn("class CareerOpponentPreview", models)
        self.assertIn("careerRunProvider", api)
        self.assertIn("career-player-board-editor", career)
        self.assertIn("career-opponent-board-preview", career)
        self.assertIn("fixedColumns: 2", career)
        self.assertIn("career-module-selection-card", career)
        self.assertIn("returnToPreviousMenu(context)", career)
        self.assertIn("ModulePalette(", career)
        self.assertIn("career-module-selection-card", career)
        self.assertIn("width: 470", career)
        self.assertIn("run.status == 'failed'", career)
        self.assertIn("? _idle(context)", career)
        self.assertIn("BOSS ÖNCESİ GÜÇLENDİRİCİ MAĞAZASI", career)
        self.assertIn("GÜÇLENDİRİCİ ALMADAN BOSS’A İLERLE", career)
        self.assertIn("SAVAŞ ÖDÜLÜ", replay)
        self.assertIn("RelayNotice.show", replay)
        self.assertNotIn("match-progression-reward", replay)

    def test_v060_ui_revision_keeps_progression_visible_and_editor_compact(self) -> None:
        status = (
            CLIENT / "lib" / "src" / "widgets" / "player_status_bar.dart"
        ).read_text(encoding="utf-8")
        palette = (
            CLIENT / "lib" / "src" / "widgets" / "module_palette.dart"
        ).read_text(encoding="utf-8")
        editor = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        board_controller = (
            CLIENT / "lib" / "src" / "state" / "board_controller.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("guestSessionProvider", status)
        self.assertIn("progressionProvider", status)
        self.assertIn("player-status-name", status)
        self.assertIn("player-status-level", status)
        self.assertIn("player-status-credits", status)
        self.assertIn("player-status-xp", status)
        self.assertIn("DEVRE KREDİSİ", status)
        self.assertIn("height: dense ? 46 : compact ? 44 : 66,", palette)
        self.assertIn("fontSize: dense ? 10.5 : compact ? 10 : 13", palette)
        self.assertIn("fontSize: dense ? 7.5 : compact ? 7.5 : 9.5", palette)
        self.assertIn("size: dense ? 18 : compact ? 18 : 24", palette)
        self.assertGreaterEqual(editor.count("_EditorMenuBackCard(busy: busy)"), 3)
        self.assertIn("void loadSavedBoard(SavedBoard saved)", board_controller)

    def test_v070_season_closed_alpha_and_safety_contract(self) -> None:
        api = (CLIENT / "lib" / "src" / "api" / "relay_api.dart").read_text(encoding="utf-8")
        models = (CLIENT / "lib" / "src" / "models" / "relay_models.dart").read_text(encoding="utf-8")
        season = (CLIENT / "lib" / "src" / "screens" / "season_screen.dart").read_text(encoding="utf-8")
        main_menu = (CLIENT / "lib" / "src" / "screens" / "main_menu_screen.dart").read_text(encoding="utf-8")
        manual = (CLIENT / "lib" / "src" / "widgets" / "game_manual.dart").read_text(encoding="utf-8")
        replay = (CLIENT / "lib" / "src" / "screens" / "replay_screen.dart").read_text(encoding="utf-8")

        self.assertIn("seasonProvider", api)
        self.assertIn("alphaSafetyProvider", api)
        self.assertIn("/api/v1/me/season", api)
        self.assertIn("/api/v1/alpha/feedback", api)
        self.assertIn("class SeasonSnapshotModel", models)
        self.assertIn("class AlphaSafetySnapshotModel", models)
        alpha_feedback = (CLIENT / "lib" / "src" / "screens" / "alpha_feedback_screen.dart").read_text(encoding="utf-8")
        settings = (CLIENT / "lib" / "src" / "screens" / "settings_screen.dart").read_text(encoding="utf-8")
        self.assertIn("İSTATİSTİKLER", season)
        self.assertIn("statistics-section-season", season)
        self.assertIn("statistics-section-weekly-league", season)
        self.assertIn("alpha-feedback-submit", alpha_feedback)
        self.assertIn("settings-alpha-feedback", settings)
        self.assertIn("SeasonPointChangeModel", models)
        self.assertIn("season_change", models)
        self.assertIn("main-menu-profile", main_menu)
        self.assertIn("Sezon Puanı", replay)

    def test_v062_collection_and_controlled_kit_contract(self) -> None:
        api = (
            CLIENT / "lib" / "src" / "api" / "relay_api.dart"
        ).read_text(encoding="utf-8")
        models = (
            CLIENT / "lib" / "src" / "models" / "relay_models.dart"
        ).read_text(encoding="utf-8")
        collection = (
            CLIENT / "lib" / "src" / "screens" / "collection_screen.dart"
        ).read_text(encoding="utf-8")
        controller = (
            CLIENT / "lib" / "src" / "state" / "board_controller.dart"
        ).read_text(encoding="utf-8")
        palette = (
            CLIENT / "lib" / "src" / "widgets" / "module_palette.dart"
        ).read_text(encoding="utf-8")
        main_menu = (
            CLIENT / "lib" / "src" / "screens" / "main_menu_screen.dart"
        ).read_text(encoding="utf-8")
        editor = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("class ControlledKit", models)
        self.assertIn("class CosmeticItem", models)
        self.assertIn("class CollectionSnapshot", models)
        self.assertIn("collectionProvider", api)
        self.assertIn("fetchCollection", api)
        self.assertIn("purchaseCosmetic", api)
        self.assertIn("equipCosmetic", api)
        self.assertIn("saveControlledKit", api)
        self.assertIn("required KitMode mode", api)
        self.assertIn("'mode': mode.wireValue", api)
        self.assertIn("kitFor(KitMode mode)", models)
        self.assertIn("kitMode: widget.mode.kitMode", editor)
        self.assertIn("kitMode: KitMode.career", career)
        self.assertIn("Navigator.of(context).pop(savedKit)", collection)
        self.assertIn("ref.read(_boardProvider.notifier).applyKit(kit)", editor)
        self.assertIn("careerBoardControllerProvider.notifier).applyKit(kit)", career)
        self.assertNotIn("boardControllerProvider", editor)
        self.assertIn("KONTROLLÜ SEKİZLİ KİT", collection)
        self.assertIn("GÜÇ DEĞİL, KİMLİK VE HAZIRLIK", collection)
        self.assertIn("main-menu-store", main_menu)
        self.assertIn("profile-section-cosmetics", (CLIENT / "lib" / "src" / "screens" / "profile_screen.dart").read_text(encoding="utf-8"))
        self.assertIn("profile-cosmetic-section-selector", (CLIENT / "lib" / "src" / "screens" / "profile_screen.dart").read_text(encoding="utf-8"))
        self.assertIn("editor-open-kit-builder", (CLIENT / "lib" / "src" / "screens" / "editor_screen.dart").read_text(encoding="utf-8"))
        self.assertIn("void applyKit(ControlledKit kit)", controller)
        self.assertIn("remainingFor(ModuleKind kind)", controller)
        self.assertIn("remainingByKind", palette)
        self.assertIn("palette-module-remaining-", palette)
        self.assertIn("ref.read(collectionProvider.future)", (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8"))

    def test_back_navigation_distinguishes_previous_and_main_menu(self) -> None:
        navigation = (
            CLIENT / "lib" / "src" / "navigation" / "navigation_actions.dart"
        ).read_text(encoding="utf-8")
        editor = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        profile = (
            CLIENT / "lib" / "src" / "screens" / "profile_screen.dart"
        ).read_text(encoding="utf-8")
        store = (
            CLIENT / "lib" / "src" / "screens" / "collection_screen.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("popUntil((route) => route.isFirst)", navigation)
        self.assertIn("maybePop()", navigation)
        self.assertIn("MENÜYE DÖN", editor)
        self.assertIn("returnToPreviousMenu(context)", editor)
        self.assertIn("MENÜYE DÖN", career)
        self.assertIn("returnToPreviousMenu(context)", career)
        self.assertIn("ANA MENÜYE DÖN", profile)
        self.assertIn("returnToMainMenu(context)", profile)
        self.assertIn("ANA MENÜYE DÖN", store)
        self.assertIn("returnToMainMenu(context)", store)

    def test_session_api_mocks_encode_turkish_json_as_utf8(self) -> None:
        session_test = (
            CLIENT / "test" / "session_api_test.dart"
        ).read_text(encoding="utf-8")

        self.assertIn(
            "'content-type': 'application/json; charset=utf-8'",
            session_test,
        )
        self.assertIn(
            "expect(saved.board.name, 'Kalıcı Devre')",
            session_test,
        )
        self.assertNotIn(
            "http.Response(jsonEncode(_savedBoardPayload()), 200)",
            session_test,
        )

    def test_app_settings_uses_a_const_list_for_double_speeds(self) -> None:
        settings = (
            CLIENT / "lib" / "src" / "state" / "app_settings.dart"
        ).read_text(encoding="utf-8")

        self.assertIn(
            "const supportedReplaySpeeds = <double>[0.25, 0.5, 1, 2];",
            settings,
        )
        self.assertIn("supportedReplaySpeeds.contains(speed)", settings)
        self.assertNotIn("const <double>{", settings)

    def test_bootstrap_replaces_flutter_generated_sources_and_tests(self) -> None:
        powershell = (
            CLIENT / "tool" / "bootstrap_client.ps1"
        ).read_text(encoding="utf-8")
        bash = (
            CLIENT / "tool" / "bootstrap_client.sh"
        ).read_text(encoding="utf-8")

        self.assertIn(
            'Remove-Item (Join-Path $clientRoot "lib") -Recurse -Force',
            powershell,
        )
        self.assertIn(
            'Remove-Item (Join-Path $clientRoot "test") -Recurse -Force',
            powershell,
        )
        self.assertIn(
            'Copy-Item (Join-Path $clientRoot "assets")',
            powershell,
        )
        self.assertIn("if ($LASTEXITCODE -ne 0)", powershell)
        self.assertIn("Invoke-Flutter analyze", powershell)
        self.assertIn("Invoke-Flutter test", powershell)
        self.assertIn("test/widget_test_support_test.dart", powershell)
        self.assertIn("test/module_palette_layout_test.dart", powershell)
        self.assertIn("test/board_controller_test.dart", powershell)
        self.assertIn("test/widget_test.dart", powershell)
        self.assertIn("--concurrency=1", powershell)
        self.assertIn("test/widget_test_support_test.dart", bash)
        self.assertIn("test/module_palette_layout_test.dart", bash)
        self.assertIn("test/board_controller_test.dart", bash)
        self.assertIn("test/widget_test.dart", bash)
        self.assertIn("flutter run -d edge", powershell)
        self.assertIn(
            'rm -rf "$client_root/lib" "$client_root/test"',
            bash,
        )
        self.assertIn(
            'cp -a "$client_root/assets" "$backup_root/assets"',
            bash,
        )

    def test_widget_navigation_tests_use_strict_unique_scroll_review(self) -> None:
        support = (
            CLIENT / "test" / "widget_test_support.dart"
        ).read_text(encoding="utf-8")
        support_test = (
            CLIENT / "test" / "widget_test_support_test.dart"
        ).read_text(encoding="utf-8")
        widget_test = (
            CLIENT / "test" / "widget_test.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("WidgetController.hitTestWarningShouldBeFatal = true", support)
        self.assertIn("findUniqueScrollableWithin", support)
        self.assertIn("physicsMatches", support)
        self.assertIn("target.hitTestable()", support)
        self.assertIn("initialTargetCount <= 1", support)
        self.assertIn("Kaydırma tamamlandığında hedef", support)
        self.assertNotIn(
            "expect(target, findsOneWidget, reason: 'Kaydırılacak hedef benzersiz olmalıdır.')",
            support,
        )
        self.assertIn("ListView.builder", support_test)
        self.assertIn("expect(target, findsNothing)", support_test)
        self.assertIn("tembel oluşturulan hedefi bulur", support_test)
        self.assertIn("AlwaysScrollableScrollPhysics", support_test)
        self.assertIn("NeverScrollableScrollPhysics", support_test)
        self.assertIn("setUpAll(enableStrictWidgetTestMode)", widget_test)
        self.assertIn("physics is AlwaysScrollableScrollPhysics", widget_test)
        self.assertNotIn(
            "widget.axisDirection == AxisDirection.down,\n"
            "        ),\n"
            "      );\n"
            "      expect(careerScrollable, findsOneWidget)",
            widget_test,
        )

    def test_powershell_bootstrap_keeps_platforms_in_one_argument(self) -> None:
        powershell = (
            CLIENT / "tool" / "bootstrap_client.ps1"
        ).read_text(encoding="utf-8")

        self.assertIn('$createArguments = @(', powershell)
        self.assertIn('"--platforms=android,web"', powershell)
        self.assertIn("Invoke-Flutter @createArguments", powershell)
        self.assertNotIn(
            "Invoke-Flutter create . `\n        --platforms=android,web",
            powershell,
        )

    def test_client_uses_gameplay_and_online_endpoints(self) -> None:
        api_source = (
            CLIENT / "lib" / "src" / "api" / "relay_api.dart"
        ).read_text(encoding="utf-8")

        for path in (
            "/api/v1/modules",
            "/api/v1/bots",
            "/api/v1/boards/validate",
            "/api/v1/matches/bot",
            "/api/v1/auth/guest",
            "/api/v1/auth/refresh",
            "/api/v1/me",
            "/api/v1/me/board",
            "/api/v1/matches/async",
            "/api/v1/me/statistics",
            "/api/v1/me/progression",
            "/api/v1/me/collection",
            "/api/v1/me/collection/equipped",
            "/api/v1/me/kit",
            "/api/v1/me/career-run",
            "/api/v1/me/career-run/start",
            "/api/v1/me/career-run/booster",
            "/api/v1/me/career-run/battle",
            "/api/v1/me/career-run/abandon",
            "/daily-missions/",
            "/achievements/",
            "/api/v1/me/matches",
            "/replay",
        ):
            with self.subTest(path=path):
                self.assertIn(path, api_source)

    def test_editor_supports_drag_drop_and_detailed_manual(self) -> None:
        palette_source = (
            CLIENT / "lib" / "src" / "widgets" / "module_palette.dart"
        ).read_text(encoding="utf-8")
        board_source = (
            CLIENT / "lib" / "src" / "widgets" / "circuit_board.dart"
        ).read_text(encoding="utf-8")
        editor_source = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        manual_source = (
            CLIENT / "lib" / "src" / "widgets" / "game_manual.dart"
        ).read_text(encoding="utf-8")
        controller_source = (
            CLIENT / "lib" / "src" / "state" / "board_controller.dart"
        ).read_text(encoding="utf-8")
        models_source = (
            CLIENT / "lib" / "src" / "models" / "relay_models.dart"
        ).read_text(encoding="utf-8")
        widget_test = (
            CLIENT / "test" / "widget_test.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("Draggable<ModuleDragData>", palette_source)
        self.assertIn("DragTarget<ModuleDragData>", board_source)
        self.assertIn("Draggable<ModuleDragData>", board_source)
        self.assertIn("onModuleDropped", board_source)
        self.assertIn("void dropModule(", controller_source)
        self.assertIn("void moveModule(", controller_source)
        self.assertIn("void replaceWithPaletteModule(", controller_source)
        self.assertIn("void removeModuleAt(", controller_source)
        self.assertIn("const maxBoardModules = 6", controller_source)
        self.assertIn("state.placements.length >= maxBoardModules", controller_source)
        self.assertIn("/$maxBoardModules MODÜL", editor_source)
        self.assertIn("onBoardModuleReturned", palette_source)
        self.assertIn("BURAYA BIRAK: KARTTAN KALDIR", palette_source)
        self.assertNotIn("HowToPlayCard", editor_source)
        self.assertIn("OYUNUN AMACI NEDİR?", manual_source)
        self.assertIn("ENERJİ NASIL AKAR?", manual_source)
        self.assertIn("ÖRNEK OYNANIŞ", manual_source)
        self.assertIn("MODÜL DEĞERLERİ NE ANLAMA GELİR?", manual_source)
        self.assertIn("NEDEN TEKRAR OYNAMALI?", manual_source)
        self.assertNotIn("İLERLEME YOLU", manual_source)
        self.assertNotIn("_ProgressStage", manual_source)
        self.assertIn("KALKAN NASIL ÇALIŞIR?", manual_source)
        self.assertIn("SEKİZLİ KİT VE KOLEKSİYON", manual_source)
        self.assertIn("manual-bottom-back-button", manual_source)
        self.assertIn("ANA MENÜYE DÖN", manual_source)
        for module_name in (
            "Jeneratör",
            "Batarya",
            "Lazer",
            "Darbe Topu",
            "Kalkan",
            "Soğutucu",
            "Güçlendirici",
            "Onarım Ünitesi",
        ):
            with self.subTest(module_name=module_name):
                self.assertIn(module_name, manual_source + models_source)
        self.assertIn("RelayApp()", widget_test)
        self.assertNotIn("MyApp()", widget_test)
        self.assertIn("Future<void> _tapProfileSection(", widget_test)
        self.assertIn("widget.axisDirection == AxisDirection.right", widget_test)
        self.assertIn("store-scroll-view", widget_test)
        self.assertIn("profile-section-cosmetics", widget_test)

    def test_main_hub_groups_play_clan_collection_store_and_profile(
        self,
    ) -> None:
        app_source = (
            CLIENT / "lib" / "src" / "app.dart"
        ).read_text(encoding="utf-8")
        main_menu = (
            CLIENT / "lib" / "src" / "screens" / "main_menu_screen.dart"
        ).read_text(encoding="utf-8")
        play_mode = (
            CLIENT / "lib" / "src" / "screens" / "play_mode_screen.dart"
        ).read_text(encoding="utf-8")
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        profile = (
            CLIENT / "lib" / "src" / "screens" / "profile_screen.dart"
        ).read_text(encoding="utf-8")
        collection = (
            CLIENT / "lib" / "src" / "screens" / "collection_screen.dart"
        ).read_text(encoding="utf-8")
        social = (
            CLIENT / "lib" / "src" / "screens" / "social_screen.dart"
        ).read_text(encoding="utf-8")
        status_bar = (
            CLIENT / "lib" / "src" / "widgets" / "player_status_bar.dart"
        ).read_text(encoding="utf-8")
        settings = (
            CLIENT / "lib" / "src" / "screens" / "settings_screen.dart"
        ).read_text(encoding="utf-8")
        how_to_play = (
            CLIENT / "lib" / "src" / "screens" / "how_to_play_screen.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("home: const MainMenuScreen()", app_source)
        self.assertIn("main-menu-play", main_menu)
        self.assertIn("main-menu-clan", main_menu)
        self.assertIn("main-menu-statistics", main_menu)
        self.assertIn("main-menu-store", main_menu)
        self.assertIn("main-menu-profile", main_menu)
        self.assertIn("main-menu-how-to-play", main_menu)
        self.assertIn("main-menu-settings", main_menu)
        self.assertNotIn("main-menu-career", main_menu)
        self.assertNotIn("main-menu-season", main_menu)
        self.assertNotIn("main-menu-collection", main_menu)
        self.assertIn("PlayerStatusBar(", main_menu)
        self.assertIn("showClaimBadge: true", main_menu)
        self.assertIn("player-status-profile-action", status_bar)
        self.assertIn("player-status-claim-badge", status_bar)

        self.assertIn("play-mode-online", play_mode)
        self.assertIn("play-mode-career", play_mode)
        self.assertIn("play-mode-training", play_mode)
        self.assertIn("const CareerScreen()", play_mode)
        self.assertIn("career-scroll-view", career)
        self.assertIn("career-back-button", career)
        self.assertIn("EditorMode.online", play_mode)
        self.assertIn("EditorMode.training", play_mode)

        self.assertIn("profile-section-general", profile)
        self.assertIn("profile-section-cosmetics", profile)
        self.assertIn("profile-section-match-history", profile)
        self.assertIn("profile-section-daily-missions", profile)
        self.assertIn("profile-section-achievements", profile)
        self.assertIn("statisticsProvider", profile)
        self.assertIn("seasonProvider", profile)
        self.assertIn("profile-rating-card", profile)
        self.assertIn("profile-cosmetics-card", profile)
        self.assertIn("profile-cosmetic-section-module", profile)
        self.assertIn("profile-cosmetic-section-board", profile)
        self.assertIn("profile-cosmetic-section-profile", profile)
        self.assertIn("claimDailyMission", profile)
        self.assertIn("claimAchievement", profile)
        self.assertIn("api.fetchReplay(matchId)", profile)

        self.assertIn("CollectionScreenMode.store", collection)
        self.assertIn("kitOnly", collection)
        self.assertIn("kit-save-and-return", collection)
        self.assertIn("_saveKitAndReturn", collection)
        self.assertIn("Navigator.of(context).pop(savedKit)", collection)
        self.assertIn("showSaveButton: false", collection)
        self.assertIn("store-section-selector", collection)
        self.assertIn("store-intro-card", collection)
        self.assertIn("GÖRSEL İÇERİK MAĞAZASI", collection)

        self.assertIn("enum _ClanSection", social)
        self.assertIn("clan-section-selector", social)
        self.assertIn("KLAN ÖZETİ", social)
        self.assertIn("KLAN ETKİNLİĞİ", social)
        self.assertIn("KLAN AYARLARI", social)

        self.assertIn("ref.watch(catalogsProvider)", how_to_play)
        self.assertIn("GameManualScreen(modules: bundle.modules)", how_to_play)
        self.assertIn("settings-replay-sound", settings)
        self.assertIn("settings-replay-speed", settings)

    def test_palette_owns_module_labels_and_stats_while_board_stays_icon_only(
        self,
    ) -> None:
        palette_source = (
            CLIENT / "lib" / "src" / "widgets" / "module_palette.dart"
        ).read_text(encoding="utf-8")
        board_source = (
            CLIENT / "lib" / "src" / "widgets" / "circuit_board.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("module.displayName", palette_source)
        self.assertIn("_moduleStatistics(module)", palette_source)
        self.assertIn("palette-module-properties-", palette_source)
        self.assertIn("final columnCount = fixedColumns ??", palette_source)
        self.assertIn("overflow: TextOverflow.ellipsis", palette_source)
        self.assertIn("BURAYA BIRAK: KARTTAN KALDIR", palette_source)
        self.assertIn("? 4", palette_source)
        self.assertIn("textAlign: TextAlign.center", palette_source)
        self.assertIn("fontSize: dense ? 10.5 : compact ? 10 : 13", palette_source)
        self.assertIn("size: dense ? 18 : compact ? 18 : 24", palette_source)
        self.assertIn("module-icon-${module.id}", board_source)
        self.assertNotIn("module-name-${module.id}", board_source)
        self.assertNotIn("module-stat-badges-${module.id}", board_source)
        self.assertNotIn("_ModuleStatBadges", board_source)
        self.assertIn("if (onRotate != null)", board_source)
        self.assertNotIn("if (selected && onRotate != null)", board_source)

    def test_module_tooltips_use_server_tactical_descriptions(self) -> None:
        palette_source = (
            CLIENT / "lib" / "src" / "widgets" / "module_palette.dart"
        ).read_text(encoding="utf-8")
        models_source = (
            CLIENT / "lib" / "src" / "models" / "relay_models.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("module.description", palette_source)
        self.assertIn("_moduleStatistics(module)", palette_source)
        self.assertNotIn(
            "Boş hücreye yerleştirin veya dolu hücredeki modülü değiştirin.",
            palette_source,
        )
        self.assertIn("json['description']", models_source)

    def test_validation_uses_turkish_module_labels(self) -> None:
        editor_source = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        models_source = (
            CLIENT / "lib" / "src" / "models" / "relay_models.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("_unpoweredModuleLabel", editor_source)
        self.assertIn("placement.kind.displayName", editor_source)
        self.assertIn("ModuleKind.shield => 'Kalkan'", models_source)
        self.assertNotIn(
            "result.unpoweredIds.join(', ')",
            editor_source,
        )

    def test_board_displays_real_ports_and_occupied_drop_actions(self) -> None:
        board_source = (
            CLIENT / "lib" / "src" / "widgets" / "circuit_board.dart"
        ).read_text(encoding="utf-8")
        visual_source = (
            CLIENT / "lib" / "src" / "widgets" / "module_visuals.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("_PortMarker", board_source)
        self.assertIn("worldPorts(module.orientation)", board_source)
        self.assertIn("_CoreHub", board_source)
        self.assertIn("isCoreCell(index)", board_source)
        self.assertIn("coreGateDirections", board_source)
        self.assertIn("CircuitTraceGeometry.modulePortAnchor", board_source)
        self.assertIn("CircuitTraceGeometry.corePortAnchor", board_source)
        self.assertNotIn("drawLine(gateCenter, coreCenter", board_source)
        self.assertIn(
            "placement.kind == ModuleKind.battery",
            board_source,
        )
        self.assertIn(
            "kullanılabilir uçlar gösterilir",
            visual_source,
        )
        self.assertIn("usableBoardPorts(", board_source)
        self.assertIn("module-direction-$cellIndex", board_source)
        self.assertIn("'YER DEĞİŞTİR'", board_source)
        self.assertIn("'DEĞİŞTİR'", board_source)

    def test_central_core_topology_is_enforced_in_client(self) -> None:
        models_source = (
            CLIENT / "lib" / "src" / "models" / "relay_models.dart"
        ).read_text(encoding="utf-8")
        controller_source = (
            CLIENT / "lib" / "src" / "state" / "board_controller.dart"
        ).read_text(encoding="utf-8")
        editor_source = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        manual_source = (
            CLIENT / "lib" / "src" / "widgets" / "game_manual.dart"
        ).read_text(encoding="utf-8")
        replay_source = (
            CLIENT / "lib" / "src" / "game" / "replay_game.dart"
        ).read_text(encoding="utf-8")
        board_source = (
            CLIENT / "lib" / "src" / "widgets" / "circuit_board.dart"
        ).read_text(encoding="utf-8")
        visual_source = (
            CLIENT / "lib" / "src" / "widgets" / "module_visuals.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("reservedCoreCells = <int>{5, 6, 9, 10}", models_source)
        self.assertIn("coreGateDirections", models_source)
        self.assertIn("_checkPlaceableCell", controller_source)
        self.assertIn("isCoreGate(targetCell)", controller_source)
        self.assertNotIn("çekirdeğe kilitli", editor_source)
        self.assertIn(
            "Jeneratör çekirdeğe dönük kalır",
            visual_source,
        )
        self.assertIn("moduleDisplayDirection", board_source)
        self.assertIn("usesConnectionDirectionArrow", visual_source)
        self.assertIn("rotate-module-$cellIndex", board_source)
        self.assertNotIn("Icons.delete_outline", editor_source)
        self.assertIn("boardMaxWidth", editor_source)
        self.assertIn("math.min(520.0", editor_source)
        self.assertIn("bot-picker-scrollbar", editor_source)
        self.assertIn("bot-picker-list", editor_source)
        self.assertNotIn("compact-how-to-play-card", manual_source)
        self.assertNotIn("_QuickRule", manual_source)
        self.assertNotIn("_HowToStep", manual_source)
        self.assertIn("maxWidth: 1360", editor_source)
        self.assertIn("_drawBoardCore", replay_source)
        self.assertIn("_moduleHasCorePort", replay_source)
        self.assertIn("ReplayCircuitGeometry.modulePortAnchor", replay_source)
        self.assertIn("ReplayCircuitGeometry.corePortAnchor", replay_source)
        self.assertIn("_drawModulePorts", replay_source)
        self.assertIn("usableBoardPorts(", replay_source)
        self.assertNotIn("final coreCenter = rect.center", replay_source)
        self.assertNotIn("_moduleCenter(fromModule", replay_source)
        self.assertNotIn("class _Metric", (
            CLIENT / "lib" / "src" / "screens" / "replay_screen.dart"
        ).read_text(encoding="utf-8"))

    def test_replay_remains_server_result_driven(self) -> None:
        editor_source = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        manual_source = (
            CLIENT / "lib" / "src" / "widgets" / "game_manual.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("createBotMatch", editor_source)
        self.assertIn("createAsyncMatch", editor_source)
        self.assertIn("saveBoard", editor_source)
        self.assertIn("fetchReplay", editor_source)
        self.assertIn("replay.checksum != match.replayChecksum", editor_source)
        self.assertIn(
            "'Jeneratör imha edilince en son çekirdek hedefe '",
            manual_source,
        )

    def test_replay_shows_boards_turkish_feed_controls_and_sound(self) -> None:
        replay_screen = (
            CLIENT / "lib" / "src" / "screens" / "replay_screen.dart"
        ).read_text(encoding="utf-8")
        replay_game = (
            CLIENT / "lib" / "src" / "game" / "replay_game.dart"
        ).read_text(encoding="utf-8")
        formatter = (
            CLIENT / "lib" / "src" / "game" / "replay_event_formatter.dart"
        ).read_text(encoding="utf-8")
        sound_player = (
            CLIENT / "lib" / "src" / "game" / "event_sound_player.dart"
        ).read_text(encoding="utf-8")
        event_feed = (
            CLIENT / "lib" / "src" / "widgets" / "replay_event_feed.dart"
        ).read_text(encoding="utf-8")
        playback_controls = (
            CLIENT
            / "lib"
            / "src"
            / "widgets"
            / "replay_playback_controls.dart"
        ).read_text(encoding="utf-8")
        attack_overlay = (
            CLIENT
            / "lib"
            / "src"
            / "widgets"
            / "replay_attack_overlay.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("match.playerBoard", replay_game)
        self.assertIn("match.opponentBoard", replay_game)
        self.assertIn("maxBoardExtent = 488", replay_game)
        self.assertIn("ReplayStageGeometry.leftBoard", replay_game)
        self.assertIn("ReplayStageGeometry.rightBoard", replay_game)
        self.assertIn("_drawModuleIcon", replay_game)
        self.assertNotIn("_moduleCode", replay_game)
        self.assertIn("height: stageHeight", replay_screen)
        self.assertIn("clamp(540.0, 620.0)", replay_screen)
        self.assertIn("maxWidth: 540", replay_screen)
        self.assertIn("mediaSize.width >= 1500", replay_screen)
        self.assertNotIn("appBar:", replay_screen)
        self.assertIn("onNewGame: _primaryAction", replay_screen)
        self.assertIn("_togglePlayback", replay_screen)
        self.assertIn("ReplayEventFeed", replay_screen)
        self.assertIn("ReplayAttackOverlay", replay_screen)
        self.assertIn("useInlineEventFeed", replay_screen)
        self.assertIn("compact: true", replay_screen)
        self.assertNotIn("Savaş Tekrarı", replay_screen)
        self.assertNotIn("DropdownButton<double>", replay_screen)
        self.assertNotIn("IconButton.filledTonal", replay_screen)
        self.assertIn("CANLI OLAY AKIŞI", event_feed)
        self.assertIn("inline-server-result", event_feed)
        self.assertIn("SUNUCU SONUCU", event_feed)
        self.assertIn("live-server-metrics", event_feed)
        self.assertIn("CANLI • ADIM $visibleTick/${result.ticks}", event_feed)
        self.assertIn("currentLeftHp: snapshot.leftHp", replay_screen)
        self.assertIn("currentRightHp: snapshot.rightHp", replay_screen)
        self.assertIn("if (widget.compact)", event_feed)
        self.assertIn("Expanded(child: eventList)", event_feed)
        self.assertIn("height: compact ? 150 : 182", event_feed)
        self.assertIn("_DecisionTable", event_feed)
        self.assertIn("← KARAR", event_feed)
        self.assertIn("Hasar/enerji", event_feed)
        self.assertIn("Toplam ısı ↓", event_feed)
        self.assertIn("controls: widget.controls", event_feed)
        self.assertIn("controls!", event_feed)
        self.assertIn("replay-playback-controls", playback_controls)
        self.assertIn("replay-playback-button", playback_controls)
        self.assertIn("replay-restart-button", playback_controls)
        self.assertIn("replay-sound-button", playback_controls)
        self.assertIn("replay-speed-button", playback_controls)
        self.assertIn("replay-new-game-button", playback_controls)
        self.assertNotIn("Icons.add_circle_outline", playback_controls)
        self.assertIn("Wrap(", playback_controls)
        self.assertIn("width: 220,", playback_controls)
        self.assertIn("height: 40,", playback_controls)
        self.assertIn("minimumSize: Size.zero", playback_controls)
        self.assertIn(
            "tapTargetSize: MaterialTapTargetSize.shrinkWrap",
            playback_controls,
        )
        self.assertNotIn(
            "minimumSize: const Size(220, 40)",
            playback_controls,
        )
        controls_test = (
            CLIENT / "test" / "replay_playback_controls_test.dart"
        ).read_text(encoding="utf-8")
        self.assertIn("width: 540", controls_test)
        self.assertIn("const Size(220, 40)", controls_test)
        self.assertIn("Yeniden Oynat", playback_controls)
        self.assertIn("YENİ OYUN", playback_controls)
        self.assertIn("Hız ${_speedLabel(speed)}", playback_controls)
        self.assertNotIn("_ResultDetails", replay_screen)
        self.assertNotIn("class _Metric", replay_screen)
        self.assertIn("ScrollController", event_feed)
        self.assertIn("thumbVisibility: true", event_feed)
        self.assertNotIn("allVisible.take(7)", event_feed)
        self.assertIn("_drawEnergyTransmission", replay_game)
        self.assertIn("_animationTime", replay_game)
        self.assertIn(
            "package:flutter/foundation.dart",
            attack_overlay,
        )
        self.assertIn("CustomPaint", attack_overlay)
        self.assertIn("IgnorePointer", attack_overlay)
        self.assertIn("event.type == 'shield_absorb'", attack_overlay)
        self.assertIn("ModuleReplayState", replay_game)
        self.assertIn("_moduleEnergyLabel", replay_game)
        self.assertIn("'Can: ", replay_game)
        self.assertIn("'Enerji: ", replay_game)
        self.assertIn("'Isı: ", replay_game)
        self.assertIn("'Doluyor: ", replay_game)

        self.assertIn("'Hazır'", replay_game)
        self.assertIn("_deltaSuffix", replay_game)
        self.assertNotIn("ui.Offset(width / 2, height - 16)", replay_game)
        self.assertIn("boardState.energyReserve", replay_game)
        self.assertIn("boardState.shield", replay_game)
        self.assertIn("imha edildi", formatter)
        self.assertNotIn(r"${event.targetId} imha edildi", replay_game)
        self.assertIn("AudioPlayer", sound_player)
        for sound_name in (
            "laser.wav",
            "pulse_cannon.wav",
            "attack.wav",
            "core_damage.wav",
            "shield_charge.wav",
            "shield_absorb.wav",
            "cool.wav",
            "repair.wav",
            "recovered.wav",
            "overheat.wav",
            "energy_starved.wav",
            "destroyed.wav",
        ):
            with self.subTest(sound_name=sound_name):
                self.assertTrue(
                    (CLIENT / "assets" / "sounds" / sound_name).is_file()
                )
        self.assertIn(
            "ModuleKind.laser => 'laser.wav'",
            sound_player,
        )
        self.assertIn(
            "ModuleKind.pulseCannon => 'pulse_cannon.wav'",
            sound_player,
        )
        self.assertIn(
            "_play('shield_absorb.wav', 0.58)",
            sound_player,
        )

    def test_game_uses_centered_translucent_notices(self) -> None:
        editor_source = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        career_source = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        statistics_source = (
            CLIENT / "lib" / "src" / "screens" / "statistics_screen.dart"
        ).read_text(encoding="utf-8")
        notice_source = (
            CLIENT / "lib" / "src" / "widgets" / "relay_notice.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("relay-centered-notice", notice_source)
        self.assertIn("OverlayEntry", notice_source)
        self.assertIn("child: Center(", notice_source)
        self.assertIn("withValues(alpha:", notice_source)
        self.assertIn("Timer? _dismissTimer", notice_source)
        self.assertIn("_dismissTimer?.cancel()", notice_source)
        self.assertIn("RelayNotice.show", editor_source)
        self.assertIn("RelayNotice.show", career_source)
        self.assertIn("RelayNotice.show", statistics_source)
        self.assertNotIn("showSnackBar", editor_source)
        self.assertNotIn("showSnackBar", career_source)
        self.assertNotIn("showSnackBar", statistics_source)


    def test_v061_revision_separates_boards_and_updates_career_flow(self) -> None:
        api = (
            CLIENT / "lib" / "src" / "api" / "relay_api.dart"
        ).read_text(encoding="utf-8")
        editor = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        manual = (
            CLIENT / "lib" / "src" / "widgets" / "game_manual.dart"
        ).read_text(encoding="utf-8")
        visuals = (
            CLIENT / "lib" / "src" / "widgets" / "module_visuals.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("/api/v1/me/career-board", api)
        self.assertIn("fetchCareerBoard", editor)
        self.assertIn("saveCareerBoard", editor)
        self.assertIn("editor-page-scrollbar", editor)
        self.assertIn("thumbVisibility: true", editor)
        self.assertIn("SONRAKİ SAVAŞA İLERLE", career)
        self.assertIn("BOSS ÖNCESİ GÜÇLENDİRİCİ MAĞAZASI", career)
        self.assertIn("booster.creditCost", career)
        self.assertIn("career-booster-skip", career)
        self.assertIn("KARİYER KOŞUSU VE KARŞI DEVRE", manual)
        self.assertIn("Kariyer devresi ile Asenkron PvP devresi ayrı", manual)
        self.assertIn("orientation.opposite", visuals)
        self.assertIn("Enerji bağlantısı", visuals)

    def test_v061_rev3_has_separate_career_battle_and_centered_async_reward(self) -> None:
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        career_battle = (
            CLIENT / "lib" / "src" / "screens" / "career_battle_screen.dart"
        ).read_text(encoding="utf-8")
        replay = (
            CLIENT / "lib" / "src" / "screens" / "replay_screen.dart"
        ).read_text(encoding="utf-8")
        controls = (
            CLIENT / "lib" / "src" / "widgets" / "replay_playback_controls.dart"
        ).read_text(encoding="utf-8")
        manual = (
            CLIENT / "lib" / "src" / "widgets" / "game_manual.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("CareerBattleScreen(", career)
        self.assertNotIn("builder: (context) => ReplayScreen(", career)
        self.assertIn("class CareerBattleScreen", career_battle)
        self.assertIn("career-battle-screen", career_battle)
        self.assertIn("SONRAKİ SAVAŞ", career_battle)
        self.assertIn("BOSS HAZIRLIĞINA GEÇ", career_battle)
        self.assertIn("KOŞUYU TAMAMLA", career_battle)
        self.assertIn("KARİYER EKRANINA DÖN", career_battle)
        self.assertIn("primaryActionRequiresCompletion: true", career_battle)
        self.assertIn("primaryActionLabel", controls)
        self.assertIn("primaryActionEnabled", controls)
        self.assertIn("widget.match.source == 'async'", replay)
        self.assertIn("widget.completionReward", replay)
        self.assertIn("SAVAŞ ÖDÜLÜ", replay)
        self.assertIn("RelayNotice.show", replay)
        self.assertNotIn("match-progression-reward", replay)
        self.assertIn("Kariyer savaşları kendine ait savaş ekranında", manual)
        self.assertIn("Asenkron PvP savaşının XP ve Devre Kredisi ödülü", manual)

    def test_replay_scrollbar_and_audio_lifecycle_regressions(self) -> None:
        event_feed = (
            CLIENT / "lib" / "src" / "widgets" / "replay_event_feed.dart"
        ).read_text(encoding="utf-8")
        sound_player = (
            CLIENT / "lib" / "src" / "game" / "event_sound_player.dart"
        ).read_text(encoding="utf-8")
        feed_test = (
            CLIENT / "test" / "replay_event_formatter_test.dart"
        ).read_text(encoding="utf-8")
        sound_test = (
            CLIENT / "test" / "event_sound_player_test.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("replay-event-scrollbar", event_feed)
        self.assertIn("replay-event-list", event_feed)
        self.assertIn("primary: false", event_feed)
        self.assertIn("scrollbars: false", event_feed)
        self.assertIn("controller: _scrollController", event_feed)
        self.assertIn("controller!.hasClients", feed_test)
        self.assertIn("PointerDeviceKind.mouse", feed_test)
        self.assertIn("final resultBottom", feed_test)
        self.assertIn("greaterThan(resultBottom.dy)", feed_test)
        self.assertNotIn(
            "of: find.byKey(const ValueKey('inline-server-result'))",
            feed_test,
        )
        self.assertIn("EventSoundChannelFactory", sound_player)
        self.assertIn("_activeChannels", sound_player)
        self.assertIn("channel.onComplete.first", sound_player)
        self.assertNotIn("List.generate(5, (_) => AudioPlayer())", sound_player)
        self.assertNotIn("_cursor", sound_player)
        self.assertIn("hızlı olaylar", sound_test)
        self.assertIn("ekran kapanışı", sound_test)
        self.assertIn("'decision': {", sound_test)

    def test_replay_contract_exposes_tick_state_frames(self) -> None:
        models = (
            CLIENT / "lib" / "src" / "models" / "relay_models.dart"
        ).read_text(encoding="utf-8")
        replay_game = (
            CLIENT / "lib" / "src" / "game" / "replay_game.dart"
        ).read_text(encoding="utf-8")
        api_app = (ROOT / "relay_api" / "app.py").read_text(
            encoding="utf-8"
        )

        self.assertIn("class ReplayStateFrame", models)
        self.assertIn("class BoardReplayState", models)
        self.assertIn("class ModuleReplayState", models)
        self.assertIn("json['state_frames']", models)
        self.assertIn("replay.stateAt(frame.tick)", replay_game)
        self.assertIn('"state_frames": _perspective_frames(', api_app)

    def test_guest_session_and_async_pvp_are_visible_and_persistent(
        self,
    ) -> None:
        api_source = (
            CLIENT / "lib" / "src" / "api" / "relay_api.dart"
        ).read_text(encoding="utf-8")
        storage_source = (
            CLIENT / "lib" / "src" / "api" / "session_storage.dart"
        ).read_text(encoding="utf-8")
        editor_source = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        session_test = (
            CLIENT / "test" / "session_api_test.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("guestSessionProvider", api_source)
        self.assertIn("bootstrapSession", api_source)
        self.assertIn("allowRefresh: false", api_source)
        self.assertIn("Authorization", api_source)
        self.assertIn("FlutterSecureStorage", storage_source)
        self.assertIn("relay.refresh_token", storage_source)
        self.assertIn("ASENKRON PvP", editor_source)
        self.assertIn("SAVAŞA BAŞLA", editor_source)
        self.assertIn("editor-menu-back-button", editor_source)
        self.assertIn("ANTRENMAN RAKİPLERİ", editor_source)
        self.assertIn("mode == EditorMode.online", editor_source)
        self.assertIn("AppHeaderActions()", editor_source)
        self.assertIn("süresi dolan erişim", session_test)

    def test_combat_sounds_are_distinct_local_waveforms(self) -> None:
        sound_names = (
            "laser.wav",
            "pulse_cannon.wav",
            "attack.wav",
            "core_damage.wav",
            "shield_charge.wav",
            "shield_absorb.wav",
            "cool.wav",
            "repair.wav",
            "recovered.wav",
            "overheat.wav",
            "energy_starved.wav",
            "destroyed.wav",
        )
        hashes: set[str] = set()
        for sound_name in sound_names:
            with self.subTest(sound_name=sound_name):
                path = CLIENT / "assets" / "sounds" / sound_name
                hashes.add(hashlib.sha256(path.read_bytes()).hexdigest())
                with wave.open(str(path), "rb") as sound:
                    self.assertEqual(sound.getnchannels(), 1)
                    self.assertEqual(sound.getsampwidth(), 2)
                    self.assertEqual(sound.getframerate(), 44_100)
                    self.assertGreater(
                        sound.getnframes() / sound.getframerate(),
                        0.25,
                    )
        self.assertEqual(len(hashes), len(sound_names))
        generator = (
            CLIENT / "tool" / "generate_sounds.py"
        ).read_text(encoding="utf-8")
        self.assertIn('"laser.wav": _laser()', generator)
        self.assertIn('"shield_absorb.wav": _shield_impact()', generator)

    def test_equipped_cosmetics_drive_editor_replay_and_profile_visuals(self) -> None:
        visuals = (
            CLIENT / "lib" / "src" / "theme" / "cosmetic_visuals.dart"
        ).read_text(encoding="utf-8")
        editor = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        board = (
            CLIENT / "lib" / "src" / "widgets" / "circuit_board.dart"
        ).read_text(encoding="utf-8")
        replay_screen = (
            CLIENT / "lib" / "src" / "screens" / "replay_screen.dart"
        ).read_text(encoding="utf-8")
        replay_game = (
            CLIENT / "lib" / "src" / "game" / "replay_game.dart"
        ).read_text(encoding="utf-8")
        attack_overlay = (
            CLIENT / "lib" / "src" / "widgets" / "replay_attack_overlay.dart"
        ).read_text(encoding="utf-8")
        player_status = (
            CLIENT / "lib" / "src" / "widgets" / "player_status_bar.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("class EquippedVisuals", visuals)
        self.assertIn("board_ion_storm", visuals)
        self.assertIn("board_mint_matrix", visuals)
        self.assertIn("module_coral_pulse", visuals)
        self.assertIn("module_mint_flux", visuals)
        self.assertIn("frame_ranked_gold", visuals)
        self.assertIn("frame_boss_core", visuals)
        self.assertIn("EquippedVisuals.fromCollection(collection)", editor)
        self.assertIn("visuals: _visuals", editor)
        self.assertIn("circuit-board-theme-", board)
        self.assertIn("leftVisuals: _leftVisuals", replay_screen)
        self.assertIn("leftVisuals.modules.attack", replay_game)
        self.assertIn("sideVisuals.modules.attack", attack_overlay)
        self.assertIn("ProfileFrameVisualTheme.fromId", player_status)

    def test_level_up_celebration_and_boss_tier_explanation_are_visible(self) -> None:
        notice = (
            CLIENT / "lib" / "src" / "widgets" / "relay_notice.dart"
        ).read_text(encoding="utf-8")
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        career_battle = (
            CLIENT / "lib" / "src" / "screens" / "career_battle_screen.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("relay-level-up-badge", notice)
        self.assertIn("SEVİYE ATLADIN", notice)
        self.assertIn("BOSS GÜÇLENDİRİCİ KADEMESİ K2 AÇILDI", notice)
        self.assertIn("BOSS GÜÇLENDİRİCİ KADEMELERİ", career)
        self.assertIn("modüllere kalıcı güç vermez", career)
        self.assertIn("completionReward: outcome.run.reward", career_battle)

    def test_known_flutter_analyzer_findings_are_fixed(self) -> None:
        replay_source = (
            CLIENT / "lib" / "src" / "game" / "replay_game.dart"
        ).read_text(encoding="utf-8")
        editor_source = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("super.render(canvas);", replay_source)
        self.assertNotIn("this.life = 1", replay_source)
        self.assertNotIn(
            "final validation = boardState.validation;",
            editor_source,
        )
        self.assertIn("?trailing,", editor_source)


    def test_v084_profile_clan_header_and_career_preparation_contract(self) -> None:
        main_menu = (
            CLIENT / "lib" / "src" / "screens" / "main_menu_screen.dart"
        ).read_text(encoding="utf-8")
        profile = (
            CLIENT / "lib" / "src" / "screens" / "profile_screen.dart"
        ).read_text(encoding="utf-8")
        social = (
            CLIENT / "lib" / "src" / "screens" / "social_screen.dart"
        ).read_text(encoding="utf-8")
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        header = (
            CLIENT / "lib" / "src" / "widgets" / "app_header_actions.dart"
        ).read_text(encoding="utf-8")
        feature_pool = (
            ROOT / "docs" / "OZELLIK_HAVUZU.md"
        ).read_text(encoding="utf-8")
        release = (
            ROOT / "docs" / "V0.8.4_PROFIL_KLAN_VE_KARIYER_HAZIRLIK.md"
        ).read_text(encoding="utf-8")
        widget_test = (
            CLIENT / "test" / "widget_test.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("main-menu-clan", main_menu)
        self.assertIn("ProfileSection.friends", profile)
        self.assertIn("profile-section-friends", profile)
        self.assertIn("embeddedProfileOnly: true", profile)
        self.assertIn("embeddedFriendsOnly: true", profile)
        self.assertNotIn("profile-open-clan", profile)
        self.assertNotIn("profile-edit-social", profile)
        self.assertIn("KLAN ÖZETİ", social)
        self.assertNotIn("SOSYAL MERKEZ", social)
        self.assertNotIn("social-section-selector", social)
        self.assertIn("AppHeaderActions", header)
        self.assertIn("/profile", header)
        self.assertIn("/settings", header)
        self.assertIn("/how-to-play", header)
        self.assertIn("career-player-board-editor", career)
        self.assertIn("career-opponent-board-preview", career)
        self.assertIn("fixedColumns: 2", career)
        self.assertIn("career-module-selection-card", career)
        self.assertIn("returnToPreviousMenu(context)", career)
        self.assertIn("KOŞUYU BAŞLAT", career)
        self.assertNotIn("title: 'GÜNLÜK GÖREVLER'", career)
        self.assertNotIn("title: 'BAŞARIMLAR'", career)
        self.assertIn("Komutan Sistemi", feature_pool)
        self.assertIn("devreyi kurduktan ve doğruladıktan sonra", feature_pool.lower())
        self.assertIn("v0.8.4", release)
        self.assertIn("ÇEVRİMİÇİ SAVAŞ • v0.8.10", widget_test)
        self.assertIn("ANTRENMAN • v0.8.10", widget_test)
        self.assertNotIn("ÇEVRİMİÇİ SAVAŞ • v0.8.4", widget_test)
        self.assertNotIn("ANTRENMAN • v0.8.4", widget_test)

        status_bar = (
            CLIENT / "lib" / "src" / "widgets" / "player_status_bar.dart"
        ).read_text(encoding="utf-8")
        self.assertNotIn("asData?.value?.", profile)
        self.assertNotIn("asData?.value?.", status_bar)
        self.assertIn(
            "_ClanSection _selectedClanSection = _ClanSection.summary;",
            social,
        )
        self.assertEqual(social.count("Widget _clanSection("), 1)
        self.assertNotIn("_ClanSection _clanSection =", social)
        self.assertNotIn("class _MetricPill", social)
        self.assertNotIn("this.trailing", career)
        self.assertNotIn("final String? trailing", career)

    def test_v082_social_interface_productization_contract(self) -> None:
        social = (
            CLIENT / "lib" / "src" / "screens" / "social_screen.dart"
        ).read_text(encoding="utf-8")
        feature_pool = (
            ROOT / "docs" / "OZELLIK_HAVUZU.md"
        ).read_text(encoding="utf-8")
        release = (
            ROOT / "docs" / "V0.8.2_SOSYAL_ARAYUZ_URUNLESTIRME.md"
        ).read_text(encoding="utf-8")

        self.assertIn("embeddedProfileOnly", social)
        self.assertIn("embeddedFriendsOnly", social)
        self.assertNotIn("SOSYAL MERKEZ", social)
        self.assertIn("social-outgoing-requests", social)
        settings = (CLIENT / "lib" / "src" / "screens" / "settings_screen.dart").read_text(encoding="utf-8")
        alpha_feedback = (CLIENT / "lib" / "src" / "screens" / "alpha_feedback_screen.dart").read_text(encoding="utf-8")
        self.assertNotIn("social-safety-card", social)
        self.assertIn("settings-alpha-feedback", settings)
        self.assertIn("alpha-feedback-submit", alpha_feedback)
        self.assertIn("Arkadaşlığı kaldır", social)
        self.assertIn("Klanı kapat", social)
        self.assertIn("Komutan Sistemi", feature_pool)
        self.assertIn("Oyuncu devreyi kurduktan ve doğruladıktan sonra", feature_pool)
        self.assertIn("Oyuncu Tarzı Profili", feature_pool)
        self.assertIn("v0.8.2", release)

    def test_v080_social_friendship_and_clan_contract(self) -> None:
        api = (
            CLIENT / "lib" / "src" / "api" / "relay_api.dart"
        ).read_text(encoding="utf-8")
        models = (
            CLIENT / "lib" / "src" / "models" / "relay_models.dart"
        ).read_text(encoding="utf-8")
        social = (
            CLIENT / "lib" / "src" / "screens" / "social_screen.dart"
        ).read_text(encoding="utf-8")
        main_menu = (
            CLIENT / "lib" / "src" / "screens" / "main_menu_screen.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("socialProvider", api)
        self.assertIn("clanDirectoryProvider", api)
        self.assertIn("/api/v1/me/social", api)
        self.assertIn("/api/v1/social/players", api)
        self.assertIn("/api/v1/clans", api)
        self.assertIn("class SocialSnapshotModel", models)
        self.assertIn("class ClanModel", models)
        self.assertIn("social-player-search", social)
        self.assertIn("social-clan-directory", social)
        self.assertIn("main-menu-clan", main_menu)

    def test_dart_named_constructor_parameters_are_unique(self) -> None:
        constructor_pattern = re.compile(
            r"(?:const\s+)?[A-Za-z_]\w*\s*\(\s*\{(?P<body>.*?)\}\s*\)",
            re.DOTALL,
        )
        failures: list[str] = []
        for path in sorted(CLIENT.rglob("*.dart")):
            source = path.read_text(encoding="utf-8")
            for match in constructor_pattern.finditer(source):
                names = re.findall(r"(?:required\s+)?this\.([A-Za-z_]\w*)", match.group("body"))
                duplicates = sorted({name for name in names if names.count(name) > 1})
                if duplicates:
                    failures.append(
                        f"{path.relative_to(ROOT)}: yinelenen constructor parametreleri {duplicates}"
                    )
        self.assertEqual(failures, [], "\n".join(failures))


if __name__ == "__main__":
    unittest.main()
