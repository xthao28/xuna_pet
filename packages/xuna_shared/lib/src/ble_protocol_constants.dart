/// Canonical XUNA BLE protocol v1 constants, GATT UUIDs, opcodes (1..13),
/// animations, and capability bit masks (shared from `device_protocol.dart`).
library;

/// XUNA BLE protocol v1 constants (`docs/roadmap/milestones/M02-ble.md` and
/// `MVP-local.md`).
abstract final class BleProtocolConstants {
  static const version = 1;

  // ---------------------------------------------------------------------------
  // Canonical BLE GATT UUIDs
  // ---------------------------------------------------------------------------

  static const uuidSuffix = '-8c44-4db6-9f61-2b7d5300a101';

  /// Formats a 16-bit XUNA characteristic/service part number into its full
  /// 128-bit GATT UUID (`7a6eXXXX-8c44-4db6-9f61-2b7d5300a101`).
  static String uuidForPart(int part) {
    if (part < 0 || part > 0xffff) {
      throw RangeError.range(part, 0, 0xffff, 'part');
    }
    return '7a6e${part.toRadixString(16).padLeft(4, '0')}$uuidSuffix';
  }

  static const servicePart = 0x0001;
  static const capabilitiesPart = 0x0002;
  static const commandPart = 0x0003;
  static const statusPart = 0x0004;
  static const lifePart = 0x0005;
  static const memoryPage0Part = 0x0006;
  static const memoryPage1Part = 0x0007;
  static const explanationPart = 0x000b;
  static const identityPart = 0x000c;
  static const proofPart = 0x000d;
  static const personalityPart = 0x000e;
  static const knowledgePart = 0x000f;
  static const speechPart = 0x0010;
  static const netConfigPart = 0x0011;
  static const netStatusPart = 0x0012;
  static const lifecyclePart = 0x0013;
  static const routinePart = 0x0014;
  static const hidHostsPart = 0x0015;
  static const memoryPageParts = <int>[memoryPage0Part, memoryPage1Part];

  static const serviceUuid = '7a6e0001-8c44-4db6-9f61-2b7d5300a101';
  static const capabilitiesUuid = '7a6e0002-8c44-4db6-9f61-2b7d5300a101';
  static const commandUuid = '7a6e0003-8c44-4db6-9f61-2b7d5300a101';
  static const statusUuid = '7a6e0004-8c44-4db6-9f61-2b7d5300a101';
  static const lifeUuid = '7a6e0005-8c44-4db6-9f61-2b7d5300a101';
  static const memoryPage0Uuid = '7a6e0006-8c44-4db6-9f61-2b7d5300a101';
  static const memoryPage1Uuid = '7a6e0007-8c44-4db6-9f61-2b7d5300a101';
  static const explanationUuid = '7a6e000b-8c44-4db6-9f61-2b7d5300a101';
  static const identityUuid = '7a6e000c-8c44-4db6-9f61-2b7d5300a101';
  static const proofUuid = '7a6e000d-8c44-4db6-9f61-2b7d5300a101';
  static const personalityUuid = '7a6e000e-8c44-4db6-9f61-2b7d5300a101';
  static const knowledgeUuid = '7a6e000f-8c44-4db6-9f61-2b7d5300a101';
  static const speechUuid = '7a6e0010-8c44-4db6-9f61-2b7d5300a101';
  static const netConfigUuid = '7a6e0011-8c44-4db6-9f61-2b7d5300a101';
  static const netStatusUuid = '7a6e0012-8c44-4db6-9f61-2b7d5300a101';
  static const lifecycleUuid = '7a6e0013-8c44-4db6-9f61-2b7d5300a101';
  static const routineUuid = '7a6e0014-8c44-4db6-9f61-2b7d5300a101';
  static const hidHostsUuid = '7a6e0015-8c44-4db6-9f61-2b7d5300a101';

