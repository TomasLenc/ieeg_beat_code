UR EAR - University of Rochester Envisioning Auditory Responses (Version 2020a) 

Getting Started
---------------

UR_EAR is a MATLAB code package created to study and explore various auditory
models and stimuli. This code has the Zilany 2014 Auditory Nerve (AN) model
and the Bruce et al. (2018) AN model [See bottom of this file for details
regarding the Bruce et al model]. An inferior colliculus (IC) Modulation
Filter model (Mao et al 2013), and the Same-Frequency Inhibition and
Excitation (SFIE) model (Nelson and Carney 2004; Carney et al., 2015) are 
included, as well as some classic auditory stimuli. Through a graphical user 
interface (GUI), the user can select a model, a stimulus, and select a variety 
of parameters, and then run the code. The output consists of a series of 
plots such as the waveform, spectrum, and model responses.

It is possible to edit the code to add in your own stimuli and/or models.
More detailed instructions lie in the code itself and in the user manual.

See below for instructions for installation and running initially. Refer to
the user manual, manual_UR_EAR_2020a.pdf for more detailed information and
instructions.

Install
-------
To install the UR_EAR code package, download the zip file from the website,
and unzip. Save the folder, and then open it and add it to your path in MATLAB.

This code has been tested on Windows 10, various Mac operating systems, and
Ubuntu/Linux Mint.

(Note: run testANModel.m for a quick check that your installation is OK.)

To Run
------
Open the code package in MATLAB, and add only the main folder to your path.  
It is important not to add to your path any of the subfolders, especially 
+stimuli and private.  Open UR_EAR_2020a.m, and run it. A GUI will open, 
and you will be able to make your selections.

Built With
----------
This code was originally created in MATLAB R2015b, and updated using Matlab 2020. 
You will need MATLAB R2015b or later to run this code.

Version
-------
This is UR_EAR_2020a, Version 2020a (May 2020).

Authors
-------
Laurel H. Carney, PI
Version 2020a: Douglas M. Schwarz
Version 2_2 (circa 2019): Afagh Farhadi
Version 1_0 (circa 2016): Langchen Fan, Natalia Galant, Braden Maxwell, Danika Teverovsky, Thomas Varner

References (Please cite the appropriate model papers in any publications)
----------------------------
Bruce, I. C., Erfani, Y., & Zilany, M. S. (2018). A phenomenological model
of the synapse between the inner hair cell and auditory nerve: Implications
of limited neurotransmitter release sites. Hearing research, 360, 40-54.

Carney, L. H., Li, T., & McDonough, J. M. (2015). Speech Coding in the Brain:
Representation of Vowel Formants by Midbrain Neurons Tuned to Sound
Fluctuations. ENeuro, 2(4). doi:10.1523/eneuro.0004-15.2015

Mao, J., Vosoughi, A., & Carney, L. H. (2013). Predictions of diotic
tone-in-noise detection based on a nonlinear optimal combination of energy,
envelope, and fine-structure cues. The Journal of the Acoustical Society of
America J. Acoust. Soc. Am., 134(1), 396. doi:10.1121/1.4807815

Nelson, P. C., & Carney, L. H. (2004). A phenomenological model of peripheral
and central neural responses to amplitude-modulated tones. The Journal of
the Acoustical Society of America J. Acoust. Soc. Am., 116(4), 2173.
doi:10.1121/1.1784442

Zilany, M. S., Bruce, I. C., & Carney, L. H. (2014). Updated parameters and
expanded simulation options for a model of the auditory periphery. The
Journal of the Acoustical Society of America J. Acoust. Soc. Am., 135(1),
283-286. doi:10.1121/1.4837815

####################################################3

This code ALSO includes the BEZ2018 version of the code for the auditory-periphery 
model from the Bruce lab at McMaster University.

This release implements the version of the model described in:

	Bruce, I.C., Erfani, Y., and Zilany, M.S.A. (2018). "A Phenomenological
	model of the synapse between the inner hair cell and auditory nerve: 
	Implications of limited neurotransmitter release sites," to appear in
	Hearing Research. (Special Issue on "Computational Models in Hearing".)

Please cite this paper if you publish any research results obtained with
this code or any modified versions of this code.

*** Change History ***

See the file changelog.txt

*** Instructions ***

The Matlab and C code included with this distribution is designed to be
compiled as a Matlab MEX file, i.e., the compiled model MEX function will run
as if it were a Matlab function.  The code can be compiled within Matlab using
the function:

    mexANmodel.m

Note that it is also possible to compile and run the code in the open-source
(i.e, free!) software Octave just as it is done in Matlab, although it will
typically run more slowly in Octave.  It may be necessary to install the
"signal" and "control" packages within Octave before running the AN model code.

The code is implemented in two parts. The first function, model_IHC_BEZ2018,
takes the acousic signal as input and gives the IHC's relative transmembrane
potential (Vihc) as the output.  The second function, model_Synapse_BEZ2018,
takes Vihc as input and outputs the PSTH (or a spike train for a single stimulus
presentation).  There are also a number of additional optional outputs from
this second function - see the help information for further details. For
instructions on how to run the code, the following commands can be run at
the Matlab command prompt:

    help model_IHC_BEZ2018

    help model_Synapse_BEZ2018

We have also included:-

1. a Matlab function "generateANpopulation.m" for generating a population
   of AN fibers with the statistics for spont rate and absolute & relative
   refractory periods as described in the journal article,

2. a function "fitaudiogram2.m" for estimating the parameters for outer and
   inner hair cell impairment, Cohc and Cihc, respectively, for a given
   audiogram, and

3. a number of scripts with filenames beginning with "test..." that run
   simulations and generate figures similar to a subset of those from the
   journal article and supplementary material.

ACKNOWLEDGMENTS

Earlier contributions to the model code made by Xuedong Zhang,
Michael G. Heinz, Qin Tan, Paul C. Nelson, and Laurel H. Carney.

%%% Ian C. Bruce (ibruce@ieee.org), Yousof Erfani (erfani.yousof@gmail.com),
    Muhammad S. A. Zilany (msazilany@gmail.com) - December 2017 %%%