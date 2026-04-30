####################################################################################################
# PACKAGES
library(readxl)
library(xml2)
library(stringr)
library(Rmisc)
library(doBy)
library(tidyverse)

library(lme4)
library(car)
library(lmerTest)
library(pbkrtest)
library(emmeans)
library(permutest)

library(BayesFactor)

library(officer)
library(flextable)

library(cowplot)
library(gtools)
library(ggprism)
library(ggpubr)
library(rstatix)
library(VennDiagram)
library(ggbeeswarm)
library(gghalves)
library(viridis)

library(pander)
library(huxtable)
library(flextable)

library(R.matlab)

# set debugging options 
options(error = function() {
    sink(stderr())
    on.exit(sink(NULL))
    traceback(3, max.lines = 1L)
    if (!interactive()) {
        q(status = 1)
    }
})

####################################################################################################
# PATHS 

# -----------------------------------------------------------------------------------------
# set this manually
experiment_path <- '/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/raw'
img_pipe_path <- '/Users/tomaslenc/projects_git/img_pipe/src/img_pipe/SupplementalFiles'
# -----------------------------------------------------------------------------------------

deriv_path <- file.path(experiment_path, 'derivatives')
feat_path <- file.path(deriv_path, 'features')

save_path <- file.path(deriv_path, 'features', 'selections')
dir.create(save_path, recursive=T, showWarnings=F)

save_path_fig <- file.path(deriv_path, 'figures')
dir.create(save_path_fig, recursive=T, showWarnings=F)

####################################################################################################
# PARAMS 

auditory_model_type <- 'ic' # an, ic

# minimum number of responsive contacts within a ROI that is needed to process it further (i.e. to 
# include it in plots and stats)
min_n_contacts_roi <- 5

# freesurfer labels outside of gray matter
rois_fs_excl <- c('Cerebral-White-Matter','Unknown','unknown','WM-hypointensities','Inf-Lat-Vent')

# lists of ROIs 
auditory_rois <- c("HG","PT","pSTG","PP","mSTG")
assoc_rois <- c('SMG', 'SMC', 'IFG', 'MFG', 'SFG')
all_rois <- c(auditory_rois, assoc_rois, 'SMA', 'preSMA')

####################################################################################################
# PLOTTING

rhythm_label_map <- c(sp='sp', 
                      wp='wp')

fontsize <- 14

# horizontal zero line in beat-index plots 
show_zero_line <- TRUE

# ROI color LUT 
data <- read_xml(file.path(img_pipe_path, 'FreeSurferLUT.xml'))
label = xml_find_all(data, xpath='//labelset/label')

str_to_rm <- c('^Left-', '^Right-', 
               '^ctx_lh_', '^ctx_rh_', 
               '^ctx-lh-', '^ctx-rh-', 
               '^wm_lh_', '^wm_rh_',
               '^wm-lh-', '^wm-rh-')
label_name <- xml_attr(label, 'fullname')
for (x in str_to_rm){
    label_name <- str_remove(label_name, x)
}
idx_to_rm <- duplicated(label_name)

label_color <- xml_attr(label, 'color')
label_color <- str_replace(label_color, '^0x', '#')

lut_fs <- setNames(label_color, label_name)
lut_fs <- lut_fs[!idx_to_rm]

lut_chang <- 
    list(
        'Unknown'=c(255, 255, 255),
        'HG'=c(16, 176, 77),
        'pmHG'=c(16, 176, 77),
        'alHG'=c(61, 190, 195),
        'PT'=c(44, 58, 152),
        'PP'=c(160, 56, 148),
        'pSTG'=c(176, 30, 35),
        'mSTG'=c(177, 178, 53)
    )
lut_chang <- sapply(lut_chang, function(x) rgb(x[1], x[2], x[3], maxColorValue=255))

lut_custom <-
    list(
        'Unknown'=c(255, 255, 255),
        'PMC'=c(230, 106, 145), 
        'SMA'=c(230, 106, 145), 
        'preSMA'=c(232, 137, 199),
        'PAC'=c(107, 107, 107)
    )
lut_custom <- sapply(lut_custom, function(x) rgb(x[1], x[2], x[3], maxColorValue=255))

lut_all <- c(lut_chang, lut_fs, lut_custom)
# 
# lut_all['inferiorfrontal'] <- lut_all['parstriangularis']
# lut_all['middlefrontal'] <- lut_all['rostralmiddlefrontal']
# lut_all['sensorymotor'] <- lut_all['precentral']
# lut_all['supramarginal'] <- '#d96900'

rgb2hex <- function(x) rgb(x[1], x[2], x[3], maxColorValue=255)

lut_all["IFG"] = rgb2hex(c(25, 159, 181))
lut_all["MFG"] = rgb2hex(c(101, 78, 163))
lut_all["SMC"] = rgb2hex(c(130, 90, 44))
lut_all["SMG"] = rgb2hex(c(230, 126, 34))

