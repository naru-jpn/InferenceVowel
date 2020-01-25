# InferenceVowel
Demo Application for inference japanese vowel (/a/, /i/, /u/, /e/, /o/) with on-device machine learning using coreml3.

(Sampling rate written in code 44_000 depends on specific device (iPhone11 pro))

## Processing Flow

```
[AudioSampler]  (Input)
      |
[AudioAnalyzer] (Preprocess)
      |
[UpdatableKNN]  (Training/Inference)
```
