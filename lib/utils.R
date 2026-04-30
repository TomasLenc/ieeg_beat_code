
ttest_against_mu <- function(df, mu) {
    res <- t.test(df$z_meterRel, mu=mu)
    data.frame(statistic=res$statistic, df=res$parameter, pval=res$p.value)
}


# log transform used for responsiveness
log_trans <- function(x){
    log(x + 10)  
} 


prep_anova_for_print <- function(res){
    tab <- as.data.frame(res)
    tab$`Pr(>F)` <- ifelse(
        tab$`Pr(>F)` < 1e-4,
        "<0.0001",
        signif(tab$`Pr(>F)`, digits=1)
    )
    return(pander(tab))
}


prep_bf_for_print <- function(res) {
    tab <- as.data.frame(res)
    tab$bf <- ifelse(
        tab$bf > 1e3,
        ">1000",
        signif(tab$bf, digits = 2)
    )
    tab <- tab %>% select(-time, -code)
    pander::set.caption(paste0("Against denominator: ", res@denominator@longName))
    out <- pander(tab)
    pander::set.caption('')
    return(out)
}


loadMagnROI <- function(roi, response, avg_method='time'){
    fname <- sprintf('response-%s_avg-%s_roi-%s_feature-magn.csv',response,avg_method,roi)
    df <- read.csv(file.path(csv_path,fname))
    df <- fixFactors(df)
    # only subset frequencies of interest 
    df <- filter(df, frequency%in%frex)
    return(df)
}


loadAllElec <- function(response, avg_method='time', suffix='aggrFreq', func_roi=NULL, rhythm=NULL, 
                        method='fft', from_deriv=FALSE){
    # This function loads an extracted tsv file with features. 
    # Parameters
    # ----------
    # response : str 
    #     reponse type (e.g. 'LFP')
    # avg_method : str | NULL
    #    How were the trials averaged? In the time domain or frequency domain? If NULL, the key-entity 
    #    pair will be omitted. 
    # suffix : str
    #     bids suffix of the tsv filename
    # func_roi : str|list
    #     if passed, all elements will be added to the filename as key-entity pairs 
    # rhythm : str
    #     if passed, a rhythm-<rhythm> will be added as an key-entity to the filename
    # 
    # Returns
    # -------
    # df : data.frame
    #   loaded dataframe
    #     
    if (response == 'force') avg_method <- NULL
    # build filename 
    fname <- sprintf('response-%s', response)
    if (!is.null(avg_method)) fname <- sprintf('%s_avg-%s', fname, avg_method)
    if (!is.null(rhythm)) fname <- sprintf('%s_rhythm-%s', fname, rhythm)
    if (!is.null(func_roi)) {
        for (froi in func_roi) fname <- sprintf('%s_funcROI-%s', fname, froi)
    }
    if (!is.null(suffix)) fname <- sprintf('%s_%s', fname, suffix)
    fname <- sprintf('%s.csv', fname)
    if (from_deriv) {
        fpath <- file.path(experiment_path, 'derivatives')
    } else {
        fpath <- file.path(experiment_path, 'features')
    }
    # load data 
    df <- read.csv(file.path(fpath, fname))
    df <- fixFactors(df)
    
    return(df)
}


fixFactors <- function(df){
    # This function takes care of 
    # (1) changing char columns to factors
    # (2) renaming factor names and levels
    # (3) reordering factor levels if needed
    roi_col_idx <- which(str_detect(names(df), '^roi'))
    for (i_col in roi_col_idx){
        # convert to factor
        df[,names(df)[i_col]] <- factor(df[,names(df)[i_col]])
    }
    if ('subject' %in% names(df)){
        df$subject <- factor(df$subject)
    }
    if ('elec' %in% names(df)){
        df$elec <- factor(df$elec)
    }
    if ('hem' %in% names(df)){
        df$hem <- factor(df$hem)
    }
    if ('rhythm' %in% names(df)){
        # recode_factor() remaps factor levels, and also changes their order 
        df$rhythm <- recode_factor(df$rhythm, !!!rhythm_label_map)
    }
    if ('task' %in% names(df)){
        df$task <- factor(df$task, levels=c("listen","tap"))
    }
    if ('chang' %in% names(df)){
        df$chang <- factor(df$chang)
    }
    if ('custom' %in% names(df)){
        df$custom <- factor(df$custom)
    }
    if ('desikan_killiany' %in% names(df)){
        df$desikan_killiany <- factor(df$desikan_killiany)
    }
    if ('destrieux' %in% names(df)){
        df$destrieux <- factor(df$destrieux)
    }
    if ('merged' %in% names(df)){
        df$merged <- factor(df$merged)
    }
    if ('pac_desikan_killiany' %in% names(df)){
        df$pac_desikan_killiany <- factor(df$pac_desikan_killiany)
    }
    if ('in_gray' %in% names(df)){
        df$in_gray <- factor(df$in_gray)
    }
    # if ('freq' %in% names(df)){
    #     df$freq <- factor(round(df$freq, 2))
    # }
    return(df)
}


