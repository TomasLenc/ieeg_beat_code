## `img_pipe_tomo` – Tomas Lenc's personal fork of `img_pipe` ##

This is a fork of the [img_pipe](https://github.com/changlabucsf/img_pipe) package originally developed by **Liberty Hamilton, David Chang, Morgan Lee** at the [Laboratory of Dr. Edward Chang](http://changlab.ucsf.edu), UC San Francisco. See their [_Frontiers in Neuroinformatics_](https://doi.org/10.3389/fninf.2017.00062) paper for additional details about the original package.  

The aim here is to make `img_pipe` work with python3.9 on Ubuntu, and with python3.12 on Mac.  

All modifications made here are work in progress and **for my own use** (no proper documentation, no intent to release this beyond what's in the current repo)!  


## Installation notes


### Ubuntu 20.04 or 22.04

Make a virtual environment with python 3.9 (don't use conda) - only use virutalenv and pip. 

```console
$ virtualenv venv_img_pipe -p=python3.9
$ source venv_img_pipe/bin/activate
```

Use pip to install stuff from the requirements file
```console
$ pip install -r requirements.txt
```

Then install the package itself. From the folder where you cloned `img_pipe`, run: 

```console
$ pip install -e .
```

You will also need to install some dependencies that will otherwise crash qt
```console
$ sudo apt-get install libxcb-xinerama0
```

Also install [freesurfer6](https://surfer.nmr.mgh.harvard.edu/fswiki/rel6downloads). 

Now you should be ready to go...



### mac OS 

Note that any functionality that depends on freesurfer won't work on mac. However, once the electrode localisation, labeling, morphing, mesh generation, etc. have been done on linux, and the `subjects_dir` is copied onto a mac, `img_pipe` can be still used for plotting.  

Make sure you have python 3.12 available (if now, install it with brew). Use conda to make a virtual environment.  

```console
$ conda env create -f environment.yml 
$ conda activate img_pipe
```

Then install the package itself. From the folder where you cloned `img_pipe`, run: 

```console
$ pip install -e .
```

Done.  

---