  // ---------------------------------------------------------------------------
  // Command Opcodes (1..13) & Sub-opcodes
  // ---------------------------------------------------------------------------

  static const opcodeAnimation = 1;
  static const opcodeSuggest = 2;
  static const opcodeFeedback = 3;
  static const opcodeForget = 4;
  static const opcodeTimeSync = 5;
  static const opcodeStatedPreference = 6;
  static const opcodeHatch = 7;

  /// Personality PE-4c: one closed conversation tag (argument 1–6).
  static const opcodeConversationSignal = 8;

  /// Personality PE-4d: 1 undo the newest change, 2 reset.
  static const opcodePersonalityControl = 9;
  static const personalityUndoLatest = 1;
  static const personalityReset = 2;

  /// Knowledge domains (opcode 10, KD-2).
  static const opcodeKnowledge = 10;
  static const knowledgeSubOpOpen = 1;
  static const knowledgeSubOpSetActive = 2;
  static const knowledgeSubOpSetResting = 3;
  static const knowledgeSubOpClear = 4;
  static const knowledgeSubOpAddEvidence = 5;
  static const knowledgeSubOpRemoveEvidence = 6;
  static const knowledgeSubOpMoveEvidence = 7;

  /// Display settings (opcode 11, Power Phase 2: brightness 0..2, screenSleep 0..1).
  static const opcodeDisplaySettings = 11;
  static const brightnessLow = 0;
  static const brightnessMedium = 1;
  static const brightnessHigh = 2;

  /// HID Consumer media key (opcode 12, UDC-2).
  static const opcodeHidConsumer = 12;
  static const hidSourceAppButton = 1;
  static const hidSourceBrainApproved = 2;

  /// HID host bond management (opcode 13, UDC-2 / UDC-9).
  static const opcodeHidHosts = 13;
  static const hidHostsForgetSlot = 1;
  static const hidHostsForgetAll = 2;
  static const hidHostsOpenPairingWindow = 3;
  static const hidHostsSetRemoteLayout = 4;
  static const remoteLayoutMedia = 0;
  static const remoteLayoutWorkflows = 1;
  static const hidHostsMaxSlots = 4;
  static const hidHostsNoSlot = 0xff;
  static const hidHostsUnknownDays = 0xff;

  // ---------------------------------------------------------------------------
  // Status & Result Codes
  // ---------------------------------------------------------------------------

  static const statusSnapshot = 0;
  static const statusResult = 1;
  static const statusStateChange = 2;
  static const statusRemoteEvent = 3;

  static const remoteEventStop = 1;
  static const remoteEventWorkflowSlot1 = 2;
  static const remoteEventWorkflowSlot2 = 3;

  static const resultOk = 0;
  static const resultUnsupportedVersion = 1;
  static const resultInvalidLength = 2;
  static const resultUnsupportedOpcode = 3;
  static const resultInvalidArgument = 4;
  static const resultBusy = 5;
  static const resultRequestIdConflict = 6;
  static const resultNotReady = 7;
  static const resultExpired = 8;

  // ---------------------------------------------------------------------------
  // Animations, Variants, Signals, Contexts & Sources
  // ---------------------------------------------------------------------------

  static const animationIdle = 0;
  static const animationHappy = 1;
  static const animationSleep = 2;
  static const animationCurious = 3;

  /// Track A variant preview (opcode 1 arguments 4–7): the board only plays
  /// the animation; nothing in XUNA's life changes.
  static const variantLookAround = 4;
  static const variantYawnStretch = 5;
  static const variantBouncePlay = 6;
  static const variantGreetNuzzle = 7;

  /// Conversation signal tags, firmware `ConversationTag` wire order.
  static const signalPraise = 1;
  static const signalScold = 2;
  static const signalAffection = 3;
  static const signalPlayful = 4;
  static const signalCuriousQuestion = 5;
  static const signalLongChat = 6;

  static const contextQuiet = 0;
  static const contextPlay = 1;

