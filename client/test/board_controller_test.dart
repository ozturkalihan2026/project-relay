import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_relay_client/src/models/relay_models.dart';
import 'package:project_relay_client/src/state/board_controller.dart';

void main() {
  group('BoardController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('başlangıç devresi bağlı jeneratör ve lazer içerir', () {
      final state = container.read(boardControllerProvider);

      expect(state.placements.length, 2);
      expect(state.placements[1]?.kind, ModuleKind.generator);
      expect(state.placements[1]?.orientation, RelayDirection.south);
      expect(state.placements[2]?.kind, ModuleKind.laser);
      expect(state.board.toJson()['name'], 'Mavi Devre');
    });

    test('paletten seçilen modülü boş hücreye yerleştirir', () {
      final controller = container.read(boardControllerProvider.notifier);

      controller
        ..selectPalette(ModuleKind.cooler)
        ..tapCell(12);
      final placed = container.read(boardControllerProvider).placements[12];

      expect(placed?.kind, ModuleKind.cooler);
      expect(placed?.row, 3);
      expect(placed?.column, 0);
      expect(placed?.orientation, RelayDirection.east);
    });

    test('sürükle bırak modülü doğrudan boş hücreye yerleştirir', () {
      final controller = container.read(boardControllerProvider.notifier);

      controller.dropModule(
        7,
        const ModuleDragData.palette(ModuleKind.battery),
      );
      final state = container.read(boardControllerProvider);
      final placed = state.placements[7];

      expect(placed?.kind, ModuleKind.battery);
      expect(placed?.row, 1);
      expect(placed?.column, 3);
      expect(state.selectedCell, 7);
      expect(state.selectedKind, isNull);
    });

    test('paletten dolu hücreye bırakınca eski modülü değiştirir', () {
      final controller = container.read(boardControllerProvider.notifier);

      controller.dropModule(
        2,
        const ModuleDragData.palette(ModuleKind.shield),
      );
      final state = container.read(boardControllerProvider);

      expect(state.placements.length, 2);
      expect(state.placements[2]?.kind, ModuleKind.shield);
      expect(state.placements[2]?.id, 'P-shield-02');
      expect(state.selectedCell, 2);
    });

    test('kart modülünü boş hücreye taşır ve kimliğini korur', () {
      final controller = container.read(boardControllerProvider.notifier);
      final source = container.read(boardControllerProvider).placements[2]!;

      controller.dropModule(
        3,
        const ModuleDragData.board(
          kind: ModuleKind.laser,
          cellIndex: 2,
        ),
      );
      final state = container.read(boardControllerProvider);

      expect(state.placements[2], isNull);
      expect(state.placements[3]?.id, source.id);
      expect(state.placements[3]?.row, 0);
      expect(state.placements[3]?.column, 3);
      expect(state.selectedCell, 3);
    });

    test('kart modülünü dolu hücreye bırakınca iki modül yer değiştirir', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller.dropModule(
        7,
        const ModuleDragData.palette(ModuleKind.battery),
      );
      final laser = container.read(boardControllerProvider).placements[2]!;
      final battery = container.read(boardControllerProvider).placements[7]!;

      controller.dropModule(
        7,
        const ModuleDragData.board(
          kind: ModuleKind.laser,
          cellIndex: 2,
        ),
      );
      final state = container.read(boardControllerProvider);

      expect(state.placements[7]?.id, laser.id);
      expect(state.placements[7]?.row, 1);
      expect(state.placements[7]?.column, 3);
      expect(state.placements[2]?.id, battery.id);
      expect(state.placements[2]?.row, 0);
      expect(state.placements[2]?.column, 2);
      expect(state.selectedCell, 7);
    });

    test('kart modülünü palete geri bırakınca karttan kaldırır', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller.applyValidation(
        const BoardValidation(
          valid: true,
          poweredIds: {'P-GEN', 'P-LASER'},
          unpoweredIds: {},
        ),
      );

      controller.removeModuleAt(2);
      final state = container.read(boardControllerProvider);

      expect(state.placements[2], isNull);
      expect(state.placements.length, 1);
      expect(state.selectedCell, isNull);
      expect(state.validation, isNull);
    });

    test('taşınan modül varken yeni palet modülüne benzersiz kimlik verir', () {
      final controller = container.read(boardControllerProvider.notifier);

      controller
        ..dropModule(
          12,
          const ModuleDragData.palette(ModuleKind.shield),
        )
        ..moveModule(12, 13)
        ..dropModule(
          12,
          const ModuleDragData.palette(ModuleKind.shield),
        );
      final state = container.read(boardControllerProvider);

      expect(state.placements[13]?.id, 'P-shield-12');
      expect(state.placements[12]?.id, 'P-shield-12-2');
      expect(
        state.placements.values.map((module) => module.id).toSet().length,
        state.placements.length,
      );
    });

    test('palet değişimi ikinci jeneratör kuralını korur', () {
      final controller = container.read(boardControllerProvider.notifier);

      expect(
        () => controller.dropModule(
          7,
          const ModuleDragData.palette(ModuleKind.generator),
        ),
        throwsStateError,
      );
      expect(
        container.read(boardControllerProvider).placements[7],
        isNull,
      );
    });

    test('kart değişince yer değiştirme eski doğrulamayı temizler', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller.applyValidation(
        const BoardValidation(
          valid: true,
          poweredIds: {'P-GEN', 'P-LASER'},
          unpoweredIds: {},
        ),
      );

      controller.moveModule(2, 3);

      expect(container.read(boardControllerProvider).validation, isNull);
    });

    test('tek portlu modül yerleşirken bağlantıya otomatik yönlenir', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller.dropModule(
        3,
        const ModuleDragData.palette(ModuleKind.cooler),
      );

      // Hücre 3'ün batısında lazer vardır; arka port otomatik batıya bakar.
      expect(
        container.read(boardControllerProvider).placements[3]?.orientation,
        RelayDirection.east,
      );
    });

    test('yalnız güçlendirici etki yönü elle döndürülür', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller.dropModule(
        3,
        const ModuleDragData.palette(ModuleKind.amplifier),
      );
      final before = container.read(boardControllerProvider).placements[3]!.orientation;
      controller.rotateAt(3);
      expect(
        container.read(boardControllerProvider).placements[3]?.orientation,
        before.next,
      );
    });

    test('ikinci jeneratörü yerleştirmeyi reddeder', () {
      final controller = container.read(boardControllerProvider.notifier);

      controller.selectPalette(ModuleKind.generator);

      expect(() => controller.tapCell(7), throwsStateError);
      expect(container.read(boardControllerProvider).placements.length, 2);
    });

    test('çekirdeğin dört hücresine modül yerleştirmeyi reddeder', () {
      final controller = container.read(boardControllerProvider.notifier);

      for (final cell in reservedCoreCells) {
        expect(
          () => controller.dropModule(
            cell,
            const ModuleDragData.palette(ModuleKind.battery),
          ),
          throwsStateError,
        );
      }
      expect(container.read(boardControllerProvider).placements.length, 2);
    });

    test('jeneratörü yalnız kapıya taşır ve otomatik çekirdeğe döndürür', () {
      final controller = container.read(boardControllerProvider.notifier);

      expect(() => controller.moveModule(1, 0), throwsStateError);
      controller.moveModule(1, 7);
      final generator =
          container.read(boardControllerProvider).placements[7]!;

      expect(generator.kind, ModuleKind.generator);
      expect(generator.orientation, RelayDirection.west);
    });

    test('paletten gelen jeneratörü kapıda içe dönük yerleştirir', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller
        ..removeModuleAt(1)
        ..dropModule(
          14,
          const ModuleDragData.palette(ModuleKind.generator),
        );

      final generator =
          container.read(boardControllerProvider).placements[14]!;
      expect(generator.orientation, RelayDirection.north);
    });

    test('kapı jeneratörünün sabit yönünü döndürmez', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller
        ..moveModule(1, 8)
        ..rotateSelected();

      expect(
        container
            .read(boardControllerProvider)
            .placements[8]
            ?.orientation,
        RelayDirection.east,
      );
    });

    test('dört yönlü Bataryayı gereksiz yere döndürmez', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller.dropModule(
        7,
        const ModuleDragData.palette(ModuleKind.battery),
      );
      final before =
          container.read(boardControllerProvider).placements[7]!.orientation;

      controller.rotateAt(7);

      expect(
        container.read(boardControllerProvider).placements[7]?.orientation,
        before,
      );
    });

    test('altı modül sınırını korur ve dolu hücre değişimine izin verir', () {
      final controller = container.read(boardControllerProvider.notifier);
      for (final cell in [0, 3, 4]) {
        controller.dropModule(
          cell,
          const ModuleDragData.palette(ModuleKind.battery),
        );
      }
      controller.dropModule(
        7,
        const ModuleDragData.palette(ModuleKind.cooler),
      );

      expect(container.read(boardControllerProvider).placements.length, 6);
      expect(
        () => controller.dropModule(
          8,
          const ModuleDragData.palette(ModuleKind.shield),
        ),
        throwsStateError,
      );

      controller.dropModule(
        0,
        const ModuleDragData.palette(ModuleKind.shield),
      );
      final state = container.read(boardControllerProvider);
      expect(state.placements.length, 6);
      expect(state.placements[0]?.kind, ModuleKind.shield);
    });

    test('başlangıç sekizlisi kaydedilince palet sınırları anında değişir', () {
      final controller = container.read(trainingBoardControllerProvider.notifier);
      controller.applyKit(
        ControlledKit(
          name: 'Antrenman Savunması',
          moduleKinds: const [
            ModuleKind.generator,
            ModuleKind.shield,
            ModuleKind.shield,
            ModuleKind.cooler,
            ModuleKind.cooler,
            ModuleKind.repair,
            ModuleKind.battery,
            ModuleKind.amplifier,
          ],
          updatedAt: DateTime.utc(2026, 8, 6),
        ),
      );

      final state = container.read(trainingBoardControllerProvider);
      expect(state.kitName, 'Antrenman Savunması');
      expect(state.kitLimits[ModuleKind.shield], 2);
      expect(state.kitLimits[ModuleKind.laser], isNull);
      expect(state.remainingFor(ModuleKind.shield), 2);
      expect(state.remainingFor(ModuleKind.laser), 0);
    });

    test('çevrimiçi antrenman ve kariyer devre durumları ayrıdır', () {
      final online = container.read(onlineBoardControllerProvider.notifier);
      final training = container.read(trainingBoardControllerProvider.notifier);
      final career = container.read(careerBoardControllerProvider.notifier);

      online.dropModule(7, const ModuleDragData.palette(ModuleKind.battery));
      training.dropModule(8, const ModuleDragData.palette(ModuleKind.cooler));
      career.dropModule(12, const ModuleDragData.palette(ModuleKind.shield));

      expect(container.read(onlineBoardControllerProvider).placements[7]?.kind, ModuleKind.battery);
      expect(container.read(onlineBoardControllerProvider).placements[8], isNull);
      expect(container.read(onlineBoardControllerProvider).placements[12], isNull);

      expect(container.read(trainingBoardControllerProvider).placements[8]?.kind, ModuleKind.cooler);
      expect(container.read(trainingBoardControllerProvider).placements[7], isNull);
      expect(container.read(trainingBoardControllerProvider).placements[12], isNull);

      expect(container.read(careerBoardControllerProvider).placements[12]?.kind, ModuleKind.shield);
      expect(container.read(careerBoardControllerProvider).placements[7], isNull);
      expect(container.read(careerBoardControllerProvider).placements[8], isNull);
    });

    test('kart değişince eski sunucu doğrulamasını temizler', () {
      final controller = container.read(boardControllerProvider.notifier);
      controller.applyValidation(
        const BoardValidation(
          valid: true,
          poweredIds: {'P-GEN', 'P-LASER'},
          unpoweredIds: {},
        ),
      );

      controller.rotateSelected();

      expect(container.read(boardControllerProvider).validation, isNull);
    });
  });
}
