#!/bin/bash

#Date: 22nd Feb
#Author: Shubham Pandey 

#fetch the 3D structure from pdb database
echo -n "enter PDB  ID: "
read id
pdb_fetch $id > $id.pdb

gnome-terminal --command "vmd $id.pdb" &
sleep 2

##Step to follow MD Simulation
#1. Protein preparation
    #a) remove water molecules using -v command 

grep -v HOH $id.pdb > $id_clean.pdb
echo "Water is removed from $id.pdb, check file named as '$id_clean.pdb'"
#Note that such a procedure is not universally appropriate (e.g., the case of a tightly bound or otherwise functional active-site water molecule). 

    #b) use pdb2gmx to generate  a topology file, a position restrain file and post-processed structure file/

echo "15" | gmx pdb2gmx  -f $id_clean.pdb -o $id_processed.gro -water spce
##we can use different water models like tip3p, tip4p and tip5p
echo "Topology and restraint file generated generated"

#2. Now, its time to add solvation and generate simulation box
gmx editconf -f $id_processed.gro -o $id_newbox.gro -c -d 1.0 -bt cubic
## we can use different shape of simulation boxes such as triclinic, dodecahedron
#NOTE "argument says rhombic dodecahedron crystal needs a lower number of solvent molucles and prevents the macromolecules of interest from interacting its image. As well as it is computationally less intensive"
## Fill the simulation box with water
gmx solvate -cp $id_newbox.gro -cs spc216.gro -o $id_solv.gro -p topol.top

#3. Add ions
#"To produce a .tpr file with grompp, we will need an additional input file, with the extension .mdp (molecular dynamics parameter file); grompp will assemble the parameters specified in the .mdp file with the coordinates and topology information to generate a .tpr file.

#An .mdp file is normally used to run energy minimization or an MD simulation, but in this case is simply used to generate an atomic description of the system."
gmx grompp -f ions.mdp -c $id_solv.gro -p topol.top -o ions.tpr
#replace water molecule with ions
#NOTE: make sure to check the group numering.
echo "13" | gmx genion -s ions.tpr -o $id_solv_ions.gro -p topol.top -pname NA -nname CL -neutral

#4. The system with  added water and ions within simulation box will go for energy minimization.
gmx grompp -f minim.mdp -c $id_solv_ions.gro -p topol.top -o em.tpr
gmx mdrun -v -deffnm em

#Plot Potential energy plot vs Minimisation step
echo "10 0" | gmx energy -f em.edr -o potential.xvg

gnome-terminal --command "python3 xvg_png_energy.py" & sleep 2

#5. Now we need to equilibrate the system
#REASON:  To begin real dynamics, we must equilibrate the solvent and ions around the protein. If we were to attempt unrestrained dynamics at this point, the system may collapse. 

    #a)Thermostat [NVT ensemble, Isothermal-isochoric or Canonical]
gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
gmx mdrun -deffnm nvt

#Plot
echo "16 0" | gmx energy -f nvt.edr -o temperature.xvg
gnome-terminal --command="python3 xvg_png_temperature.py"

    #b)Barostat [NPT ensemble, Isothermal-isobaric]
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
gmx mdrun -deffnm npt

#Plot
echo "18 0" | gmx energy -f npt.edr -o pressure.xvg
gnome-terminal --command="python3 xvg_png_pressure.py"

#NOTE: There may be a chage that the pressure value we get from simulation will have high deviation as compare to experimental value. AS NPT converge slower than NVT and thus takes more time.
#In the meantime we can calculte the density of the solvent which will be a good comparinig  point with the experimental values.
echo "24 0" | gmx energy -f npt.edr -o density.xvg
gnome-terminal --command="python3 xvg_png_density.py"

#6. Well at this point your system is stablized enough and ready for PRODUCTION run :)
gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr
gmx mdrun -deffnm md_0_1