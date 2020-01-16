# Pore-Algorithm-and-18-lattices-numerical-method

This method is for simulating the capillary force of sand in different matrix suction, including SWCC and net interparticle force by negative pore water pressure and surface tension.

Name of code : Pore-Algorithm and 18 lattices numerical method
Developper : Chengsheng Li
Contact details : State Key Laboratory of Geomechanics and Geotechnical Engineering, Institute of Rock and Soil Mechanics, Chinese Academy of Sciences, Wuhan, Hubei 430071, China; 
email : lichengsheng@outlook.com
Year first availabel : 2020
Hardware required : SWCC was run a computer with 4 cores (3.4 GHz each) and 8 GB.
Software required and language : Matlab 2019b or other versions.
Details on how to access the source code : the source files of the Pore-Algorithm and 18 lattices numerical method can be downloaded from github https://github.com/lichengshengHK/Pore-Algorithm-and-18-lattices-numerical-method.

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
   
   There will generate r_x_SWWCC.mat and tif result folder "r_x_SWCC".

4.SWCC Hysteresis

   Click [File] load the SWCC tif result of r, 
   
   then, Click [模拟半径] import [ water, air, ske, Hysteresis part ] the gray value of those Number of thoes part
   
   like " [1, 2, 3, 1]", the Hysteresis part is air, the simulation is about Drying path,
   
   if " [1, 2, 3, 2]", the Hysteresis part is air, the simulation is about wetting path,
   
   then, Click [SWCC Hysteresis], the hysteresis of "ink-bottle" effect will be simulated.
   
   finally, "Drying path" or "Wetting path" file which include tif results will be generated.
   
   if size of the "r" of the SWCC Simulate is 10, the "SWCC Hysteresis" need to be carry 10*2 = 20 timmes.
   
   At the [滞后Sr] will show the hysteresis Sr of this matric suction of wetting path or drying path.

5.SWCC Force

   Click [File] load the "Drying path" or "Wetting path" (including tif results images)
   
   then, Click [SWCC Force], a result data of VCT.mat will be generated.
   
   VCT.mat including the Solid-liquid force "VCT.F_Ws"and Solid-liquid-air force "VCT.Wa".
   
   if size of the "r" of the SWCC Simulate is 10, the "SWCC Force" need to be carry 10*2 = 20 timmes.
  
6. Finally, the program can give the average result number of "[ sum(Fwix) + sum(Fwiy) + sum(Fwiz) ] / 6", 
 



