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

## Reference
- guide-mel-frequency-cepstral-coefficients-mfccs
  - [http://practicalcryptography.com/miscellaneous/machine-learning/guide-mel-frequency-cepstral-coefficients-mfccs/#computing-the-mel-filterbank](http://practicalcryptography.com/miscellaneous/machine-learning/guide-mel-frequency-cepstral-coefficients-mfccs/#computing-the-mel-filterbank)
- Updatable Nearest Neighbor Classifier
  - [https://github.com/apple/coremltools/blob/master/examples/updatable_models/updatable_nearest_neighbor_classifier.ipynb](https://github.com/apple/coremltools/blob/master/examples/updatable_models/updatable_nearest_neighbor_classifier.ipynb)
