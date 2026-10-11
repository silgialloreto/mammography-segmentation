# Mammography Segmentation – Mass segmentation in mammograms

Project for the **Image Processing** course (*Elaborazione di Immagini*, A.Y. 2024/2025)  
Authors: Silvia Gialloreto, Valerio Luzi

This project segments masses (benign and malignant) in mammograms from the **mini-MIAS** dataset and compares two approaches:

1. **Region Growing**: a region-based algorithm driven by a manually chosen seed, with contrast-enhancement pre-processing;
2. **Convolutional neural network**: **DeepLabv3+** with a **ResNet-50** backbone, trained for 2-class semantic segmentation (`N` background, `B` mass).

Shape features (circularity, eccentricity, solidity, extent, border CV) are then extracted from the segmented masses to tell benign masses from malignant ones.

---

## Repository structure

```
mammography-segmentation/
├── scripts/
│   ├── divisione_train_test.m      # STEP 1 – patient-wise training/test split, contrast, PNG export
│   ├── alg.reg growing.m           # Region growing on TRAINING images + metric plots
│   ├── reg growing TEST.m          # Region growing on TEST images, post-processing, shape features
│   ├── my_regiongrowing.m          # region growing function (D. Kroon, Univ. Twente – modified)
│   ├── evaluation_segmentation.m   # function: TP, FP, FN, Correctness, Completeness, F-measure
│   ├── RETE NEURALE 2.0.m          # mask normalisation, DeepLabv3+ construction and training (net_2A)
│   ├── continuo_addestr_net2.m     # fine-tuning of net_2A -> net_2B (parallel pool)
│   ├── Codice_RETE_COMPLETO.m      # network testing, best/worst cases, boxplots and violin plots
│   ├── rete neurale.asv            # autosave of an earlier version (image cropping)
│   └── pazienti/                   # region growing scripts with the parameters tuned for each patient
├── data/
│   ├── Augmented/
│   │   ├── Image_noisy/            # 820 images from the provided (augmented) dataset, .pgm
│   │   └── GT/                     # 820 binary ground-truth masks (.pgm)
│   ├── im_train2/  gt_train2/      # training set: 600 images/GT (30 cases × 20) as PNG, contrast-enhanced
│   ├── im_test2/   gt_test2/       # test set: 220 images/GT (11 cases × 20) as PNG
│   ├── gt_normalizzato_RETE/       # training GT normalised to {0,1} for pixelLabelDatastore
│   └── label.xlsx                  # mini-MIAS annotations (tissue, class, severity B/M, centre and radius)
├── models/                         # trained networks rete_addestrata*.mat (~147 MB each, NOT versioned)
└── docs/
    ├── ImpostazioneProgetto.pptx   # project brief (steps required by the instructor)
    └── progetto EI presentazione.pptx  # final presentation with results
```

### Dataset

Images follow the mini-MIAS naming `mdbXXX_YYY_Z` (GT: `mdbXXX_GT_YYY_Z`), where `mdbXXX` is the case number.
The training/test split is done **by case, not by image**: the same patient never appears in both sets.

| Set | Cases | Images |
|---|---|---|
| Training | 30 (mdb001 … mdb202) | 600 |
| Test | 11 (mdb206 … mdb315) | 220 |

For each case, `label.xlsx` gives the tissue type (F/G/D), the abnormality class (CIRC, SPIC, MISC, ARCH, ASYM, NORM), the severity (**B** benign / **M** malignant) and the x, y coordinates and radius of the mass.

---

## Requirements

- MATLAB (R2024b)
- Image Processing Toolbox
- Deep Learning Toolbox, Computer Vision Toolbox (`deeplabv3plusLayers`, `semanticseg`, `pixelLabelDatastore`)
- Deep Learning Toolbox Model for ResNet-50 Network
- Parallel Computing Toolbox (only for `continuo_addestr_net2.m`)

---

## Usage

Open MATLAB in `scripts/`, so that `my_regiongrowing.m` and `evaluation_segmentation.m` are found, and run the scripts section by section.

> **Paths:** the network scripts and `divisione_train_test.m` use absolute paths such as
> `C:\Users\silgi\Desktop\progetto EI (no OneDrive)\matlab EI PROGETTO\...`. To run them, update these paths to point to the folders in `data/` (and to the network `.mat` files in `models/`).

### 1. Training/test split – `divisione_train_test.m`
Select the `Augmented/Image_noisy` and `Augmented/GT` folders. The first 600 images (30 cases) go to training and the remaining 220 (11 cases) to test. `imadjust` is applied to the images, then everything is saved as PNG (never JPEG, which would corrupt the binary GT).

### 2. Region Growing – `alg.reg growing.m`, `reg growing TEST.m`
1. Select an image and its GT (`uigetfile`).
2. Enhance the contrast with `imadjust`.
3. Pick the seed with `drawpoint()`. `my_regiongrowing` grows the region while the intensity difference from the region mean stays below the threshold.
4. Fill the holes (`imfill`) and evaluate the result with `evaluation_segmentation`.

The threshold is tuned separately for each training image (see `scripts/pazienti/`). On the test set the **mean of the training thresholds, 0.34**, is used.

### 3. Neural network – `RETE NEURALE 2.0.m`, `continuo_addestr_net2.m`
- Masks are converted from {0,255} to {0,1} (`gt_normalizzato_RETE/`).
- `pixelLabelImageDatastore` at 256×256×3 (gray→RGB conversion).
- `deeplabv3plusLayers(..., "resnet50")` with **class weights inversely proportional to pixel frequency**, to compensate for the background/mass imbalance.
- Adam training: lr 5e-4, 20 epochs, batch 4, lr halved every 10 epochs → `net_2A`.
- Fine-tuning: lr 1e-5, 10 epochs, batch 16 → `net_2B`.

### 4. Testing and analysis – `Codice_RETE_COMPLETO.m`
Segmentation with `semanticseg`, followed by post-processing (`imfill`, closing with a disk of radius 3, `bwareafilt` to keep the main component). The script computes the metrics on test and training, finds the 3 best and 3 worst cases (from different patients) and draws boxplots and violin plots.

### 5. Shape features – final sections of `reg growing TEST.m`
Morphological closing (4×4 square) and `regionprops`, from which **Extent**, **Solidity**, **Eccentricity**, **Circularity** and the **ribbon CV** (mass border) are derived. The values are compared between benign and malignant masses with scatter plots and boxplots.

---

## Metrics

Computed by `evaluation_segmentation(BW, GT)`:

| Metric | Formula | Meaning |
|---|---|---|
| Correctness (CR) | TP / (TP + FP) | = 1 when there is no over-segmentation |
| Completeness (CM) | TP / (TP + FN) | = 1 when there is no under-segmentation |
| F-measure (FM) | 2·CR·CM / (CR + CM) | harmonic mean |

## Conclusions

**Region growing** proved to be the more effective segmentation method, thanks to the pre-processing and the manual seed selection. However, it is not precise enough to tell benign from malignant masses, because it approximates the shape of the mass instead of following its borders in detail. The ribbon CV, in particular, turned out not to be discriminative.

Details, images and plots in `docs/progetto EI presentazione.pptx`.

---

> **Note on the models:** the files in `models/` (`rete_addestrata*.mat`) exceed GitHub's 100 MB per-file limit and are not tracked by git. To version them you need Git LFS; otherwise exclude them with a `.gitignore`.
