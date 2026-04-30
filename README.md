Code repository for:   
*Lenc T, Jonas J, Colnat-Coulbois S, Rossion B, Nozaradan S. Intracerebral recordings in humans reveal gradual emergence of musical beat representation across the dorsal auditory pathway.*  

 
The data are available on openneuro *link_here*. 


## Dependencies
- [letswave6](https://github.com/NOCIONS/letswave6)
- [rnb_tools (commit `???`)](https://github.com/TomasLenc/rnb_tools)
- [acf_tools (commit `???`)](https://github.com/TomasLenc/acf_tools)
- [img_pipe (commit `???`)](https://github.com/TomasLenc/img_pipe_python3.9.git)

The img_pipe library must be installed using conda. 

## Pipeline

When using matlab, make sure your working directory is set to the root folder of the code directory (where `get_par.m` file is located). 


**Step 1: set up matlab** 

Go to `get_par.m` and set the paths to the data. 


**Step 2: preprocessing** 

Run `prepare_anat_bipolar.m`in Matlab. This will take the list of all electrode contacts in _derivatives/features/prefix-TDT_elecs_all_anatomy.csv_ and prepare the bipolar channels along with their xyz locations and anatomical labels.  

Next, run `preprocessing.m`. 


**Step 2b (optional): brainstem model** 

As the simulation takes a long time, the openneuro dataset already contains the output of the model in "urear" subfolder. If you want to run the model yourself, first you need to compile some mex files. Go to `lib/urear` and follow the README. When done, run the script `run_urear.m`.  


**Step 3: stats in R** 

Open the `config.R` in R and set your paths. Then, run `main.R`. This will automatically run all analyses, and generate figures in _derivatives/figures_, as well as RMarkdown reports with the results in _derivatives/reports_. 


**Step 4: make rest of the figures in python and matlab** 

Matlab 

* Run `fig1.m` in matlab to prepare Figure 1.  

* Run `fig3_main.m`, `fig3_roi_meshes.m`, and `fig3_stim.m` to create elemets that can be assembled into Figure 3. Note that some of the scripts may need to be run several times (e.g. once per rhythm), after adjusting the relevant parameter manually at the start of the script.  

python  

* Run `fig2.py` in python to prepare elements for Figure 2. IMPORTANT: Don't forget to set the paths at the begining of the script. Because of troubles with mayavi (originally used in img_pipe), the updated (tweaked) version uses pyvista. On mac, the only way to actually render the figures from a script is to run it in a jupyter window in vscode (select the whole script and "run in interactive window').  

* Run `figS1_auditory.py` and `figS1_associative.py` to create individual brain meshes for Figure S1. 
