# On-device sentence voice

Bundled in `assets/tts/kitten_nano_v0_8/` and run by `KittenSpeechEngine`.

- **KittenTTS nano v0.8 (int8)**, KittenML, Apache License 2.0 (`LICENSE` in the
  model folder). https://github.com/KittenML/KittenTTS
  Converted package from sherpa-onnx, downloaded 2026-10-08:
  https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kitten-nano-en-v0_8-int8.tar.bz2
  (archive SHA-256 `6fa5be852612ce761094ba74ee6123b4fc4acfefa79bf64dc63acae4a83af2fd`).
  `model.int8.onnx`, `voices.bin` and `tokens.txt` are unchanged.
- **sherpa-onnx 1.13.8** runtime (pub.dev `sherpa_onnx`), Apache License 2.0.
- **espeak-ng data**, GPL-3.0-or-later. https://github.com/espeak-ng/espeak-ng
  Only the English files are kept: `en_dict`, phoneme tables, `intonations` and
  `lang/gmw/en*`. Other languages, voice variants and `phondata-manifest` were
  removed; on a desktop check the output was sample-identical to the full data.
  sherpa-onnx's native library also includes espeak-ng for phonemization.
  Review GPL obligations before distributing the app.

Voice row 0 of 8 is used (`KittenSpeechEngine.voice`). Normal speed is 1.0 and
slow replay is synthesized at 0.7. Audio is generated on the phone at runtime;
no recordings are bundled. If the engine cannot start, the phone's system
text-to-speech (`flutter_tts`) is used instead.
