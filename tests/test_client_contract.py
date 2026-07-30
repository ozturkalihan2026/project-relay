from __future__ import annotations

import hashlib
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

        self.assertIn("version: 0.4.13+32", pubspec)
        self.assertIn("${widget.mode.title} • v0.4.13", editor)
        self.assertIn("ASENKRON DEVRE SAVAŞI • v0.4.13", main_menu)
        self.assertIn("PROJECT RELAY • v0.4.13", manual)
        self.assertIn("audioplayers:", pubspec)
        self.assertIn("assets/sounds/", pubspec)
        self.assertIn("flame:", pubspec)
        self.assertIn("flutter_riverpod:", pubspec)
        self.assertIn("flutter_secure_storage:", pubspec)

    def test_module_palette_stack_has_finite_height(self) -> None:
        palette = (
            CLIENT / "lib" / "src" / "widgets" / "module_palette.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("height: 74,", palette)
        self.assertIn("computedTileWidth > 255", palette)
        self.assertIn("alignment: WrapAlignment.center", palette)
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
        self.assertIn("child: const Text('YENİ OYUN')", controls)
        self.assertIn("fontSize: 14", controls)
        self.assertIn("letterSpacing: 0.8", controls)

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
        self.assertIn("flutter run -d edge", powershell)
        self.assertIn(
            'rm -rf "$client_root/lib" "$client_root/test"',
            bash,
        )
        self.assertIn(
            'cp -a "$client_root/assets" "$backup_root/assets"',
            bash,
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
            "/api/v1/me/board",
            "/api/v1/matches/async",
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

    def test_main_menu_separates_online_training_career_and_settings(
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
        editor = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        career = (
            CLIENT / "lib" / "src" / "screens" / "career_screen.dart"
        ).read_text(encoding="utf-8")
        settings = (
            CLIENT / "lib" / "src" / "screens" / "settings_screen.dart"
        ).read_text(encoding="utf-8")
        how_to_play = (
            CLIENT / "lib" / "src" / "screens" / "how_to_play_screen.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("home: const MainMenuScreen()", app_source)
        self.assertIn("main-menu-play", main_menu)
        self.assertIn("main-menu-career", main_menu)
        self.assertIn("main-menu-how-to-play", main_menu)
        self.assertIn("main-menu-settings", main_menu)
        self.assertLess(
            main_menu.index("main-menu-career"),
            main_menu.index("main-menu-how-to-play"),
        )
        self.assertLess(
            main_menu.index("main-menu-how-to-play"),
            main_menu.index("main-menu-settings"),
        )
        self.assertIn("ref.watch(catalogsProvider)", how_to_play)
        self.assertIn("GameManualScreen(modules: bundle.modules)", how_to_play)
        self.assertNotIn("ÇIKIŞ", main_menu)
        self.assertIn("play-mode-online", play_mode)
        self.assertIn("play-mode-training", play_mode)
        self.assertIn("EditorMode.online", play_mode)
        self.assertIn("EditorMode.training", play_mode)
        self.assertIn("mode == EditorMode.online", editor)
        self.assertIn("training-panel", editor)
        self.assertIn("async-pvp-card", editor)
        self.assertIn("KARİYER HAZIRLANIYOR", career)
        self.assertIn("settings-replay-sound", settings)
        self.assertIn("settings-replay-speed", settings)
        self.assertIn("play-mode-back-button", play_mode)
        self.assertIn("settings-back-button", settings)
        self.assertIn("SAVAŞA BAŞLA", editor)
        self.assertIn("editor-menu-back-card", editor)
        self.assertIn("editor-menu-back-button", editor)
        self.assertNotIn("SUNUCU YETKİLİ SAVAŞ", editor)
        for section_index in ("1", "2", "3", "4"):
            self.assertIn(f"index: '{section_index}'", editor)
        for old_index in ("01", "02", "03", "04"):
            self.assertNotIn(f"index: '{old_index}'", editor)

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
        self.assertIn("final columnCount = constraints.maxWidth >= 720", palette_source)
        self.assertIn("? 4", palette_source)
        self.assertIn("textAlign: TextAlign.center", palette_source)
        self.assertIn("fontSize: 13", palette_source)
        self.assertIn("size: 24", palette_source)
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
            "'kullanılabilir uçlar gösterilir'",
            board_source,
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

        self.assertIn("reservedCoreCells = <int>{5, 6, 9, 10}", models_source)
        self.assertIn("coreGateDirections", models_source)
        self.assertIn("_checkPlaceableCell", controller_source)
        self.assertIn("isCoreGate(targetCell)", controller_source)
        self.assertNotIn("çekirdeğe kilitli", editor_source)
        self.assertIn(
            "Jeneratör çekirdeğe dönük kalır",
            board_source,
        )
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
        self.assertIn("onNewGame: _newGame", replay_screen)
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
        self.assertIn("minimumSize: const Size(220, 40)", playback_controls)
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

    def test_editor_uses_contextual_translucent_notices(self) -> None:
        editor_source = (
            CLIENT / "lib" / "src" / "screens" / "editor_screen.dart"
        ).read_text(encoding="utf-8")
        widget_test = (
            CLIENT / "test" / "widget_test.dart"
        ).read_text(encoding="utf-8")

        self.assertIn("editor-context-notice", editor_source)
        self.assertIn("_EditorNoticeTone.success", editor_source)
        self.assertIn("_EditorNoticeTone.warning", editor_source)
        self.assertIn("_EditorNoticeTone.error", editor_source)
        self.assertIn("color.withValues(alpha: 0.10)", editor_source)
        self.assertNotIn("showSnackBar", editor_source)
        self.assertIn("await tester.ensureVisible(dismissButton)", widget_test)

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
        self.assertIn('"state_frames": match.result.get(', api_app)

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
        self.assertIn("guest-session-badge", editor_source)
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


if __name__ == "__main__":
    unittest.main()