get_lut <- function(atlas='desikan_killiany'){
    if (atlas == 'custom'){
        return(lut_custom)
    } else if (atlas == 'chang'){
        return(lut_chang)
    } else if (atlas == 'merged'){
        return(lut_merged)
    } else {
        return(lut_fs)
    }
}


save_fig <- function(fname, plt, width, height, png=T, pdf=T){
    # strip file extension
    fname <- tools::file_path_sans_ext(fname)
    # save as png
    if (png) ggsave(paste(fname, '.png', sep=''), plt, width=width, height=height, bg='white')
    # save as svg
    if (pdf) ggsave(paste(fname, '.svg', sep=''), plt, width=width, height=height)
}

make_prop_responsive_table <- function(roi_counts){
    df <- roi_counts
    # df$prop_responsive = round(df$n_responsive/df$n_total,2)
    df <- df %>% arrange(desc(n_responsive_both_rhythms))
    old_col_names <- names(df)
    new_col_names <- unlist(lapply(strsplit(old_col_names, '_'), function(s) paste(s, collapse=' ')))
    names(df) <- new_col_names
    ht <- as_hux(df) %>% 
        set_align('left') %>% 
        set_font_size(9) %>%
        set_bottom_padding(0.2) %>%
        set_top_padding(0.2) %>%
        theme_article
    col_width(ht) <- c(1/3, rep((1-1/3)/4, 4))
    # wrap(ht) <- TRUE
    tbl <- ht
    # tbl <- huxtable::as_flextable(ht)
    return(tbl)
}


make_ttests_table <- function(df, caption=''){
    ht <- as_hux(df) %>% 
        set_align('left') %>% 
        set_font_size(11) %>%
        set_bottom_padding(0.2) %>%
        set_top_padding(0.2) %>%
        theme_article %>% 
        huxtable::set_caption(caption)
    # ft <- huxtable::as_flextable(ht)
    # ft <- ft %>% 
    #     set_caption(caption) %>%
    return(ht)
}


signifStars <- function(pvals){
    getSymbol <- function(p){
        if (p<0.001) return('***')
        if (p<0.01) return('**')
        if (p<0.05) return('*') else return('')
    }
    return(sapply(pvals, getSymbol))
}


merge_elec_counts <- function(df_total, dfs_subset, suffixes=c('responsive')){
    # This function merges electrode counts between two datasets. First, it updates the subset dataset
    # so that it also contains '0' for rois that are in the total dataset but haven't been observed. 
    if (class(dfs_subset) != 'list') dfs_subset <- list(dfs_subset)
    if (class(suffixes) != 'list') suffixes <- c(suffixes)
    
    df_merged <- df_total %>% rename(n_total = n)
    
    for (i in 1:length(dfs_subset)){
        df_subset <- dfs_subset[[i]]
        df_subset$roi <- as.character(df_subset$roi)
        for (roi in levels(df_total$roi)){
            if (!roi %in% df_subset$roi){
                df_subset[nrow(df_subset)+1, ] <- c(roi, 0)
            }
        }
        df_subset$roi <- factor(df_subset$roi)
        df_subset$n <- as.numeric(df_subset$n)
        df_subset <- rename_with(df_subset, ~ paste0('n_', suffixes[i]), 'n')
        df_merged <- merge(df_merged, df_subset, by=c('roi'))
    }

    return(df_merged)
}


count_elec_roi <- function(df, atlas){
    df %>% 
        count(.data[[atlas]]) %>% 
        filter(!.data[[atlas]]%in%c('unknown', 'Unknown')) %>% 
        filter(!.data[[atlas]]%in%rois_fs_excl) %>%
        arrange(desc(n))
}