  /// GPIO0 greeting: only in memory pages, never in the life value.
  static const contextGreeting = 2;

  static const sourceNone = 0;
  static const sourceButton = 1;
  static const sourceText = 2;

  /// Owner reaction on the device (pet / shoo), D6 revised 2026-10-19.
  static const sourceReaction = 3;
  static const sourcePhone = 1;

  // ---------------------------------------------------------------------------
  // Lifecycle & Identity States
  // ---------------------------------------------------------------------------

  static const identityStateEgg = 0;
  static const identityStateReady = 1;
  static const identityStateSafe = 2;

  static const growthStageEgg = 0;
  static const growthStageNewborn = 1;

  static const clockQualityUnknown = 0;
  static const clockQualityApproximate = 1;
  static const clockQualitySynced = 2;

  static const originNone = 0;
  static const originHatchedOnDevice = 1;
  static const originHatchedViaApp = 2;
  static const originMigratedFromV1 = 3;

  // ---------------------------------------------------------------------------
  // Capability Bit Masks
  // ---------------------------------------------------------------------------

  static const capabilityTimeSync = 1 << 4;
  static const capabilityStatedPreference = 1 << 5;
  static const capabilityHatch = 1 << 6;
  static const capabilityIdentity = 1 << 7;

  /// Capability byte 3: Identity V2 device proof (characteristic 7a6e000d).
  static const capabilityDeviceProof = 1 << 0;

  /// Capability byte 3: personality projection (characteristic 7a6e000e).
  static const capabilityPersonality = 1 << 1;

  /// Capability byte 3: conversation signal (opcode 8, PE-4c).
  static const capabilityConversationSignal = 1 << 2;

  /// Capability byte 3: personality control (opcode 9, PE-4d).
  static const capabilityPersonalityControl = 1 << 3;

  /// Capability byte 3: knowledge domains (opcode 10, KD-2).
  static const capabilityKnowledge = 1 << 4;

  /// Capability byte 3: speech subtitles (`7a6e0010`, owner 2026-10-27).
  static const capabilitySpeechText = 1 << 5;

  /// Capability byte 3: Wi-Fi setup `7a6e0011` and network projection
  /// `7a6e0012` (device-direct DC-2; firmware built with `XUNA_NET`).
  static const capabilityNetworkSetup = 1 << 6;

  /// Capability byte 3: display brightness & screen sleep (opcode 11, Power Phase 2).
  static const capabilityDisplaySettings = 1 << 7;

  /// Capability byte 4 (animation mask) bits 4–7: the four variant previews.
  static const capabilityVariantPreview = 0xf0;

  /// Capability byte 5 (flags mask) bit 2: Routine V1 projection (`7a6e0014`).
  static const capabilityRoutine = 1 << 2;

  /// Capability byte 5 bit 3: BLE HID service (`0x1812`, UDC-1).
  static const capabilityHid = 1 << 3;

  /// Capability byte 5 bit 4: HID control opcodes 12–13 & `7a6e0015` (UDC-2).
  static const capabilityHidControl = 1 << 4;

  /// Capability byte 5 bit 5: custom characteristics require authenticated link (UDC-2).
  static const capabilityAuthenticatedChannel = 1 << 5;

  /// Capability byte 5 bit 6: Remote mode events on status `7a6e0004` (`kind = 3`, UDC-7 S7.3).
  static const capabilityRemoteEvents = 1 << 6;

  // ---------------------------------------------------------------------------
  // Device Proof & Limits
  // ---------------------------------------------------------------------------

  static const proofPurposeBind = 1;
  static const proofStatusIdle = 0;
  static const proofStatusPending = 1;
  static const proofStatusOk = 2;
  static const proofStatusInvalidRequest = 3;
  static const proofStatusUnsupportedPurpose = 4;
  static const proofStatusNotReady = 5;
  static const proofStatusFailed = 6;

  static const maxRequestId = 0xffffffff;
  static const maxMemoryEpisodes = 8;
}
