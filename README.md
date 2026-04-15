# Emona 101/C Telecommunications Emulator

Welcome to the Emona 101/C Emulator! This software is a virtual version of the physical Emona 101/C Telecommunications Experimenter board. It allows you to build, route, and test analog and digital communication circuits directly on your computer, just like you would with physical cables in a laboratory.

---

## 📥 How to Download and Install

Before you begin, you need to download the files to your computer. 
* If you are on the GitHub webpage, click the green **"<> Code"** button near the top right, and select **"Download ZIP"**. 
* Extract (unzip) the downloaded folder to a location on your computer, such as your Desktop.

Once you have the folder open, choose **ONE** of the installation methods below that best fits your situation.

### Method 1: I do NOT have MATLAB installed (Recommended for most users)
If you don't use MATLAB or don't have a license, you can run this as a standalone Windows program.

1. Open the downloaded folder and navigate to this exact path:  
   `standalone installers` ➔ `for_redistribution`
2. Double-click the file named **`Emona101Installer_web.exe`**.
3. Follow the installation wizard. 
   * *Note: If this is your first time running a MATLAB-built standalone app, the installer will automatically download the "MATLAB Runtime" (a free background program required to run the math engine). This may take a few minutes depending on your internet speed.*
4. Once installed, you can open the **Emona101Emulator** from your Windows Start Menu.

### Method 2: I already have MATLAB installed
If you are a student or engineer who already has MATLAB on your computer, installing the app directly into MATLAB is the fastest method.

1. Open the main downloaded folder.
2. Find the file named **`Emona101Emulator.mlappinstall`**.
3. Double-click this file. MATLAB will open automatically and prompt you to install the application.
4. Click **Install**.
5. To open the emulator, go to the **Apps** tab at the top of your MATLAB window and click the **Emona101Emulator** icon.

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

## 📄 Disclaimer
This software was developed strictly for educational purposes. The Emona 101/C hardware specifications, board layout, and trademarks are the intellectual property of Emona Instruments Pty Ltd.