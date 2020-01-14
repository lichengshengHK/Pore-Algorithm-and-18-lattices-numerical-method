# Pore-Algorithm-and-18-lattices-numerical-method

This method is for simulating the capillary force of sand in different matrix suction, including SWCC and net interparticle force by negative pore water pressure and surface tension.

Thi codes are simulation about SWCC, hysteresis, force;
Its name is BWLABEL3D, it including some other codes.

Developer is: Chengsheng Li, lichengsheng@outlook.com,
Institute of Rock and Soil Mechanics, Chinese Academy of Sciences, Wuhan, 
Hubei 430071, China;
+86 15623646052 

Those codes are free.

Those programs base on MATLAB 2019b, you can run the BWLABEL3D.fig on 
MATLAB

The steps of simulation about "Simulation of capillary force in sand using Pore-Algorithm and 18 lattices numerical method"
are:

1. Prepare the porous media data, only include air and ske two part, the formatof file must be uint8.

2. Click [File] the tif file path, Click [Save] load the save fiel path,
   then Click [Generate .mat], a V.mat will be generated.

3. SWCC Simulate
  Click [Open] load the V.mat file path, 
  then Click [模拟半径] import the matrix suction r, like " [1:10]",
  Chose "SWCC Simulate"
  then Click [SWCC Simulate], a siries of data will be generated of different r.

4.SWCC Hysteresis
  Click [File] load the SWCC tif result of r, 
  then, Click [模拟半径] import [ water, air, ske, Hysteresis part ] the gray value of those Number of thoes part
  like " [1, 2, 3, 1]", the Hysteresis part is air, the simulation is about Drying path,
  if " [1, 2, 3, 2]", the Hysteresis part is air, the simulation is about wetting path,
  then, Click [SWCC Hysteresis], the hysteresis of "ink-bottle" effect will be simulated.
  finally, "Drying path" or "Wetting path" file which include tif results will be generated.

5.SWCC Force
  Click [File] load the "Drying path" or "Wetting path" (including tif results images)
  then, Click [SWCC Force], a result data of VCT.mat will be generated.
  VCT.mat including the Solid-liquid force "VCT.F_Ws"and Solid-liquid-air force "VCT.Wa".
 