subset_rois_clean <- function(df, atlas='desikan_killiany', min_n=-Inf, 
                              rhythm=NA, task=NA, freq=NA, logic='all'){
    # This function takes a dataframe and subsets the entries (based on atlas), by:
    # 1) Removing ROIs like "Unknown", "White-matter" etc. 
    # 2) Only keeping electrodes that belong to ROIs which have more than min_n electrodes in them. 
    #    This is done by looking across conditions (rhythms, tasks) present in the dataframe and 
    #    taking the minimum number of elecs. Thus, if we have a dataset where responsive elecs were 
    #    selected separately for each rhythm, we only keep ROIs that have more than min_n elecs in 
    #    *each* rhythm. 
    atlas_roi_col <- sprintf('roi_%s',atlas)
    # get counts and trim rois with too little electrodes
    df_counts <- df
    if (!is.na(rhythm)) df_counts <- filter(df_counts, rhythm=={{rhythm}})
    if (!is.na(task)) df_counts <- filter(df_counts, task=={{task}})
    if (!is.na(freq)) df_counts <- filter(df_counts, freq=={{freq}})
    df_counts <- df_counts %>% group_by(rhythm, task) %>% group_modify(~ count_elec_roi(.x, atlas))
    df_counts <- pivot_wider(df_counts, names_from=c(rhythm,task), values_from=n)
    if (logic == 'all'){
        df_counts <- df_counts[complete.cases(df_counts), ]
        min_na_rm <- FALSE        
    } else if (logic == 'any'){
        min_na_rm <- TRUE
    }
    n_conds <- length(names(df_counts))-1
    df_counts$min_n_across_cond <- apply(as.matrix(df_counts[,2:(n_conds+1)]), 1, 
                                         function(x) min(x, na.rm=min_na_rm))
    rois_incl <- df_counts %>% filter(min_n_across_cond >= min_n) %>% select(roi) %>% unlist()
    # subset the dataframe
    df <- df %>% filter(!.data[[atlas_roi_col]]%in%rois_fs_excl & 
                        .data[[atlas_roi_col]]%in%rois_incl)
    df[,atlas_roi_col] <- droplevels(df[,atlas_roi_col])
    return(df)
}


pairwise_contrasts_one_cond <- function(model, var, adjust_method='fdr', return_ci=TRUE){
    
    # calcualte contrast
    emm <- emmeans(model, var)
    c <- contrast(emm, 'pairwise', adjust=adjust_method)
    # get pvalues
    c_pval <- as.data.frame(c)
    c_pval$signif <- stars.pval(c_pval$p.value)
    options(scipen=100)
    c_pval$p.value <- format.pval(c_pval$p.value, digits=2, eps=0.0001)
    # get CIs
    c_ci <- as.data.frame(confint(c, adjust=adjust_method))
    # merge it together
    c_merged <- merge(c_pval, c_ci %>% dplyr::select(contrast,lower.CL,upper.CL), by=c('contrast'))
    c_merged <- c_merged %>% 
        dplyr::select(contrast,estimate,df,t.ratio,lower.CL,upper.CL,p.value,signif) %>%
        mutate_at(c('t.ratio','df'), round, digits=2) %>% 
        mutate_at(c('estimate','lower.CL','upper.CL'), round, digits=3) %>% 
        arrange(contrast)
    if (!return_ci) c_merged <- select(c_merged, -one_of(c('lower.CL','upper.CL')))
    # prepare matrix for plotting
    tmp <- pwpm(emm, means=F, flip=T, reverse=T, adjust=adjust_method, digits=1)
    tmp <- sub("[<>]", "", tmp)
    p_matrix <- matrix(as.numeric((tmp)), 
                   nrow=length(tmp[,1]), 
                   ncol=length(tmp[,1])) 
    rownames(p_matrix) <- colnames(p_matrix) <- colnames(tmp)
    p_matrix[upper.tri(p_matrix, diag=FALSE)] <- NA
    return(list(res=c_merged, p_matrix=p_matrix))
}


pairwise_contrasts_interaction <- function(model, var1, var2, adjust_method='fdr', return_ci=TRUE){
    
    # calcualte contrast
    emm <- emmeans(model, var1, by=var2)
    c <- contrast(emm, 'pairwise', adjust=adjust_method)
    
    # get pvalues
    c_pval <- as.data.frame(c)
    c_pval$signif <- stars.pval(c_pval$p.value)
    c_pval$p.value <- format.pval(c_pval$p.value, digits=1, eps=0.0001)
    # get CIs
    c_ci <- as.data.frame(confint(c, adjust=adjust_method))
    # merge it together
    c_merged <- merge(c_pval,
                      c_ci %>% dplyr::select(contrast,.data[[var2]],lower.CL,upper.CL), 
                      by=c('contrast', 'rhythm'))
    c_merged <- c_merged %>% 
        dplyr::select(contrast,.data[[var2]],estimate,df,t.ratio,lower.CL,upper.CL,p.value,signif) %>%
        mutate_at(c('t.ratio','df'), round, digits=2) %>% 
        mutate_at(c('estimate','lower.CL','upper.CL'), round, digits=3) %>% 
        arrange(.data[[var2]],contrast)
    if (!return_ci) c_merged <- select(c_merged, -one_of(c('lower.CL','upper.CL')))
    # prepare matrix for plotting
    tmp_matrices <- pwpm(emm, means=F, flip=T, reverse=T, adjust=adjust_method, digits=1)
    p_matrices <- lapply(tmp_matrices, function(tmp){
        p_matrix <- matrix(as.numeric((tmp)), 
                           nrow=length(tmp[,1]), 
                           ncol=length(tmp[,1])) 
        rownames(p_matrix) <- colnames(p_matrix) <- colnames(tmp)
        p_matrix[upper.tri(p_matrix, diag=FALSE)] <- NA
        return(p_matrix)
    })
    return(list(res=c_merged, p_matrices=p_matrices))
    
}




