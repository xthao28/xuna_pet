import 'package:test/test.dart';
import 'package:xuna_shared/xuna_shared.dart';

void main() {
  group('SharedRiskTier', () {
    test('wire representations and levels match ADR-0012', () {
      expect(SharedRiskTier.r0.xtpWire, 'R0');
      expect(SharedRiskTier.r0.lowerWire, 'r0');
      expect(SharedRiskTier.r0.wire, 'R0');
      expect(SharedRiskTier.r0.level, 0);
      expect(SharedRiskTier.r0.rank, 0);

      expect(SharedRiskTier.r1.xtpWire, 'R1');
      expect(SharedRiskTier.r1.lowerWire, 'r1');
      expect(SharedRiskTier.r1.level, 1);

      expect(SharedRiskTier.r2.xtpWire, 'R2');
      expect(SharedRiskTier.r2.lowerWire, 'r2');
      expect(SharedRiskTier.r2.level, 2);

      expect(SharedRiskTier.r3.xtpWire, 'R3');
      expect(SharedRiskTier.r3.lowerWire, 'r3');
      expect(SharedRiskTier.r3.level, 3);

      expect(SharedRiskTier.r4.xtpWire, 'R4');
      expect(SharedRiskTier.r4.lowerWire, 'r4');
      expect(SharedRiskTier.r4.level, 4);
    });

    test('relational operators and compareTo work accurately', () {
      expect(SharedRiskTier.r0 < SharedRiskTier.r1, isTrue);
      expect(SharedRiskTier.r1 <= SharedRiskTier.r1, isTrue);
      expect(SharedRiskTier.r3 > SharedRiskTier.r2, isTrue);
      expect(SharedRiskTier.r4 >= SharedRiskTier.r3, isTrue);
      expect(SharedRiskTier.r2.compareTo(SharedRiskTier.r2), 0);
    });

    test('tier classification flags', () {
      expect(SharedRiskTier.r0.isActionTier, isFalse);
      expect(SharedRiskTier.r1.isActionTier, isTrue);
      expect(SharedRiskTier.r2.isActionTier, isTrue);
      expect(SharedRiskTier.r3.isActionTier, isTrue);
      expect(SharedRiskTier.r4.isActionTier, isFalse);

      expect(SharedRiskTier.r0.isHostGrantTier, isTrue);
      expect(SharedRiskTier.r3.isHostGrantTier, isTrue);
      expect(SharedRiskTier.r4.isHostGrantTier, isFalse);

      expect(SharedRiskTier.r3.isForbiddenInMvp, isFalse);
      expect(SharedRiskTier.r4.isForbiddenInMvp, isTrue);
    });

    test('fromXtpWire and fromWire parse valid strings and throw on invalid', () {
      for (final tier in SharedRiskTier.values) {
        expect(SharedRiskTier.fromXtpWire(tier.xtpWire), tier);
        expect(SharedRiskTier.fromWire(tier.xtpWire), tier);
        expect(SharedRiskTier.fromWire(tier.lowerWire), tier);
      }
      expect(() => SharedRiskTier.fromXtpWire('r1'), throwsFormatException);
      expect(() => SharedRiskTier.fromWire('R5'), throwsFormatException);
    });

    test('parseHostGrantTier and parseActionTier map mobile tiers safely', () {
      expect(SharedRiskTier.parseHostGrantTier('R0'), SharedRiskTier.r0);
      expect(SharedRiskTier.parseHostGrantTier('r3'), SharedRiskTier.r3);
      expect(SharedRiskTier.parseHostGrantTier('R4'), SharedRiskTier.r1);
      expect(SharedRiskTier.parseHostGrantTier(null), SharedRiskTier.r1);

      expect(SharedRiskTier.parseActionTier('R0'), SharedRiskTier.r1);
      expect(SharedRiskTier.parseActionTier('r1'), SharedRiskTier.r1);
      expect(SharedRiskTier.parseActionTier('R2'), SharedRiskTier.r2);
      expect(SharedRiskTier.parseActionTier('r3'), SharedRiskTier.r3);
      expect(SharedRiskTier.parseActionTier('R4'), SharedRiskTier.r2);
      expect(SharedRiskTier.parseActionTier('unknown'), SharedRiskTier.r2);
    });
  });

  group('SharedHostPlatform', () {
    test('wire serialization and round-trip parsing', () {
      for (final platform in SharedHostPlatform.values) {
        expect(SharedHostPlatform.fromWire(platform.wire), platform);
        expect(
          SharedHostPlatform.tryParse(platform.wire.toUpperCase()),
          platform,
        );
      }
      expect(
        () => SharedHostPlatform.fromWire('freebsd'),
        throwsFormatException,
      );
      expect(SharedHostPlatform.tryParse('freebsd'), isNull);
      expect(SharedHostPlatform.tryParse(null), isNull);
    });

    test('desktop vs mobile classification', () {
      expect(SharedHostPlatform.windows.isDesktop, isTrue);
      expect(SharedHostPlatform.macos.isDesktop, isTrue);
      expect(SharedHostPlatform.linux.isDesktop, isTrue);
      expect(SharedHostPlatform.android.isDesktop, isFalse);
      expect(SharedHostPlatform.ios.isDesktop, isFalse);

      expect(SharedHostPlatform.android.isMobile, isTrue);
      expect(SharedHostPlatform.ios.isMobile, isTrue);
      expect(SharedHostPlatform.windows.isMobile, isFalse);
    });
  });

  group('BleProtocolConstants', () {
    test('GATT UUIDs match uuidForPart', () {
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.servicePart),
        BleProtocolConstants.serviceUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.capabilitiesPart),
        BleProtocolConstants.capabilitiesUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.commandPart),
        BleProtocolConstants.commandUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.statusPart),
        BleProtocolConstants.statusUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.lifePart),
        BleProtocolConstants.lifeUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.memoryPage0Part),
        BleProtocolConstants.memoryPage0Uuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.memoryPage1Part),
        BleProtocolConstants.memoryPage1Uuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.explanationPart),
        BleProtocolConstants.explanationUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.identityPart),
        BleProtocolConstants.identityUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.proofPart),
        BleProtocolConstants.proofUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.personalityPart),
        BleProtocolConstants.personalityUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.knowledgePart),
        BleProtocolConstants.knowledgeUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.speechPart),
        BleProtocolConstants.speechUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.netConfigPart),
        BleProtocolConstants.netConfigUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.netStatusPart),
        BleProtocolConstants.netStatusUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.lifecyclePart),
        BleProtocolConstants.lifecycleUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.routinePart),
        BleProtocolConstants.routineUuid,
      );
      expect(
        BleProtocolConstants.uuidForPart(BleProtocolConstants.hidHostsPart),
        BleProtocolConstants.hidHostsUuid,
      );
      expect(
        () => BleProtocolConstants.uuidForPart(-1),
        throwsRangeError,
      );
      expect(
        () => BleProtocolConstants.uuidForPart(0x10000),
        throwsRangeError,
      );
    });

    test('opcodes 1..13 and capability bit masks match protocol v1', () {
      expect(BleProtocolConstants.version, 1);
      expect(BleProtocolConstants.opcodeAnimation, 1);
      expect(BleProtocolConstants.opcodeSuggest, 2);
      expect(BleProtocolConstants.opcodeFeedback, 3);
      expect(BleProtocolConstants.opcodeForget, 4);
      expect(BleProtocolConstants.opcodeTimeSync, 5);
      expect(BleProtocolConstants.opcodeStatedPreference, 6);
      expect(BleProtocolConstants.opcodeHatch, 7);
      expect(BleProtocolConstants.opcodeConversationSignal, 8);
      expect(BleProtocolConstants.opcodePersonalityControl, 9);
      expect(BleProtocolConstants.opcodeKnowledge, 10);
      expect(BleProtocolConstants.opcodeDisplaySettings, 11);
      expect(BleProtocolConstants.opcodeHidConsumer, 12);
      expect(BleProtocolConstants.opcodeHidHosts, 13);

      expect(BleProtocolConstants.capabilityTimeSync, 1 << 4);
      expect(BleProtocolConstants.capabilityStatedPreference, 1 << 5);
      expect(BleProtocolConstants.capabilityHatch, 1 << 6);
      expect(BleProtocolConstants.capabilityIdentity, 1 << 7);
      expect(BleProtocolConstants.capabilityDeviceProof, 1 << 0);
      expect(BleProtocolConstants.capabilityPersonality, 1 << 1);
      expect(BleProtocolConstants.capabilityConversationSignal, 1 << 2);
      expect(BleProtocolConstants.capabilityPersonalityControl, 1 << 3);
      expect(BleProtocolConstants.capabilityKnowledge, 1 << 4);
      expect(BleProtocolConstants.capabilitySpeechText, 1 << 5);
      expect(BleProtocolConstants.capabilityNetworkSetup, 1 << 6);
      expect(BleProtocolConstants.capabilityDisplaySettings, 1 << 7);
      expect(BleProtocolConstants.capabilityVariantPreview, 0xf0);
      expect(BleProtocolConstants.capabilityRoutine, 1 << 2);
      expect(BleProtocolConstants.capabilityHid, 1 << 3);
      expect(BleProtocolConstants.capabilityHidControl, 1 << 4);
      expect(BleProtocolConstants.capabilityAuthenticatedChannel, 1 << 5);
      expect(BleProtocolConstants.capabilityRemoteEvents, 1 << 6);
    });
  });
}
