[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
# Emona 101/C Telecommunications Emulator

Welcome to the Emona 101/C Emulator! This software is a virtual version of the physical Emona 101/C Telecommunications Experimenter board. It allows you to build, route, and test analog and digital communication circuits directly on your computer, just like you would with physical cables in a laboratory.

---

## 📥 How to Download and Install

The easiest way to get started is to download the pre-packaged installers from the **[Releases](https://github.com/yasinsaad/Emona101Emulator/releases)** page.


### Method 1: MATLAB App (For MATLAB users)
1. Go to the **[Releases](https://github.com/yasinsaad/Emona101Emulator/releases)** page.
2. Download the **`Emona101Emulator.mlappinstall`** file.
3. Double-click the file to install it directly into your MATLAB Apps gallery.
4. Access it anytime via the **Apps** tab in the MATLAB toolstrip.


### Method 2: Standalone Windows App (No MATLAB required)
1. Go to the **[Releases](https://github.com/yasinsaad/Emona101Emulator/releases)** section on the right side of this page.
2. Download the **`Emona101Installer_standalone.exe`**.
3. Run the installer. 
   - *Note: The installer will automatically download the free MATLAB Runtime if you don't have it. This ensures the math engine runs correctly on your PC.*
4. Launch the **Emona101Emulator** from your Start Menu.

### Method 3: I want to run it from the Source Code (Advanced)
If you want to view or edit the underlying code:
1. Open MATLAB and navigate to the main downloaded folder.
2. Double-click the **`main.mlapp`** file to open it in MATLAB App Designer.
3. Click the green **Run** button at the top of the screen.
*(Note: You must have the Signal Processing Toolbox installed to run the source code).*

---

## 🎛️ How to Use the Emulator

This software is designed to behave exactly like the physical hardware board.

### 1. Making Connections (Patch Cables)
* **To connect a wire:** Click and hold your mouse on an **Output Port** (always located on the *right* side of a module block). Drag your mouse over to an **Input Port** (located on the *left* side of a module) and let go. The wire will snap into place.
* **To delete a wire:** Click on any wire you have drawn. It will glow to show it is selected. Then, look at the dark Tools Panel on the top left of your screen and click the red **Delete Cable** button.
* **Color Coding:** You can change the color of the next wire you draw by clicking the colored circles in the Tools Panel. This helps keep complex circuits organized.

### 2. Adjusting Knobs and Switches
* **Turning Knobs:** Because turning a knob in a circle with a mouse is frustrating, this emulator uses a drag system. **Click and hold the knob, then drag your mouse Up to increase the value, or Down to decrease it.**
* **Flipping Switches:** For standard switches (like the VCO range or Line Code selector), simply click directly on the switch text to toggle it.

### 3. Using the Oscilloscope
* The board features a built-in virtual oscilloscope. Connect any signal you want to view to the **CH A**, **CH B**, **CH C**, or **CH D** ports on the board.
* A pop-up black window will automatically appear showing your waveforms.
* To adjust how the waves look, use the **Oscilloscope Control** panel located in the main MATLAB window. You can stretch the waves horizontally (Time/Div) or vertically (Volts/Div) to get a clear view.

---

## ⚙️ Available Modules
This emulator currently supports the following hardware blocks:
* **Master Signals:**
* **Math Blocks:** Adders and Multipliers.
* **Filters:** Tunable Low-Pass, Channel Band-Pass, Baseband Low-Pass, and RC Low-Pass.
* **Generators:** VCO (Voltage Controlled Oscillator), Twin Pulse Generator, and Sequence Generator (PRBS).
* **Digital Logic:** Line Code Encoder (NRZ-L, Bi-Phase, AMI, NRZ-M), Analog Switch, and Comparator.


---

## 👤 Author
**Yasin Hasan Saad**

## 📖 Project Background

This emulator was developed as the final project for **EEE 4416: Simulation Lab** at the **Islamic University of Technology (IUT)**. 

### The Problem
During the **EEE 4404: Communication Engineering I Lab**, it was observed that many students struggled to grasp complex modulation and coding concepts due to limited access to the physical Emona 101/C trainer boards outside of scheduled lab hours. 

### The Solution
I developed this digital twin to provide:
* **Pre-lab Practice:** Allowing students to familiarize themselves with the hardware layout and signal routing before entering the lab.
* **Remote Learning:** Providing instructors with a tool for high-quality online demonstrations.
* **Open Access:** Ensuring that a lack of physical hardware is no longer a barrier to mastering telecommunications fundamentals.

The project demonstrates the application of MATLAB's **App Designer** and **DSP System Toolbox** to create an interactive, student-focused educational tool.

## 📄 Disclaimer
This software was developed strictly for educational purposes. The Emona 101/C hardware specifications, board layout, and trademarks are the intellectual property of Emona Instruments Pty Ltd.