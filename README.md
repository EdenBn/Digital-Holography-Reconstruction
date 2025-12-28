\# Digital Holography Reconstruction Tool 🔬



\*\*A MATLAB-based tool for reconstructing digital holograms using Off-Axis Fresnel Back-Propagation.\*\*

!\[GUI Loader](assets/gui_loader1.png)

\## Overview

This project was developed as part of an advanced physics lab at Ben-Gurion University. It provides a complete workflow for reconstructing amplitude and phase information from digital holograms.



The tool features a graphical user interface (GUI) that allows users to load interference patterns, tune physical parameters in real-time (propagation distance, angle, wavelength), and perform 3D surface measurements.

!\[GUI Loaded](assets/gui_loader2.png)

\## Features

\* 📦 \*\*Data Loading:\*\* Dedicated interface for loading Object, Reference, and Hologram images.

\* 🎛️ \*\*Real-Time Control:\*\* Adjust reconstruction distance ($d$), wavelength ($\\lambda$), and reference angle ($\\theta$) with immediate visual feedback.

\* 📐 \*\*Dual Reconstruction:\*\* Outputs both Amplitude (intensity) and Phase (topography) maps.

\* 🔄 \*\*Phase Unwrapping:\*\* Integrated Least-Squares (LSQ) unwrapping for 3D depth estimation.

\* 🛠️ \*\*Analysis Tools:\*\* Built-in ROI selection for calculating RMS surface roughness.



\## File Structure

\* `src/`: Core logic and GUI scripts.

\* `utils/`: Helper algorithms (Phase Unwrapping).

\* `data/`: Sample dataset (Bullet Casing) for testing.



\## How to Run (Demo)

1\.  Clone the repository and add the folders to your MATLAB path.

2\.  Run the loader script:

    ```matlab

    holography\_loader

    ```

3\.  In the loader window, select the images from the `data/` folder.

4\.  Click \*\*Start Reconstruction\*\*.

5\.  In the Control Panel, use the parameters of th demo datasets.



\## Results

\### Amplitude Reconstruction

!\[Amplitude Reconstruction](results/6.4.2-3.png)

\*Clear reconstruction of the object intensity, removing the DC term and twin image.\*



\### 3D Phase Map (Bullet Casing)

!\[3D Phase Map](results/6.4.2-5.png)

\*Topographical reconstruction of a 9mm bullet casing, revealing surface depth.\*



\## Future Improvements

\* Optimization for live rendering while adjusting sliders.

\* Auto-focus algorithm to detect optimal reconstruction distance automatically.



\## Credits \& References

\* \*\*Author:\*\* Eden Banim (Ben-Gurion University).

\* \*\*Phase Unwrapping Algorithm:\*\* Provided by \*\*Muhammad F. Kasim\*\* (University of Oxford, 2016), based on the work of Ghiglia \& Romero.

