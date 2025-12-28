<div align="center">

# 🔬 Digital Holography Reconstruction Tool

![MATLAB](https://img.shields.io/badge/MATLAB-R2024a-orange.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Status](https://img.shields.io/badge/Status-Active-green.svg)

**A MATLAB-based workflow for reconstructing digital holograms using Off-Axis Fresnel back-propagation**

[Overview](#overview) • [Features](#features) • [How to Run](#how-to-run-demo) • [Results](#results)

</div>

---

## Overview

This project was developed as part of an advanced physics laboratory course at  
**Ben-Gurion University of the Negev**.

It provides a complete workflow for reconstructing **amplitude** and **phase**
information from off-axis digital holograms.

![GUI Loader Screenshot](assets/gui_loader1.png)

A graphical user interface (GUI) allows loading experimental data, adjusting
physical reconstruction parameters, and performing quantitative 3D surface
analysis.

---

## Features

- 📦 **Data Loading**  
  Support for standard digital holography inputs:
  - Object intensity \( |O|^2 \)
  - Reference intensity \( |R|^2 \)
  - Hologram \( |O + R|^2 \)

- 🎛️ **Interactive Reconstruction Control**  
  Real-time adjustment of:
  - Propagation distance \( d \)
  - Wavelength \( \lambda \)
  - Reference beam angle \( \theta \)

- 📐 **Amplitude & Phase Reconstruction**  
  Simultaneous visualization of reconstructed intensity and phase maps

- 🔄 **Phase Unwrapping**  
  Least-Squares (LSQ) phase unwrapping for quantitative depth estimation

- 🛠️ **Analysis Tools**  
  ROI selection and RMS surface roughness calculation

---

## How to Run (Demo)

1. Clone the repository and add all folders to your MATLAB path.
2. Run the main loader script.
3. Select one of the datasets from the `data/` folder.
4. Click **Start Reconstruction**.
5. Adjust parameters in the Control Panel as indicated for the selected dataset.

> The `data/` directory contains **two example datasets**, each with recommended
> reconstruction parameters.

---

## Results

### Amplitude Reconstruction

![Amplitude Reconstruction](results/6.4.2-3.png)

*Reconstructed object intensity after suppression of the DC term and twin image.*

---

### 3D Phase Map (Bullet Casing)

![3D Phase Map](results/6.4.2-5.png)

*Quantitative topographical reconstruction of a 9 mm bullet casing surface.*

---

## Future Improvements

- Improved performance for live parameter adjustment
- Automatic focus detection for optimal reconstruction distance estimation

---

## Credits & References

- **Author:** Eden Banim — Ben-Gurion University of the Negev  
- **Phase Unwrapping Algorithm:**  
  Muhammad F. Kasim (University of Oxford, 2016), based on Ghiglia & Romero

---

## File Structure

```text
├── src/        # Core reconstruction logic and GUI scripts
├── utils/      # Helper algorithms (e.g., phase unwrapping)
├── assets/     # Documentation images
└── data/       # Two example holography datasets


