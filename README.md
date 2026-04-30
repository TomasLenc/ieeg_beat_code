Code repository for:   
*Lenc T, Jonas J, Colnat-Coulbois S, Rossion B, Nozaradan S. Intracerebral recordings in humans reveal gradual emergence of musical beat representation across the dorsal auditory pathway.*  

 
The data are available *link_here*. 

This code runs on macOS 26.4 (Apple M2 Pro, 32GB RAM), Matlab R2018a, python 3.12, and R 4.5.3. 

## Dependencies
- [letswave6](https://github.com/NOCIONS/letswave6)
- [rnb_tools (commit `2a6830b`)](https://github.com/TomasLenc/rnb_tools/tree/2a6830b16120c8b285a888969bba74d91a076756)
- [acf_tools (commit `1cfc01b`)](https://github.com/TomasLenc/acf_tools/tree/1cfc01b5edb4b784dfb1eebddd0ea14eaece6251)

In addition, 3D rendering with python requires a fork of the `img_pipe` library that is included in the `lib/img_pipe` subfolder of the current repo. Before running any of the python code, the package needs to be installed in a dedicated enviornment. Follow the instructions in `lib/img_pipe/README.md`.   

## Pipeline

When using matlab, make sure your working directory is set to the root folder of the code directory (where `get_par.m` file is located). 


**Step 1: set up matlab** 

* Go to `get_par.m` and set the paths to the data and external code libraries. 


**Step 2: preprocessing** 

* Run `prepare_anat_bipolar.m`in Matlab. This will take the list of all electrode contacts in _derivatives/features/prefix-TDT_elecs_all_anatomy.csv_ and prepare the bipolar channels along with their xyz locations and anatomical labels.  

* Run `preprocessing.m`. 


**Step 2b (optional): brainstem model** 

* As the simulation takes a long time, the publically available dataset already contains the output of the brainstem model in the `urear` subfolder. If you want to run the model yourself, first you need to compile some mex files. Go to `lib/urear` and follow the README. When done, run the script `run_urear.m`.  


**Step 3: stats in R** 

* Open the `config.R` in R and set your paths. 

* Then, run `main.R`. This will automatically run all analyses, and generate figures in the `derivatives/figures` folder, as well as RMarkdown reports with the results in the `derivatives/reports` folder. 


**Step 4: make rest of the figures in python and matlab** 

Matlab 

* Run `fig1.m` in matlab to prepare Figure 1.  

* Run `fig3_main.m`, `fig3_roi_meshes.m`, and `fig3_stim.m` to create elemets that can be assembled into Figure 3. Note that some of the scripts may need to be run several times (e.g. separately for each rhythm), after adjusting the relevant parameter manually at the start of the script.  

python  

* Run `fig2.py` in python to prepare elements for Figure 2. _IMPORTANT_: Don't forget to set the paths at the begining of the script. Because of troubles with `mayavi ` used in the original version of `img_pipe` package, the modified version that's included here uses `pyvista`. On mac, the only way to actually render the figures from a script without freezing is to run it in an interactive jupyter window in vscode (select the whole script and "Run in an interactive window').  

* Run `figS1_auditory.py` and `figS1_associative.py` to create individual brain meshes for Figure S1. 
