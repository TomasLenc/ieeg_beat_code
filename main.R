rm(list=ls())

# get general parameters
source('config.R')

report_path <- file.path(deriv_path, 'reports')
if (!dir.exists(report_path)) dir.create(report_path, recursive=T)

# create reports 
for (response in c('LFP', 'biLFP')){
    
    for (rhythm in c('wp', 'sp')){
        
        report_fname <- sprintf('response-%s_rhythm-%s_task-listen_date-%s_time-%s_report', 
                                response, rhythm, Sys.Date(), format(Sys.time(),'%H-%M'))
        
        rmarkdown::render(sprintf('main.Rmd'), 
                          output_file=sprintf('%s/%s.html', report_path, report_fname))
    }
}



































# 
# rm(list=ls())
# 
# source('config.R')
# source('lib/utils.R')
# source('lib/figures.R')
# 
# # ================================================================================================================
# # analysis parameters
# # ================================================================================================================
# 
# # set this manually 
# response <- 'LFP'
# rhythm <- 'wp'
# task <- 'listen'
# 
# # responsiveness z-score threshold 
# z_snr_thr = ifelse(str_detect(response, 'biLFP'), qnorm(1-0.05), qnorm(1-0.01))
# 
# # plotting y axis limits 
# if (rhythm=='sp') {
#     ylims_fft <- c(-1.1, 1.2)# c(-0.8, 1.5) 
#     ylims_acf <- c(-1.1, 1.2)
# } else if (rhythm=='wp') {
#     ylims_fft <- c(-0.7, 0.7) # c(-0.7, 1.2)
#     ylims_acf <- c(-1, 1)
# }
# 
# # horizontal zero line in beat-index plots 
# show_zero_line <- TRUE
# 
# # filenames and paths 
# save_prefix <- sprintf('response-%s_rhythm-%s_task-%s', response, rhythm, task)
# 
# anat_prefix <- ifelse(str_detect(response, 'bi'), 'bipolar_elecs_all', 'TDT_elecs_all')
#     
# deriv_path <- file.path(experiment_path, 'derivatives')
# 
# save_path <- file.path(deriv_path, 'features', 'selections')
# dir.create(save_path, recursive=T, showWarnings=F)
# 
# save_path_fig <- file.path(deriv_path, 'figures')
# dir.create(save_path_fig, recursive=T, showWarnings=F)
# 
# feat_path <- file.path(deriv_path, 'features')
# 
# # ================================================================================================================
# # load stimulus envelope  
# # ================================================================================================================
# 
# df_hilbert_fft <- read.csv(file.path(feat_path, 'response-hilbert_fftAggrFreq.csv'))
# df_hilbert_fft <- fixFactors(df_hilbert_fft)
# 
# df_hilbert_acf <- read.csv(file.path(feat_path, 'response-hilbert_aggrACFtrial.csv'))
# df_hilbert_acf <- fixFactors(df_hilbert_acf)
# 
# # ================================================================================================================
# # load brainstem model 
# # ================================================================================================================
# 
# auditory_model_type <- 'ic' # an, ic
# 
# if (auditory_model_type == 'an'){
#     
#     df_urear_fft <- read.csv(file.path(feat_path, 'response-an_fftAggrFreq.csv'))
#     df_urear_fft <- fixFactors(df_urear_fft)
#     
#     df_urear_acf <- read.csv(file.path(feat_path, 'response-an_aggrACFtrial.csv'))
#     df_urear_acf <- fixFactors(df_urear_acf)
# 
# } else if (auditory_model_type == 'ic'){
#     
#     df_urear_fft <- read.csv(file.path(feat_path, 'response-ic_fftAggrFreq.csv'))
#     df_urear_fft <- fixFactors(df_urear_fft)
#     
#     df_urear_acf <- read.csv(file.path(feat_path, 'response-ic_aggrACFtrial.csv'))
#     df_urear_acf <- fixFactors(df_urear_acf)
# 
# }
# 
# df_urear_acf <- select(df_urear_acf, rhythm, z_meterRel)
# 
# # ================================================================================================================
# # contact responsiveness
# # ================================================================================================================
# 
# # prepare dataframe with a list of responsive contacts 
# df_resp <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_resp <- fixFactors(df_resp)
# 
# # subset only listening wp 
# df_resp <- filter(df_resp, task=='listen' & rhythm=='wp')
# 
# # get info about responsive contacts 
# df_resp$responsive <- df_resp$z_snr > z_snr_thr
# df_resp <- select(df_resp, subject, elec, responsive)
#     
# # prepare dataframe with z-snr 
# df_zsnr_all <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_zsnr_all <- fixFactors(df_zsnr_all)
# 
# df_zsnr_all <- dplyr::inner_join(df_zsnr_all, df_resp)
# df_zsnr_all <- df_zsnr_all %>% select(subject, elec, rhythm, task, z_snr, responsive)
# 
# # subset responsive 
# df_zsnr_responsive <- df_zsnr_all %>% filter(responsive == TRUE)
# 
# # load responses to distortion products above 130 Hz 
# df_crossmod <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_ffrAggrCrossmod.csv', response)))
# df_crossmod <- fixFactors(df_crossmod)
# 
# # subset responsive 
# df_crossmod_responsive <- df_crossmod %>% 
#     filter(task=='listen' & rhythm=='wp' & z_snr > z_snr_thr) %>% 
#     select(subject, elec, z_snr)
# 
# # ================================================================================================================
# # anatomy
# # ================================================================================================================
# 
# auditory_rois <- c("HG","PT","pSTG","PP","mSTG")
# assoc_rois <- c('SMG', 'SMC', 'IFG', 'MFG', 'SFG')
# all_rois <- c(auditory_rois, assoc_rois, 'SMA', 'preSMA')
#     
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# # N participants
# length(unique(df_anat$subject))
# 
# # total N electrodes 
# nrow(df_anat)
# 
# # N in gray matter
# df_anat %>% count(in_gray)
# 
# df_anat %>% filter(in_gray==1) %>% count(hem)
# 
# sum(df_zsnr_all$responsive)
# 
# # N across all auditory ROIs
# df_anat %>% filter(custom %in% auditory_rois & custom != 'unknown') %>% nrow
# df_anat %>% filter(custom %in% auditory_rois & custom != 'unknown') %>% count(subject)
# 
# # N across all higher-level ROIs
# df_anat %>% filter(custom %in% assoc_rois & custom != 'unknown') %>% nrow
# df_anat %>% filter(custom %in% assoc_rois & custom != 'unknown') %>% count(subject)
# 
# # N contacts across all ROIs
# df_anat %>% filter(custom != 'unknown') %>% nrow
# df_anat %>% filter(custom != 'unknown') %>% count(subject)
# 
# # how many electrode arrays were implanted across all ROIs?  
# df <- filter(df_anat, custom != 'unknown')
# df$shaft <- str_extract(df$elec, '^[^0-9]+')
# df$sub_shaft <- str_c(df$subject, df$shaft, sep="_")
# length(unique(df$sub_shaft))
# 
# df %>% count(hem)
# 
# # ================================================================================================================
# # anatomically-defined PAC 
# # ================================================================================================================
# 
# # -------
# # anatomy
# # -------
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# # get only contacts in HG
# df_anat <- filter(df_anat, custom %in% c('HG'))
# 
# # ---
# # FFT
# # ---
# 
# # load FFT 
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset + add anatomy  
# df_data <- dplyr::inner_join(df_data, df_anat)
# nrow(df_data)
# 
# # add responsiveness info 
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# nrow(df_data)
# 
# df_summary <- summarySE(df_data, measurevar='z_snr', groupvars=c('custom'))
# sprintf('mean zSNR %.2f, 95%% CI [%.2f, %.2f]',
#         df_summary$z_snr, 
#         df_summary$z_snr-df_summary$ci, 
#         df_summary$z_snr+df_summary$ci)
# 
# df_summary <- summarySE(df_data, measurevar='z_meterRel', groupvars=c('custom'))
# sprintf('mean z-beat %.2f, 95%% CI [%.2f, %.2f]',
#         df_summary$z_meterRel, 
#         df_summary$z_meterRel-df_summary$ci, 
#         df_summary$z_meterRel+df_summary$ci)
# 
# mu <- filter(df_urear_fft, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# t.test(df_data$z_meterRel, mu=mu)
# t.test(df_data$z_meterRel, mu=0)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', hline_spec=mu,
#                     pntsize_ind='z_snr', pnt_col='lut', pnt_col_mean='black', hline_col='grey70',
#                     y_lims=ylims_fft, hline_zero=show_zero_line) 
# plt
# 
# # ---------
# # ACF
# # ---------
# 
# # load ACF trial 
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_aggrACFtrial.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset + add anatomy  
# df_data <- dplyr::inner_join(df_data, df_anat)
# nrow(df_data)
# 
# # add responsiveness info 
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive, z_snr))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# nrow(df_data)
# 
# mu <- filter(df_urear_acf, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# t.test(df_data$z_meterRel, mu=mu)
# t.test(df_data$z_meterRel, mu=0)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', hline_spec=mu,
#                     pntsize_ind='z_snr', pnt_col='lut', pnt_col_mean='black', hline_col='grey70',
#                     y_lims=ylims_acf, hline_zero=show_zero_line) 
# plt
# 
# 
# # ================================================================================================================
# # functionally-defined PAC (anatomical + physiological criterion)
# # ================================================================================================================
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# # get only contacts in HG
# df_anat <- filter(df_anat, custom %in% c('HG'))
# 
# # ---------
# # FFT
# # ---------
# 
# # load FFT 
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset + add anatomy  
# df_data <- dplyr::inner_join(df_data, df_anat)
# nrow(df_data)
# 
# # add responsiveness info 
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# nrow(df_data)
# 
# # subset responsive to crossmod above 100 Hz 
# df_data <- dplyr::inner_join(df_data, select(df_crossmod_responsive, subject, elec))
# nrow(df_data)
# 
# # save
# write.csv(df_data, 
#           file.path(save_path, sprintf('%s_atlas-functionalPAC_fft.csv', save_prefix)), 
#           row.names=F)
# 
# # let's keep this for later (to show PAC elecs in plots)
# df_pac <- df_data %>% select(subject, elec)
# 
# mu <- filter(df_urear_fft, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# t.test(df_data$z_meterRel, mu=mu)
# t.test(df_data$z_meterRel, mu=0)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', hline_spec=mu,
#                     pntsize_ind=1.2, pnt_col='lut', pnt_col_mean='black', hline_col='grey70', 
#                     y_lims=ylims_fft, hline_zero=show_zero_line) 
# plt
# 
# 
# # ---------
# # ACF
# # ---------
# 
# # load ACF 
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_aggrACFtrial.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset + add anatomy  
# df_data <- dplyr::inner_join(df_data, df_anat)
# nrow(df_data)
# 
# # add responsiveness info 
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive, z_snr))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# nrow(df_data)
# 
# # subset responsive to crossmod above 100 Hz 
# df_data <- dplyr::inner_join(df_data, select(df_crossmod_responsive, subject, elec))
# nrow(df_data)
# 
# mu <- filter(df_urear_acf, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# t.test(df_data$z_meterRel, mu=mu)
# t.test(df_data$z_meterRel, mu=0)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', hline_spec=mu,
#                     pntsize_ind=1.2, pnt_col='lut', pnt_col_mean='black', hline_col='grey70',
#                     y_lims=ylims_acf, hline_zero=show_zero_line) 
# plt
# 
# 
# 
# # ================================================================================================================
# # all auditory regions
# # ================================================================================================================
# 
# atlas_name <- 'auditory'
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# # select only in custom atlas 
# df_anat <- filter(df_anat, custom %in% auditory_rois)
# 
# # set ROI order for plotting
# df_anat$custom <- factor(df_anat$custom, levels=c("HG","PT","pSTG","PP","mSTG"))
# 
# df_count_all <- count_elec_roi(df_anat, 'custom')
# 
# # subset responsive 
# df_anat_resp <- dplyr::inner_join(df_anat, 
#                                   df_zsnr_responsive %>% 
#                                       filter(rhythm==!!rhythm & task==!!task) %>%
#                                       select(subject, elec))
# 
# df_count_resp <- count_elec_roi(df_anat_resp, 'custom')
# 
# plt <- plot_count_roi_resp(df_count_all, df_count_resp, 'custom')
# plt
# 
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_responsive_counts', save_prefix, atlas_name)), 
#          plt, width=5, height=4, png=F)
# 
# # ---------
# # FFT
# # ---------
# 
# # load FFT
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset + add anatomy  
# df_data <- dplyr::inner_join(df_data, df_anat)
# nrow(df_data)
# 
# # add responsiveness info 
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # add info about PAC 
# df_data$pac <- str_c(df_data$subject, df_data$elec) %in% str_c(df_pac$subject, df_pac$elec)
# stopifnot(length(df_data$pac) != nrow(df_pac))
# 
# # save
# write.csv(df_data, 
#           file.path(save_path, sprintf('%s_atlas-%s_fft.csv', save_prefix, atlas_name)), 
#           row.names=F)
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# nrow(df_data)
# 
# mu <- filter(df_urear_fft, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', 
#                     edgehighligh_name='pac', hline_spec=mu, hline_col='grey70', 
#                     pntsize_ind=2, pntalpha_ind=0.5, pnt_col='lut', dodge_width=0.2,
#                     pnt_col_mean='black', pntsize_mean=3, size_err=1.1, width_err=0,
#                     y_lims=ylims_fft, show_labels=F, hline_zero=show_zero_line)
# plt
# 
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_urear-%s_zbeatFFT',
#                                           save_prefix, atlas_name, auditory_model_type)), 
#          plt, width=1.9, height=2.5, png=F)
# 
# # mixed model 
# # -----------
# 
# m <- lmer(z_meterRel ~ custom + (1|subject), data=df_data)
# Anova(m, test='F')
# 
# # include z-snr as a covariate
# m <- lmer(z_meterRel ~ custom + z_snr + (1|subject), data=df_data)
# Anova(m, test='F')
# 
# # BF
# # --
# 
# bf <- anovaBF(z_meterRel ~ custom + subject, data=df_data, whichRandom='subject')
# bf
# 
# # include z-snr as a covariate
# bf_1 <- lmBF(z_meterRel ~ custom + subject + z_snr, data=df_data, whichRandom='subject')
# bf_0 <- lmBF(z_meterRel ~ custom + subject, data=df_data, whichRandom='subject')
# bf_0 / bf_1
# 
# # posthoc 
# # -------
# pairwise_contrasts_one_cond(m, var='custom', adjust_method='fdr', return_ci=TRUE)
# 
# # ttests 
# # ------
# ttest_against_mu <- function(df) {
#     res <- t.test(df$z_meterRel, mu=mu)
#     data.frame(t=res$statistic, df=res$parameter, pval=res$p.value)
# }
# df_against_mu <- ddply(df_data, c('custom'), ttest_against_mu)
# df_against_mu$pval <- p.adjust(df_against_mu$pval, method='fdr')
# df_against_mu$signif <- signifStars(df_against_mu$pval)
# df_against_mu
# 
# ttest_against_0 <- function(df) {
#     res <- t.test(df$z_meterRel, mu=0)
#     data.frame(t=res$statistic, df=res$parameter, pval=res$p.value)
# }
# df_against_0 <- ddply(df_data, c('custom'), ttest_against_0)
# df_against_0$pval <- p.adjust(df_against_0$pval, method='fdr')
# df_against_0$signif <- signifStars(df_against_0$pval)
# df_against_0
# 
# # ---------
# # ACF
# # ---------
# 
# # load ACF
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_aggrACFtrial.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset in custom atlas 
# df_data <- dplyr::inner_join(df_data, df_anat)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # add info about PAC 
# df_data$pac <- str_c(df_data$subject, df_data$elec) %in% str_c(df_pac$subject, df_pac$elec)
# stopifnot(length(df_data$pac) != nrow(df_pac))
# 
# # save
# write.csv(df_data, 
#           file.path(save_path, sprintf('%s_atlas-%s_acfTrial.csv', save_prefix, atlas_name)), 
#           row.names=F)
# 
# # subset responsive 
# df_data <- df_data %>% filter(responsive == TRUE)
# 
# mu <- filter(df_urear_acf, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', hline_spec=mu, hline_col='grey70', 
#                     edgehighligh_name='pac', pntsize_ind=2, pntalpha_ind=0.5, pnt_col='lut', dodge_width=0.2,
#                     pnt_col_mean='black', pntsize_mean=3, size_err=1.1, width_err=0,
#                     y_lims=ylims_acf, show_labels=F, hline_zero=show_zero_line) 
# plt
# 
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_urear-%s_zbeatACFtrial', 
#                                           save_prefix, atlas_name, auditory_model_type)), 
#          plt, width=1.9, height=2.5, png=F)
# 
# m <- lmer(z_meterRel ~ custom + (1|subject), data=df_data)
# Anova(m, test='F')
# 
# bf <- anovaBF(z_meterRel ~ custom+subject, data=df_data, whichRandom='subject')
# bf
# 
# ttest_against_mu <- function(df) {
#     res <- t.test(df$z_meterRel, mu=mu)
#     data.frame(t=res$statistic, df=res$parameter, pval=res$p.value)
# }
# df_against_mu <- ddply(df_data, c('custom'), ttest_against_mu)
# df_against_mu$pval <- p.adjust(df_against_mu$pval, method='fdr')
# df_against_mu$signif <- signifStars(df_against_mu$pval)
# df_against_mu
# 
# ttest_against_0 <- function(df) {
#     res <- t.test(df$z_meterRel, mu=0)
#     data.frame(t=res$statistic, df=res$parameter, pval=res$p.value)
# }
# df_against_0 <- ddply(df_data, c('custom'), ttest_against_0)
# df_against_0$pval <- p.adjust(df_against_0$pval, method='fdr')
# df_against_0$signif <- signifStars(df_against_0$pval)
# df_against_0
# 
# 
# # ================================================================================================================
# # higher-order associative regions
# # ================================================================================================================
# 
# atlas_name <- 'assoc'
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# df_anat <- dplyr::filter(df_anat, custom %in% c('HG', assoc_rois))
# df_anat$custom <- droplevels(df_anat$custom)
# df_anat$custom <- factor(df_anat$custom, levels=c('HG', assoc_rois))
# 
# # subset responsive 
# df_anat_resp <- dplyr::inner_join(df_anat, 
#                                   df_zsnr_responsive %>% 
#                                       filter(rhythm==!!rhythm & task==!!task) %>%
#                                       select(subject, elec))
# 
# # check counts
# count_elec_roi(df_anat, 'custom')
# count_elec_roi(df_anat_resp, 'custom')
# 
# ## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# if (response == 'LFP'){
#     # remove SFG (too little responsive electrodes)
#     bad_rois <- c('SFG')
# } else if (response == 'biLFP'){
#     # remove SFG and MFG (too little responsive electrodes)
#     bad_rois <- c('SFG', 'MFG')
# }
# df_anat <- filter(df_anat, !custom %in% bad_rois) %>% droplevels()
# df_anat_resp <- filter(df_anat_resp, !custom %in% bad_rois) %>% droplevels()
# ## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# 
# # recount
# df_count_all <- count_elec_roi(df_anat, 'custom')
# df_count_resp <- count_elec_roi(df_anat_resp, 'custom')
# 
# plt <- plot_count_roi_resp(df_count_all, df_count_resp, 'custom')
# plt 
# 
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_responsive_counts', save_prefix, atlas_name)),
#          plt, width=5, height=4, png=F)
# 
# # ---------
# # FFT
# # ---------
# 
# # load FFT
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, df_anat)
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # save
# write.csv(df_data, 
#           file.path(save_path, sprintf('%s_atlas-%s_fft.csv', save_prefix, atlas_name)), 
#           row.names=F)
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# mu <- filter(df_urear_fft, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', 
#                     hline_spec=mu, hline_col='grey70', 
#                     pntsize_ind=2, pntalpha_ind=0.5, pnt_col='lut', dodge_width=0.2,
#                     pnt_col_mean='black', pntsize_mean=3, size_err=1.1, width_err=0,
#                     y_lims=ylims_fft, show_labels=F, hline_zero=show_zero_line) 
# plt
#  
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_urear-%s_zbeatFFT', 
#                                           save_prefix, auditory_model_type, atlas_name)), 
#          plt, width=1.9, height=2.5, png=F)
# 
# # mixed model 
# m <- lmer(z_meterRel ~ custom + (1|subject), data=df_data)
# Anova(m, test='F')
# 
# # BF
# bf <- anovaBF(z_meterRel ~ custom + subject, data=df_data, whichRandom='subject')
# bf
# 
# # posthoc 
# pairwise_contrasts_one_cond(m, var='custom', adjust_method='fdr', return_ci=TRUE)
# 
# # include z-snr as a covariate
# df_data$z_snr_log <- log_trans(df_data$z_snr)
# 
# m <- lmer(z_meterRel ~ custom + z_snr_log + (1|subject), data=df_data)
# Anova(m, test='F')
# 
# bf_1 <- lmBF(z_meterRel ~ custom+subject+z_snr_log, data=df_data, whichRandom='subject')
# bf_0 <- lmBF(z_meterRel ~ subject+z_snr_log, data=df_data, whichRandom='subject')
# bf_1 / bf_0
# 
# # same model with z-snr as dependent variable 
# m_zsnr <- lmer(z_snr ~ custom + (1|subject), data=df_data)
# Anova(m_zsnr, test='F')
# pairwise_contrasts_one_cond(m_zsnr, var='custom', adjust_method='fdr', return_ci=TRUE)
# 
# # ttests 
# # ------
# 
# test_against_mu <- function(df) {
#     res <- t.test(df$z_meterRel, mu=mu)
#     data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
# }
# df_against_mu <- ddply(df_data, c('custom'), test_against_mu)
# df_against_mu$pval <- p.adjust(df_against_mu$pval, method='fdr')
# df_against_mu$signif <- signifStars(df_against_mu$pval)
# df_against_mu
# 
# test_against_0 <- function(df) {
#     res <- t.test(df$z_meterRel, mu=0)
#     data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
#     # data.frame(pval=res$p.value)
# }
# df_against_0 <- ddply(df_data, c('custom'), test_against_0)
# df_against_0$pval <- p.adjust(df_against_0$pval, method='fdr')
# df_against_0$signif <- signifStars(df_against_0$pval)
# df_against_0
# 
# # ---------
# # ACF
# # ---------
# 
# # load ACF
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_aggrACFtrial.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, df_anat)
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive, z_snr))
# 
# # save
# write.csv(df_data, 
#           file.path(save_path, sprintf('%s_atlas-%s_acfTrial.csv', save_prefix, atlas_name)), 
#           row.names=F)
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# mu <- filter(df_urear_acf, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', 
#                     hline_spec=mu, hline_col='grey70', 
#                     pntsize_ind=2, pntalpha_ind=0.5, pnt_col='lut', dodge_width=0.2,
#                     pnt_col_mean='black', pntsize_mean=3, size_err=1.1, width_err=0,
#                     y_lims=ylims_acf, show_labels=F, hline_zero=show_zero_line) 
# plt
# 
# # add zscore from hilbert envelope
# mu_hilbert <- filter(df_hilbert_acf, rhythm==!!rhythm) %>% pull(z_meterRel)
# plt + geom_hline(yintercept=mu_hilbert, col='pink', size=0.5) 
# 
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_urear-%s_zbeatACFtrial', 
#                                           save_prefix, atlas_name, auditory_model_type)), 
#          plt, width=1.9, height=2.5, png=F)
# 
# m <- lmer(z_meterRel ~ custom + (1|subject), data=df_data)
# Anova(m, test='F')
# 
# bf <- anovaBF(z_meterRel ~ custom + subject, data=df_data, whichRandom='subject')
# bf
# 
# # posthoc 
# pairwise_contrasts_one_cond(m, var='custom', adjust_method='fdr', return_ci=TRUE)
# 
# # ttests
# test_against_mu <- function(df) {
#     res <- t.test(df$z_meterRel, mu=mu)
#     data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
#     # data.frame(pval=res$p.value)
# }
# df_against_mu <- ddply(df_data, c('custom'), test_against_mu)
# df_against_mu$pval <- p.adjust(df_against_mu$pval, method='fdr')
# df_against_mu$signif <- signifStars(df_against_mu$pval)
# df_against_mu
# 
# test_against_0 <- function(df) {
#     res <- t.test(df$z_meterRel, mu=0)
#     data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
#     # data.frame(pval=res$p.value)
# }
# df_against_0 <- ddply(df_data, c('custom'), test_against_0)
# df_against_0$pval <- p.adjust(df_against_0$pval, method='fdr')
# df_against_0$signif <- signifStars(df_against_0$pval)
# df_against_0
# 
# # ================================================================================================================
# # SMA
# # ================================================================================================================
# 
# atlas_name <- 'sma'
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# # get only contacts in SMA and preSMA
# df_anat <- filter(df_anat, custom %in% c('SMA', 'preSMA'))
# 
# # merge SMA and preSMA
# df_anat$custom <- fct_recode(df_anat$custom, SMA='SMA', SMA='preSMA')
# 
# # subset responsive 
# df_anat_resp <- dplyr::inner_join(df_anat, 
#                                   df_zsnr_responsive %>% 
#                                       filter(rhythm==!!rhythm & task==!!task) %>%
#                                       select(subject, elec))
# # count
# df_count_all <- count_elec_roi(df_anat, 'custom')
# df_count_resp <- count_elec_roi(df_anat_resp, 'custom')
# 
# plt <- plot_count_roi_resp(df_count_all, df_count_resp, 'custom')
# plt
# 
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_responsive_counts', save_prefix, atlas_name)), 
#          plt, width=2, height=3, png=F)
# 
# # ---------
# # FFT
# # ---------
# 
# # load FFT
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, df_anat)
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # save
# write.csv(df_data, 
#           file.path(save_path, sprintf('%s_atlas-%s_fft.csv', save_prefix, atlas_name)), 
#           row.names=F)
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# mu <- filter(df_urear_fft, rhythm==!!rhythm) %>% pull(z_meterRel)
# t.test(df_data$z_meterRel, mu=mu)
# 
# one_sample(df_data$z_meterRel, shift=mu, alternative="greater", reps=10^4)
# one_sample(df_data$z_meterRel, shift=0, alternative="greater", reps=10^4)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', hline_spec=mu, hline_col='grey70', 
#                     pntsize_ind=2, pntalpha_ind=0.5, pnt_col='lut', dodge_width=0.2,
#                     pnt_col_mean='black', pntsize_mean=3, size_err=1.1, width_err=0,
#                     y_lims=ylims_fft, show_labels=F, hline_zero=show_zero_line) 
# plt
# 
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_urear-%s_zbeatFFT', 
#                                           save_prefix, atlas_name, auditory_model_type)), 
#          plt, width=1, height=2.5, png=F)
# 
# # ---------
# # ACF
# # ---------
# 
# # load ACF
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_aggrACFtrial.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, df_anat)
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive, z_snr))
# 
# # save
# write.csv(df_data, 
#           file.path(save_path, sprintf('%s_atlas-%s_acfTrial.csv', save_prefix, atlas_name)), 
#           row.names=F)
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# mu <- filter(df_urear_acf, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# t.test(df_data$z_meterRel, mu=mu)
# t.test(df_data$z_meterRel, mu=0)
# 
# plt <- plot_feature(df_data, feature_name='z_meterRel', atlas='custom', task='listen', hline_spec=mu, hline_col='grey70', 
#                     pntsize_ind=2, pntalpha_ind=0.5, pnt_col='lut', dodge_width=0.2,
#                     pnt_col_mean='black', pntsize_mean=3, size_err=1.1, width_err=0,
#                     y_lims=ylims_acf, show_labels=F, hline_zero=show_zero_line) 
# plt
# 
# save_fig(file.path(save_path_fig, sprintf('%s_atlas-%s_urear-%s_zbeatACFtrial', 
#                                           save_prefix, atlas_name, auditory_model_type)), 
#          plt, width=1, height=2.5, png=F)
# 
# 
# # ================================================================================================================
# # correlation between z-snr and beat index 
# # ================================================================================================================
# 
# # ---------------
# # prepare anatomy
# # ---------------
# 
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# # select ALL rois (auditory and associative, even if the given roi has small N responsive contacts)
# df_anat <- dplyr::filter(df_anat, custom %in% all_rois)
# 
# # ---------
# # FFT
# # ---------
# 
# # load FFT
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, select(df_anat, subject, elec, custom, hem))
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# # log transform 
# df_data$sum_magn_log <- log_trans(df_data$sum_magn)
# df_data$z_snr_log <- log_trans(df_data$z_snr)
# 
# ggplot(df_data, aes(z_snr_log, z_meterRel)) + 
#     geom_hline(aes(yintercept=0), data=df_urear_fft, color='black') +  
#     geom_hline(aes(yintercept=z_meterRel), data=df_urear_fft, color='gray80') +  
#     geom_point(color='#288ec9', alpha=0.5) + 
#     theme_cowplot() + 
#     facet_wrap(~rhythm)
# 
# # beat-index vs z-snr for strongly-periodic rhythm
# m <- lmer(z_meterRel ~ z_snr_log + (1|subject), data=filter(df_data, rhythm=='sp'))
# summary(m)
# 
# lmBF(z_meterRel ~ z_snr_log, whichRandom="subject", 
#      data=filter(df_data, rhythm=='sp'))
# 
# # beat-index vs z-snr for weakly-periodic rhythm
# m <- lmer(z_meterRel ~ z_snr_log + (1|subject), data=filter(df_data, rhythm=='wp'))
# summary(m)
# 
# lmBF(z_meterRel ~ z_snr_log, whichRandom="subject", 
#      data=filter(df_data, rhythm=='wp'))
# 
# # ---------
# # ACF
# # ---------
# 
# # load 
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_aggrACFtrial.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, select(df_anat, subject, elec, custom, hem))
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive, z_snr))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# # log transform 
# df_data$z_snr_log <- log_trans(df_data$z_snr)
# 
# ggplot(df_data, aes(z_snr_log, z_meterRel)) + 
#     geom_hline(aes(yintercept=0), data=df_urear_fft, color='black') +  
#     geom_hline(aes(yintercept=z_meterRel), data=df_urear_acf, color='gray80') +  
#     geom_point(color='#288ec9', alpha=0.5) + 
#     theme_cowplot() + 
#     facet_wrap(~rhythm)
# 
# # beat-index vs z-snr for strongly-periodic rhythm
# m <- lmer(z_meterRel ~ z_snr_log + (1|subject), data=filter(df_data, rhythm=='sp'))
# summary(m)
# 
# lmBF(z_meterRel ~ z_snr_log, whichRandom="subject", 
#      data=filter(df_data, rhythm=='sp'))
# 
# # beat-index vs z-snr for weakly-periodic rhythm
# m <- lmer(z_meterRel ~ z_snr_log + (1|subject), data=filter(df_data, rhythm=='wp'))
# summary(m)
# 
# lmBF(z_meterRel ~ z_snr_log, whichRandom="subject", 
#      data=filter(df_data, rhythm=='wp'))
# 
# 
# # ================================================================================================================
# # all ROIs - ttests against mu and 0
# # ================================================================================================================
# 
# # function that exports to a nice table 
# prepare_doc <- function(df){
#     
#     df$statistic <- round(df$statistic, 2)
#     df$pval <- p_format(df$pval, digits=1)
# 
#     ft <- flextable(df)
#     
#     # Rename Columns
#     ft <- set_header_labels(ft, 
#                             custom = "ROI", 
#                             statistic = "t", 
#                             pval = "P", 
#                             signif = '')
#     # Make Header Bold
#     ft <- flextable::bold(ft, part="header")
#     
#     # Align everything to the left
#     ft <- flextable::align(ft, align = "left", part = "all")
#     
#     # Set Font to Calibri (all parts: header and body)
#     ft <- flextable::font(ft, fontname = "Calibri", part = "all")
#     ft <- fontsize(ft, size = 12, part = "all")
#     
#     # Adjust columns to content width
#     ft <- autofit(ft)
#     
#     # Remove the fixed width property (this was making it unnecessarily wide)
#     ft <- set_table_properties(ft, layout = "autofit", width=1)
#     
#     doc <- read_docx()
#     doc <- body_add_flextable(doc, ft)
#     return(doc) 
# }
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# # don't forget to remove 'MFG' from here for biLFP (too few contacts)
# if (response == 'LFP'){
#     rois <- c("HG", "PT", "pSTG", "PP", "mSTG", "SMG", "SMC", "IFG", "MFG")
# } else if (response == 'biLFP'){
#     rois <- c("HG", "PT", "pSTG", "PP", "mSTG", "SMG", "SMC", "IFG")
# }
#              
# df_anat <- dplyr::filter(df_anat, custom %in% rois)
# df_anat$custom <- droplevels(df_anat$custom)
# df_anat$custom <- factor(df_anat$custom, levels=rois)
# 
# # subset responsive 
# df_anat_resp <- dplyr::inner_join(df_anat, 
#                                   df_zsnr_responsive %>% 
#                                       filter(rhythm==!!rhythm & task==!!task) %>%
#                                       select(subject, elec))
# 
# # ---
# # FFT 
# # ---
# 
# # load FFT
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, df_anat)
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# mu <- filter(df_urear_fft, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# # ttests
# test_against_mu <- function(df) {
#     res <- t.test(df$z_meterRel, mu=mu)
#     data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
#     # data.frame(pval=res$p.value)
# }
# df_against_mu <- ddply(df_data, c('custom'), test_against_mu)
# df_against_mu$pval <- p.adjust(df_against_mu$pval, method='fdr')
# df_against_mu$signif <- signifStars(df_against_mu$pval)
# df_against_mu
# 
# doc <- prepare_doc(df_against_mu)
# print(doc, target=file.path(save_path_fig, sprintf("%s_ttests_against_mu_fft.docx", save_prefix)))
# 
# test_against_0 <- function(df) {
#     res <- t.test(df$z_meterRel, mu=0)
#     data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
#     # data.frame(pval=res$p.value)
# }
# df_against_0 <- ddply(df_data, c('custom'), test_against_0)
# df_against_0$pval <- p.adjust(df_against_0$pval, method='fdr')
# df_against_0$signif <- signifStars(df_against_0$pval)
# df_against_0
# 
# doc <- prepare_doc(df_against_0)
# print(doc, target=file.path(save_path_fig, sprintf("%s_ttests_against_0_fft.docx", save_prefix)))
# 
# 
# # ---------
# # ACF
# # ---------
# 
# # load ACF
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_aggrACFtrial.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset rhythm and task
# df_data <- filter(df_data, task==!!task & rhythm==!!rhythm)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, df_anat)
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive, z_snr))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# mu <- filter(df_urear_acf, rhythm==!!rhythm) %>% pull(z_meterRel)
# 
# 
# # ttests
# test_against_mu <- function(df) {
#     res <- t.test(df$z_meterRel, mu=mu)
#     data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
#     # data.frame(pval=res$p.value)
# }
# df_against_mu <- ddply(df_data, c('custom'), test_against_mu)
# df_against_mu$pval <- p.adjust(df_against_mu$pval, method='fdr')
# df_against_mu$signif <- signifStars(df_against_mu$pval)
# df_against_mu
# 
# doc <- prepare_doc(df_against_mu)
# print(doc, target=file.path(save_path_fig, sprintf("%s_ttests_against_mu_acf.docx", save_prefix)))
# 
# 
# test_against_0 <- function(df) {
#     res <- t.test(df$z_meterRel, mu=0)
#     data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
#     # data.frame(pval=res$p.value)
# }
# df_against_0 <- ddply(df_data, c('custom'), test_against_0)
# df_against_0$pval <- p.adjust(df_against_0$pval, method='fdr')
# df_against_0$signif <- signifStars(df_against_0$pval)
# df_against_0
# 
# doc <- prepare_doc(df_against_0)
# print(doc, target=file.path(save_path_fig, sprintf("%s_ttests_against_0_acf.docx", save_prefix)))
# 
# 
# # ================================================================================================================
# # all ROIs - SNR of CAR vs. bipolar montage
# # ================================================================================================================
# # NOTE: we won't select only responsive contacts to keep the comparison fair: indeed, the z-snr threshold was different
# # for LFP and biLFP, which would bias the comparison. 
# 
# rois <- c("HG", "PT", "pSTG", "PP", "mSTG", "SMG", "SMC", "IFG", "MFG")
# 
# # -------------
# # prepare  CAR 
# # ------------
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-TDT_elecs_all_anatomy.csv')))
# df_anat <- fixFactors(df_anat)
# 
# df_anat <- dplyr::filter(df_anat, custom %in% rois)
# df_anat$custom <- droplevels(df_anat$custom)
# df_anat$custom <- factor(df_anat$custom, levels=rois)
# 
# # load functional 
# df_car <- read.csv(file.path(feat_path, sprintf('response-LFP_avg-time_fftAggrFreq.csv')))
# df_car <- fixFactors(df_car)
# df_car <- subset(df_car, rhythm=='wp' & task=='listen')
# df_car <- select(df_car, c('subject', 'elec', 'rhythm', 'task', 'z_snr', 'sum_magn', 'z_meterRel'))
# df_car$response <- 'LFP'
# 
# # subset ROIs only
# df_car <- dplyr::inner_join(df_car, df_anat)
# 
# # -------------
# # prepare bipolar 
# # -------------
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-bipolar_elecs_all_anatomy.csv')))
# df_anat <- fixFactors(df_anat)
# 
# df_anat <- dplyr::filter(df_anat, custom %in% rois)
# df_anat$custom <- droplevels(df_anat$custom)
# df_anat$custom <- factor(df_anat$custom, levels=rois)
# 
# df_bi <- read.csv(file.path(feat_path, sprintf('response-biLFP_avg-time_fftAggrFreq.csv')))
# df_bi <- fixFactors(df_bi)
# df_bi <- subset(df_bi, rhythm=='wp' & task=='listen')
# df_bi <- select(df_bi, c('subject', 'elec', 'rhythm', 'task', 'z_snr', 'sum_magn', 'z_meterRel'))
# df_bi$response <- 'biLFP'
# 
# # subset ROIs only
# df_bi <- dplyr::inner_join(df_bi, df_anat)
# 
# # -------------
# # concatenate
# # -------------
# 
# df <- rbind(df_car, df_bi)
# df$response <- factor(df$response, levels=c('LFP', 'biLFP'))
# 
# # log transform 
# df$sum_magn_log <- log_trans(df$sum_magn)
# df$z_snr_log <- log_trans(df$z_snr)
# 
# df_summary <- summarySE(df, measurevar='z_snr_log', groupvars=c('response', 'custom'))
# 
# cmap <- c(LFP='#aa62d1', biLFP='#cf9f11')
# 
# plt <- ggplot(df, aes(y=z_snr_log)) + 
#     geom_half_violin(aes(split=response, fill=response),
#                      color=NA, alpha=0.2,
#                      position='identity', trim=FALSE) +
#     geom_segment(data=df_summary,
#                aes(x=0.05*(as.numeric(response)-1.5-0.3), 
#                    xend=0.05*(as.numeric(response)-1.5+0.3), 
#                    y=z_snr_log), 
#                color='black', size=0.5) +
#     geom_errorbar(data=df_summary,
#                   aes(x=0.05*(as.numeric(response)-1.5), ymin=z_snr_log-ci, ymax=z_snr_log+ci), 
#                   color='black', width=0, size=0.6) +
#     scale_fill_manual(values=cmap) +
#     theme_minimal() + 
#     theme(
#         axis.title.x = element_blank(),
#         axis.text.x = element_blank()
#     ) + 
#     facet_wrap(~custom, nrow=1)
# 
# plt
# 
# save_fig(file.path(save_path_fig, sprintf('rhythm-wp_feat-logzsnr_LFP-vs-biLFP')), 
#          plt, width=10, height=2, png=F)
# 
# m <- lmer(z_snr_log ~ response + (1|subject), data=df)
# summary(m)
# 
# m <- lmer(z_snr_log ~ response + custom + (1|subject), data=df)
# summary(m)
# Anova(m, test='F')
# 
# bf <- anovaBF(z_snr_log ~ response + custom, data=df, whichRandom='subject')
# bf
# 
# 
# # ================================================================================================================
# # all ROIs - zSNR
# # ================================================================================================================
# 
# # load anatomy
# df_anat <- read.csv(file.path(feat_path, sprintf('prefix-%s_anatomy.csv', anat_prefix)))
# df_anat <- fixFactors(df_anat)
# 
# # don't forget to remove 'MFG' from here for biLFP (too few contacts)
# if (response == 'LFP'){
#     rois <- c("HG", "PT", "pSTG", "PP", "mSTG", "SMG", "SMC", "IFG", "MFG")
# } else if (response == 'biLFP'){
#     rois <- c("HG", "PT", "pSTG", "PP", "mSTG", "SMG", "SMC", "IFG")
# }
# 
# df_anat <- dplyr::filter(df_anat, custom %in% rois)
# df_anat$custom <- droplevels(df_anat$custom)
# df_anat$custom <- factor(df_anat$custom, levels=rois)
# 
# # load FFT
# df_data <- read.csv(file.path(feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response)))
# df_data <- fixFactors(df_data)
# 
# # subset task
# df_data <- filter(df_data, task==!!task)
# 
# # subset in ROIs
# df_data <- dplyr::inner_join(df_data, df_anat)
# 
# # add info about responsiveness
# df_data <- dplyr::inner_join(df_data, select(df_zsnr_all, subject, elec, rhythm, task, responsive))
# 
# # subset responsive 
# df_data <- filter(df_data, responsive==TRUE)
# 
# df_summary <- summarySE(df_data, 'z_snr', c('rhythm', 'custom'))
# df_summary$ci_low <- df_summary$z_snr - df_summary$ci
# df_summary$ci_high <- df_summary$z_snr + df_summary$ci
# df_summary <- select(df_summary, rhythm, custom, z_snr, ci_low, ci_high)
# 
# prepare_doc <- function(df){
#     df$z_snr <- round(df$z_snr, 2)
#     df$ci_low <- round(df$ci_low, 2)
#     df$ci_high <- round(df$ci_high, 2)
#     df$rhythm <- mapvalues(df$rhythm, 
#                            from=c('sp', 'wp'), 
#                            to=c('strongly-periodic', 'weakly-periodic'))    
#     df$rhythm <- factor(df$rhythm, levels=c('weakly-periodic', 'strongly-periodic'))
#     df <- dplyr::arrange(df, rhythm)
#     ft <- flextable(df)
#     ft <- set_table_properties(
#         ft,
#         width = 1,
#         layout = "autofit"
#     )
#     doc <- read_docx()
#     doc <- body_add_flextable(doc, ft)
# }
# 
# doc <- prepare_doc(df_summary)
# 
# print(doc, target=file.path(save_path_fig,
#                             sprintf("response-%s_task-%s_zsnr.docx", response, task)))
# 
# # model with z-snr as dependent variable
# # --------------------------------------
# 
# # we'll do the same as when comparing beat index across associative ROIs
# rois <- c('HG','SMG', 'SMC', 'IFG', 'MFG')
# 
# df_data$z_snr_log <- log_trans(df_data$z_snr)
# 
# # include both rhythms (as a main effect)
# m_zsnr <- lmer(z_snr_log ~ rhythm + custom + (1|subject), 
#                data=subset(df_data, custom %in% rois))
# 
# Anova(m_zsnr, test='F')
# 
# pairwise_contrasts_one_cond(m_zsnr, var='custom', adjust_method='fdr', return_ci=TRUE)
# 
# # only for sp rhythm? (see Results section for context)
# m_zsnr <- lmer(z_snr_log ~ custom + (1|subject), 
#                data=subset(df_data, rhythm=='sp' & custom %in% rois))
# 
# Anova(m_zsnr, test='F')
# 
# bf <- anovaBF(z_snr_log ~ custom + subject, 
#               data=subset(df_data, rhythm=='sp' & custom %in% rois),
#               whichRandom='subject')
# bf
# 
# pairwise_contrasts_one_cond(m_zsnr, var='custom', adjust_method='fdr', return_ci=TRUE)
# 
# 
# 
