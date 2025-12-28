<div align="center">

# Digital Holography Reconstruction Tool 🔬

![MATLAB](https://img.shields.io/badge/MATLAB-R2024a-orange.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Status](https://img.shields.io/badge/Status-Active-green.svg)

**A complete workflow for reconstructing digital holograms using Off-Axis Fresnel Back-Propagation.**

[Overview](#overview) • [Features](#features) • [How To Run](#how-to-run-demo) • [Results](#results)

</div>

---

## Overview
This project was developed as part of an advanced physics lab at **Ben-Gurion University**. It provides a complete workflow for reconstructing amplitude and phase information from digital holograms.

The tool features a graphical user interface (GUI) that allows users to load interference patterns, tune physical parameters in real-time (propagation distance, angle, wavelength), and perform 3D surface measurements.

## Features
* 📦 **Data Loading:** Dedicated interface for loading Object ($|O|^2$), Reference ($|R|^2$), and Hologram ($|O+R|^2$) images.
* 🎛️ **Real-Time Control:** Adjust reconstruction distance ($d$), wavelength ($\lambda$), and reference angle ($\theta$) with immediate visual feedback.
* 📐 **Dual Reconstruction:** Outputs both **Amplitude** (intensity) and **Phase** (topography) maps.
* 🔄 **Phase Unwrapping:** Integrated Least-Squares (LSQ) unwrapping for 3D depth estimation.
* 🛠️ **Analysis Tools:** Built-in ROI selection for calculating RMS surface roughness.

## File Structure
```text
├── src/                  # Core logic and GUI scripts
├── utils/                # Helper algorithms (Phase Unwrapping)
├── assets/               # Screenshots for documentation
└── data/                 # Link to external Demo Dataset
