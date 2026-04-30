

plot_count_roi <- function(df){
    # Plots number of electrodes in each ROI as barplot
    ggplot(df, aes(roi,n)) + 
        geom_histogram(stat='identity', fill='grey50') + 
        xlab('') + 
        ylab('number of electrodes') + 
        theme_cowplot() + 
        theme(panel.grid.major=element_line(color='grey80',size=0.5), 
              axis.text.x = element_text(angle=60, hjust=1, size=fontsize), 
              axis.text.y = element_text(size=fontsize), 
              axis.title = element_text(size=fontsize), 
              strip.text = element_text(size=fontsize), 
              plot.title = element_text(size=fontsize)) 
}


plt_elecs_set_venn <- function(elec_id_set1, elec_id_set2, set_labels, fontsize=1.5, margin=0.2){
    list_venn <- list(
        elec_id_set1,
        elec_id_set2
    )
    list_venn <- setNames(list_venn, set_labels)
    colors <- RColorBrewer::brewer.pal(8, 'Dark2')[1:2]
    plt <- venn.diagram(list_venn, 
                        fill=colors, 
                        alpha=0.3, 
                        lwd=0, 
                        fontfamily='Helvetica',
                        cex=fontsize,
                        cat.fontfamily='Helvetica',
                        cat.fontface='bold',
                        cat.cex=fontsize,
                        cat.col=colors,
                        filename = NULL, 
                        margin=margin,
                        disable.logging=FALSE)
    return(plt)
}


plot_count_roi_resp <- function(df_all, df_resp, atlas){
    # remove ROIs that have no responsive elecs 
    missing_levels <- setdiff(levels(df_all[,atlas]), levels(df_resp[,atlas]))
    df_all <- df_all %>% 
        filter(.data[[atlas]] %in% levels(df_resp[,atlas])) %>%
        mutate(!!atlas := fct_drop(.data[[atlas]], only = missing_levels))
    
    bar_width <- 0.8
    cmap <- lut_all[levels(df_all[,atlas])]
    
    plt <- ggplot(data=df_all, aes(y=n)) + 
        geom_bar(data=df_all, aes(x=.data[[atlas]]), stat='identity', width=bar_width, fill='grey50') + 
        geom_bar(data=df_resp, aes(x=.data[[atlas]], fill=.data[[atlas]]), stat='identity', width=bar_width)  
        
    plt <- plt + 
        xlab('') + 
        ylab('number of electrodes') + 
        theme_cowplot() + 
        scale_fill_manual(name='', values=cmap) + 
        theme(axis.text.x = element_text(angle=60, hjust=1, size=fontsize, color=cmap),
              axis.text.y = element_text(size=fontsize), 
              axis.title = element_text(size=fontsize), 
              strip.text = element_text(size=fontsize), 
              plot.title = element_text(size=fontsize)) 
    return(plt)
}



plot_count_comarison_roi <- function(df, columns=c('n_responsive_unsync', 'n_responsive_sync')){
    df <- pivot_longer(df, !roi, values_to='count', names_to='type')
    cols <- setNames(c(list('grey50'), RColorBrewer::brewer.pal(8, 'Dark2')[1:length(columns)]), 
                     c(list('n_total'), columns))
    main_bar_with <- 0.8
    bar_width <- main_bar_with/length(columns)
    pd <- main_bar_with/2 - (bar_width/2 + bar_width * c(0:(length(columns)-1)))
    
    plt <- ggplot(data=df, aes(y=count)) + 
        geom_bar(data=filter(df, type=='n_total'), aes(x=roi, fill='n_total'), 
                 stat='identity', width=main_bar_with) 
    
    for (i in c(1:length(columns))){
        current_column <- columns[i]
        current_pd <- pd[i]
        plt <- plt + 
            geom_bar(data=filter(df, type==!!current_column), 
                     aes(x=as.numeric(roi)-!!current_pd, fill=!!current_column), 
                     stat='identity', width=bar_width)
    }
    plt <- plt + 
        xlab('') + 
        ylab('number of electrodes') + 
        theme_cowplot() + 
        scale_fill_manual(name='', values=cols) + 
        theme(panel.grid.major=element_line(color='grey80',linewidth=0.5), 
              axis.text.x = element_text(angle=60, hjust=1, size=fontsize,
                                         color=lut_all[levels(df$roi)]), 
              axis.text.y = element_text(size=fontsize), 
              axis.title = element_text(size=fontsize), 
              strip.text = element_text(size=fontsize), 
              plot.title = element_text(size=fontsize)) 
    return(plt)
}


plot_feature_compare_tasks <- function(df, feature_name, atlas=NA, maxYLim=NA, plot_zero_line=T){
    # This function plots a comparison of some feature between listening and tapping, 
    # separately for each rhythm and roi. 
    fontsize <- 14
    dodge_point <- 0.3
    cols <- c("listen"="grey50",
              "tap"="black")
    
    if (is.na(atlas)){
        plt <- ggplot(data=df, aes(task, .data[[feature_name]])) 
        if (plot_zero_line){
            plt <- plt + 
                geom_hline(yintercept=0, col='red', linetype='solid', size=0.6)
        }
        plt <- plt + 
            geom_line(aes(group=interaction(rhythm, subject, elec)), 
                      alpha=0.5, color='grey70') + 
            geom_point(data=filter(df,task=='listen'), aes(col='listen')) + 
            geom_point(data=filter(df,task=='tap'), aes(col='tap')) + 
            facet_wrap(~rhythm, nrow=2) 
    } else {
        df_z_meter_ttest_task <- ttest_task_per_roi(df, var_name=feature_name, atlas=atlas, format_pvals=F)
        df_pval <- filter(df_z_meter_ttest_task, p<0.05)
        df_pval$label <- format.pval(df_pval$p, digits=1)
        df_pval$y.position <- 1.2
        df_pval$group1 <- 'listen'
        df_pval$group2 <- 'tap'
        
        atlas_roi_col <- sprintf('roi_%s',atlas)
        df$x <- as.numeric(df[,atlas_roi_col])
        df$x_point <- ifelse(df$task=='listen',
                             df$x-dodge_point, 
                             df$x+dodge_point)

        plt <- ggplot(data=df, aes(x_point, .data[[feature_name]])) 
        if (plot_zero_line){
            plt <- plt + 
                geom_hline(yintercept=0, col='red', linetype='solid', size=0.6)
        }
        plt <- plt + 
            geom_line(aes(group=interaction(.data[[atlas_roi_col]], rhythm, subject, elec)), 
                      alpha=0.5, color='grey70') + 
            geom_point(data=filter(df,task=='listen'), aes(col='listen')) + 
            geom_point(data=filter(df,task=='tap'),aes(col='tap')) + 
            facet_wrap(~rhythm, nrow=2)  + 
            scale_x_continuous(name=NULL, breaks=c(1:length(levels(df[,atlas_roi_col]))), 
                               labels=levels(df[,atlas_roi_col])) 
    }
    plt <- plt + 
    scale_y_continuous(limits = c(NA,maxYLim)) + 
    scale_colour_manual(name="task", values=cols) +
    theme_cowplot() + 
    theme(axis.text.x = element_text(angle=60, hjust=1, size=fontsize), 
          axis.text.y = element_text(size=fontsize), 
          axis.title = element_text(size=fontsize), 
          strip.text = element_text(size=fontsize),
          axis.line.x = element_blank(), 
          axis.ticks.x = element_blank()
          ) 
    return(plt)
}



plot_feature_task_diff <- function(df, feature_name, atlas=NA, score_type='absolute', ttest=TRUE,  
                                   adjust_method='fdr', maxYLim=NA, pnt_col='lut'){
    # This function plots the difference score  for some feature. 
    # If score_type = 'absolute': [listen]-[tap]
    # If score_type = 'ratio': [listen]/[tap]
    # If score_type = 'contrast': [listen]-[tap] / [listen]+[tap]
    # If atlas is passed, each ROI is plotted separately. If no atlas is passed, all electrodes in the 
    # dataframe are merged together. 
    # In addition, a t-test against 0 can be calculated and significance stars plotted. 
    fontsize <- 14
    pd <- position_jitter(width=0.1)
    
    if (score_type == 'absolute'){
        feature_name_diff <- paste(feature_name, 'diff', sep='_')
        get_scores <- function(x_listen, x_tap) x_tap - x_listen
        mu <- 0
    }
    if (score_type == 'ratio'){
        feature_name_diff <- paste(feature_name, 'ratio', sep='_')
        get_scores <- function(x_listen, x_tap) x_tap / x_listen
        mu <- 1
    }
    if (score_type == 'contrast'){
        feature_name_diff <- paste(feature_name, 'contrast', sep='_')
        get_scores <- function(x_listen, x_tap) (x_tap - x_listen) / (x_tap + x_listen)
        mu <- 0
    }    
    
    # no atlas passed, merge all electrodes found in the dataframe
    if (is.na(atlas)){
        df_wide <- df %>% 
            group_by(rhythm) %>% 
            group_modify(~ get_wide_df_task(.x, feature_name))
        df_wide[, feature_name_diff] <- get_scores(df_wide$listen, df_wide$tap)
        df_summary <- summarySE(df_wide, groupvars='rhythm', measurevar=feature_name_diff)
        
        plt <- ggplot(data=df_wide, aes(x=0, y=.data[[feature_name_diff]])) + 
            geom_hline(yintercept=mu, col='red', linetype='solid', size=0.5) + 
            geom_point(position=pd, color='grey70', alpha=0.6) + 
            scale_x_continuous(breaks=c(), name='', limits=c(-1, 1))
        
        if (ttest){
            df_pval <- df_wide %>% 
                group_by(rhythm) %>%
                t_test(as.formula(sprintf('%s ~ 1', feature_name_diff)), mu=mu) %>%
                adjust_pvalue(method=adjust_method) %>%
                mutate(p.adj.signif=stars.pval(.data[['p.adj']]))%>% 
                add_y_position()
            plt <- plt + 
                geom_text(data=df_pval, inherit.aes=FALSE, x=0, 
                          aes(y=y.position, label=p.adj.signif), color='black', size=5)
        }

    # atlas available, analyse each ROI separately
    } else {
        atlas_col <- sprintf('roi_%s', atlas)
        df_wide <- df %>% 
            group_by(rhythm, .data[[atlas_col]]) %>% 
            group_modify(~ get_wide_df_task(.x, feature_name))
        df_wide[, feature_name_diff] <- get_scores(df_wide$listen, df_wide$tap)
        df_summary <- summarySE(df_wide, groupvars=c('rhythm', atlas_col), measurevar=feature_name_diff)        
        
        plt <- ggplot(data=df_wide, aes(x=.data[[atlas_col]], y=.data[[feature_name_diff]])) + 
            geom_hline(yintercept=mu, col='red', linetype='solid', size=0.5) 
        if (pnt_col == 'lut'){
            lut <- get_lut(atlas)
            lut <- lut[as.character(unique(df[, atlas_col]))]
            plt <- plt + 
                geom_point(aes(color=.data[[atlas_col]]), position=pd, alpha=0.3) + 
                scale_color_manual(values=lut)
        } else {
            plt <- plt + geom_point(position=pd, color='grey70', alpha=0.6)
        }

        if (ttest){
            df_pval <- df_wide %>% 
                group_by(rhythm, .data[[atlas_col]]) %>%
                t_test(as.formula(sprintf('%s ~ 1', feature_name_diff)), mu=mu) %>%
                adjust_pvalue(method=adjust_method) %>%
                mutate(p.adj.signif=stars.pval(.data[['p.adj']]))%>% 
                add_y_position()
            plt <- plt + 
                geom_text(data=df_pval, inherit.aes=FALSE, color='black', size=6, fontface='bold',
                          aes(x=.data[[atlas_col]], y=y.position, label=p.adj.signif))
        }
        
    }
    plt <- plt + 
        geom_point(data=df_summary, color='black',  shape=95, size=5, stroke=10) + 
        geom_errorbar(data=df_summary, aes(ymin=.data[[feature_name_diff]]-ci,
                                           ymax=.data[[feature_name_diff]]+ci), 
                      color='black', size=0.8, width=0) + 
        facet_wrap(~rhythm, nrow=2) +
        scale_y_continuous(limits = c(NA,maxYLim)) + 
        theme_cowplot() + 
        theme(axis.text.x = element_text(angle=60, hjust=1, size=fontsize), 
              axis.text.y = element_text(size=fontsize), 
              axis.title = element_text(size=fontsize), 
              strip.text = element_text(size=fontsize),
              axis.line.x = element_blank(), 
              axis.ticks.x = element_blank(),
              legend.position = 'none'
        ) 
    return(plt)
}


plot_phase <- function(df, freq=5, task='listen', rhythm='all', atlas='chang'){
    # This function plots the phase for a particular frequency, task and rhythm, separately for each ROI. 
    # subset task 
    df <- df[df$task %in% task, ]
    # frequency of interest
    df <- df[df$freq == freq, ]
    # subset rhythm (if requested )
    if (rhythm!='all') df <- df[df$rhythm %in% rhythm, ]
    atlas_col_name <- sprintf('roi_%s',atlas)
    n_rois <- length(unique(df[, atlas_col_name]))
    if (n_rois<7) {
        fontsize <- 14
        pointsize <- 3
        linewidth <- 1.2
        strip_text_angle <- 0
    } else {
        fontsize <- 12
        pointsize <- 1.7
        linewidth <- 1
        strip_text_angle <- 60
    }
    # get mean vector
    df_mean_vec = ddply(df, c('rhythm', 'task', atlas_col_name), get_mean_vec)
    # make sure the angles are from 0 to 2pi
    df$phase = df$phase %% (2*pi)
    df_mean_vec$theta = df_mean_vec$theta %% (2*pi)
    # order ROIs factor by mean angle for visualization
    rhythm_to_order <- ifelse(rhythm=='all', 'syncopated', rhythm)
    roi_order <- df_mean_vec %>% filter(rhythm == rhythm_to_order) %>% arrange(theta) %>% 
        select(.data[[atlas_col_name]]) %>% unlist()
    df[, atlas_col_name] <- factor(df[, atlas_col_name], levels=roi_order)
    # plot
    plt <- ggplot(df) +
        geom_hline(yintercept=1, color='gray60') +
        geom_vline(xintercept = c(0, pi/2, pi, 3*pi/2), color='gray60') +
        geom_point(aes(x=phase, y=1), alpha=0.5, color='#8080FF', size=pointsize) + 
        geom_segment(data=df_mean_vec, 
                     aes(x=theta%%(2*pi), xend=theta%%(2*pi), y=0, yend=r), 
                     color='red', size=linewidth) + 
        scale_x_continuous(limits=c(0,2*pi),
                           breaks = c(0, pi/2, pi, 3*pi/2),
                           labels = c('0',
                                      expression(paste(pi,'/2')),
                                      expression(pi),
                                      expression(paste('-',pi,'/2'))),
                           expand=c(0,0) ) +
        scale_y_continuous(limits=c(0, 1.3)) +
        coord_polar(start=-pi/2, direction=-1) +
        theme_bw() +
        theme(
            panel.border = element_blank(),
            strip.text.x = element_text(angle=strip_text_angle, size=fontsize),
            strip.text.y = element_text(size=fontsize),
            strip.background = element_blank(),
            axis.title = element_blank(),
            axis.ticks = element_blank(),
            axis.text.x = element_text(size=fontsize, color='gray60'),
            axis.text.y = element_blank(),
            panel.grid = element_blank()
        ) + 
        facet_grid(as.formula(sprintf('rhythm ~ %s', atlas_col_name)))
    return(plt)
}

    
plot_feature <- function(df, feature_name, task='listen', rhythm='all', atlas='chang', y_lims=c(NA,NA),
                         plot_summary=TRUE, hline_spec=NULL, hline_zero=FALSE, dodge_width=0.1, pntsize_ind=1, 
                         pntalpha_ind=0.4, pnt_col='grey70', pnt_col_mean='black', hline_col='red', show_labels=TRUE, 
                         edgehighligh_name=NA, fontsize=12, pntsize_mean=2, size_err=0.7, width_err=0){
    # This function plots some feature for a particular task, separately for each ROI. 
    
    # subset task 
    df <- df[df$task %in% task, ]
    # subset rhythm (if requested )
    if (rhythm!='all') df <- df[df$rhythm %in% rhythm, ]
    
    atlas_roi_col <- sprintf('%s',atlas)
    n_rois <- length(unique(df[,atlas_roi_col]))
    if (plot_summary) df_summary <- summarySE(df, measurevar=feature_name, 
                                              groupvars=c('rhythm',atlas_roi_col))

    pd <- position_jitter(width=dodge_width)
    plt <- ggplot(data=df, aes(.data[[atlas_roi_col]], .data[[feature_name]])) 
    
    # plot horizontal lines
    if (hline_zero){
        plt <- plt + geom_hline(yintercept=0, col='black', size=0.5) 
    }
    if (is.numeric(hline_spec)){
        plt <- plt + geom_hline(yintercept=hline_spec, col=hline_col, size=0.5) 
    }
    if (is.character(hline_spec)){
        plt <- plt + geom_hline(aes(yintercept=.data[[hline_spec]]), col=hline_col, size=0.5) 
    }
    
    # plot individual points 
    if (pnt_col == 'lut'){
        lut <- lut_all[as.character(unique(df[, atlas_roi_col]))]
        if (is.na(edgehighligh_name)) {
            if (is.character(pntsize_ind)){
                plt <- plt + 
                    geom_point(aes(fill=.data[[atlas_roi_col]], size=.data[[pntsize_ind]]), shape=21,
                               position=pd, alpha=pntalpha_ind, stroke=0)      
            } else {
                plt <- plt + 
                    geom_point(aes(fill=.data[[atlas_roi_col]]), size=pntsize_ind, shape=21,
                               position=pd, alpha=pntalpha_ind, stroke=0)      
            }
     
        } else {
            df_false <- filter(df, .data[[edgehighligh_name]] == FALSE)
            df_true <- filter(df, .data[[edgehighligh_name]] == TRUE)
            if (is.character(pntsize_ind)){
                plt <- plt + 
                    geom_point(data=df_false, 
                               aes(fill=.data[[atlas_roi_col]], color=.data[[atlas_roi_col]], size=.data[[pntsize_ind]]), 
                               shape=21, position=pd, alpha=pntalpha_ind, stroke=0)              
                plt <- plt + 
                    geom_point(data=df_true, color='black', 
                               aes(fill=.data[[atlas_roi_col]], size=.data[[pntsize_ind]]), shape=21,
                               position=pd, alpha=pntalpha_ind, stroke=1)     
            } else {
                plt <- plt + 
                    geom_point(data=df_false, 
                               aes(fill=.data[[atlas_roi_col]], color=.data[[atlas_roi_col]]), 
                               size=pntsize_ind, shape=21, position=pd, alpha=pntalpha_ind, stroke=0)              
                plt <- plt + 
                    geom_point(data=df_true, color='black', 
                               aes(fill=.data[[atlas_roi_col]]), size=pntsize_ind, shape=21,
                               position=pd, alpha=pntalpha_ind, stroke=1)      
             }
        }
        plt <- plt + 
            scale_color_manual(values=lut) +
            scale_fill_manual(values=lut)
    } else {
        plt <- plt + 
            geom_point(col=pnt_col, size=pntsize_ind, position=pd, alpha=pntalpha_ind) 
    }
    
    # plot mean +- CI 
    if (plot_summary){
        if (pnt_col_mean == 'lut'){
            lut <- lut_all[as.character(unique(df[, atlas_roi_col]))]
            plt <- plt + 
                geom_point(data=df_summary, aes(color=.data[[atlas_roi_col]]), size=pntsize_mean) + 
                geom_errorbar(data=df_summary, 
                              aes(ymin=.data[[feature_name]]-ci, ymax=.data[[feature_name]]+ci, 
                                  color=.data[[atlas_roi_col]]), 
                              width=width_err, size=size_err) 
        } else {
            plt <- plt + 
                geom_point(data=df_summary, color=pnt_col_mean, size=pntsize_mean) + 
                geom_errorbar(data=df_summary, 
                              aes(ymin=.data[[feature_name]]-ci, ymax=.data[[feature_name]]+ci), 
                              color=pnt_col_mean, width=width_err, size=size_err) 
        }
    }
    
    # format the plot
    plt <- plt + 
        facet_wrap(~rhythm, nrow=2)  +  
        scale_y_continuous(limits=y_lims) + 
        theme_cowplot() 
    
    if (show_labels) {
        plt <- plt + 
            theme(axis.text.x = element_text(angle=60, hjust=1, size=fontsize),
                  axis.text.y = element_text(size=fontsize, family='Helvetica'), 
                  axis.title.x = element_blank(), 
                  axis.title.y = element_text(size=fontsize, family='Helvetica'), 
                  strip.text = element_text(size=fontsize, family='Helvetica'),
                  axis.line.x = element_blank(), 
                  axis.ticks.x = element_blank(),
                  legend.position = 'none', 
                  plot.margin = margin(b=50)
            ) 
    } else {
        plt <- plt + 
            theme(axis.text.x = element_blank(), 
                  axis.text.y = element_text(size=fontsize, family='Helvetica'), 
                  axis.title.x = element_blank(), 
                  axis.title.y = element_blank(), 
                  strip.text = element_blank(), 
                  axis.line.x = element_blank(), 
                  axis.ticks.x = element_blank(),
                  legend.position = 'none'
            ) 
    }
    
    
}


plot_feature_violin <- function(df, var_name, atlas, add_violin=FALSE, do_trim=TRUE){
    
    pnt_size_ind = 1
    pnt_size_mean = 2
    errbar_size = 0.7
    errbar_width = 0.1
    dodge_rois = 4
    jit_point = 0.2
    dodge_viol = -0.6
    dodge_errbar = 0.05
    # prepare the data
    df$y <- df[,var_name]
    # create x positions
    atlas_roi_col <- sprintf('roi_%s',atlas)
    df[,atlas_roi_col] <- as.factor(df[,atlas_roi_col])
    rois <- levels(df[,atlas_roi_col])
    df$x = (as.numeric(df[,atlas_roi_col])-1) * dodge_rois
    df$x_point <- jitter(df$x, amount=jit_point)
    # make summary with means and CIs 
    df_summary <- summarySE(data=df, measurevar='y', groupvars=c('rhythm', 'task', atlas_roi_col))
    df_summary$x = (as.numeric(as.factor(df_summary[,atlas_roi_col]))-1) * dodge_rois
    plt <- ggplot(data=df) + 
        # geom_point(aes(x=x_point, y=y), color='grey60', alpha=0.5, size=pnt_size_ind, show.legend=FALSE) + 
        geom_quasirandom(aes(x=x, y=y), color='grey60', alpha=0.7, size=pnt_size_ind, show.legend=FALSE, 
                         position=position_nudge(x=dodge_point), width=0.5) + 
        facet_wrap(~ rhythm, nrow=2) + 
        theme_cowplot() + 
        scale_x_continuous(name=NULL, breaks=seq(0,length(rois)-1)*dodge_rois, labels=rois) + 
        theme(axis.line.x = element_blank(), 
              axis.ticks.x = element_blank(), 
              axis.line.y = element_line(size=0.5))
    
    if (add_violin){
        plt <- plt + 
            geom_half_violin(data=df, aes(x=x, y=y, group=.data[[atlas_roi_col]]), 
                         fill='red', color=NA, alpha=0.6, position=position_nudge(x=dodge_viol), 
                         side='l', trim=do_trim) +
            geom_point(data=df_summary, aes(x=x, y=y, group=.data[[atlas_roi_col]]), 
                       position=position_nudge(x=dodge_viol), col='black', size=pnt_size_mean) + 
            geom_errorbar(data=df_summary, aes(x, ymin=y-ci, ymax=y+ci, group=.data[[atlas_roi_col]]), 
                          position=position_nudge(x=dodge_viol), width=errbar_width, size=errbar_size)
    } else {
        plt <- plt + 
            geom_point(data=df_summary, aes(x=x, y=y, group=.data[[atlas_roi_col]]), 
                       col='black', size=pnt_size_mean) + 
            geom_errorbar(data=df_summary, aes(x, ymin=y-ci, ymax=y+ci, group=.data[[atlas_roi_col]]), 
                          width=errbar_width, size=errbar_size)
    }
    return(plt)
}


plot_feature_swarm <- function(df, var_name, atlas){
    
    pnt_size_ind = 1
    pnt_size_mean = 2
    errbar_size = 0.7
    errbar_width = 0.1
    dodge_rois = 3
    # prepare the data
    df$y <- df[,var_name]
    # create x positions
    atlas_roi_col <- sprintf('roi_%s',atlas)
    df[,atlas_roi_col] <- as.factor(df[,atlas_roi_col])
    rois <- levels(df[,atlas_roi_col])
    df$x = (as.numeric(df[,atlas_roi_col])-1) * dodge_rois
    # make summary with means and CIs 
    df_summary <- summarySE(data=df, measurevar='y', groupvars=c('rhythm', 'task', atlas_roi_col))
    df_summary$x = (as.numeric(as.factor(df_summary[,atlas_roi_col]))-1) * dodge_rois
    plt <- ggplot(data=df, aes(x=x, y=y)) + 
        geom_quasirandom(color='grey60', alpha=0.7, size=pnt_size_ind, width=0.5, 
                         show.legend=FALSE) + 
        geom_point(data=df_summary, aes(group=.data[[atlas_roi_col]]), 
                   col='black', size=pnt_size_mean) + 
        geom_errorbar(data=df_summary, aes(ymin=y-ci, ymax=y+ci, group=.data[[atlas_roi_col]]), 
                      width=errbar_width, size=errbar_size) + 
        facet_wrap(~ rhythm, nrow=2) + 
        theme_cowplot() + 
        scale_x_continuous(name=NULL, breaks=seq(0,length(rois)-1)*dodge_rois,
                           labels=rois) + 
        ylab(var_name) + 
        theme(axis.line.x = element_blank(), 
              axis.ticks.x = element_blank(), 
              axis.line.y = element_line(size=0.5))
    return(plt)
}



plot_pairwise_matrix <- function(p_matrix){
    # This function plots matrix with pvalues corresponding to pairwise comparisons between conditions. 
    df <- as.data.frame.table(p_matrix)
    names(df)[3] <- 'p'
    df$p_text <- format.pval(df$p, digits=3, eps=1e-1)
    df$p_text[df$p_text=='NA'] <- NA
    fontsize <- ifelse(length(unique(df$Var2)) > 9, 3, 6)
    df %>%
        ggplot(aes(Var1, Var2, fill=p)) + 
        geom_tile(color='white', lwd=0.1, linetype=1) +
        geom_text(aes(label=p_text), size=fontsize) + 
        scale_fill_gradient2(mid="red", limit=c(0,0.05),name="p") + 
        theme_cowplot() + 
        theme(
            axis.title = element_blank(), 
            axis.text.x = element_text(angle=60, hjust=1)
        )  + 
        coord_fixed()
}


plot_marginal_distribution <- function(df, var, color, alpha=0.5, bins=30) {
    ggplot(df, aes(x=.data[[var]])) +
        geom_histogram(bins=bins, fill=color, alpha=alpha, position="identity") +
        # geom_density(alpha=alpha, size = 0.1, fill=color, color=NA) +
        guides(fill='none') +
        theme_void() +
        theme(plot.margin = margin())
}


plot_correlation_scatter <- function(df, var_x, var_y, corr_result=NULL, color='#358ab8'){
    
    label_pos_x <- max(df[,var_x])
    label_pos_y <- max(df[,var_y])
    if (is.null(corr_result)) {
        label_text <- ''
    } else {
        corr_method <- corr_result$method
        if (corr_method == "Spearman's rank correlation rho") corr_symbol <- 'rho'
        if (corr_method == "Kendall's rank correlation tau") corr_symbol <- 'tau'
        if (corr_method == "Pearson's product-moment correlation") corr_symbol <- 'r'
        label_text <- sprintf('%s=%.2f (p=%.3f)', 
                              corr_symbol, corr_result$estimate, corr_result$p.value)
    }
    # prepare scatterplot of the two variables
    scatterplot <- ggplot(df, aes(.data[[var_x]], .data[[var_y]])) + 
        geom_point(shape=21, size=1.5, col=color) + 
        # scale_color_manual(values=col_generator) + 
        annotate('text', x=label_pos_x, y=label_pos_y, label=label_text, hjust='right') + 
        theme_cowplot() 
    # prepare marginal histograms
    x_hist <- plot_marginal_distribution(df, var_x, color, alpha=0.8)
    y_hist <- plot_marginal_distribution(df, var_y, color, alpha=0.8) + coord_flip()
    # align histograms with scatterplot
    aligned_x_hist <- align_plots(x_hist, scatterplot, align = "v")[[1]]
    aligned_y_hist <- align_plots(y_hist, scatterplot, align = "h")[[1]]
    # arrange plots
    plt <- plot_grid(
        aligned_x_hist, 
        NULL, 
        scatterplot,
        aligned_y_hist,
        ncol=2,
        nrow=2,
        rel_heights=c(0.2, 1),
        rel_widths=c(1, 0.2)
    )
    return(plt)
}



FIG_magnMean_task <- function(){
    
    df_pval <- filter(df_magn_mean_ttest_task, p<0.05)
    df_pval$label <- format.pval(df_pval$p, digits=1)
    df_pval$y.position <- 3
    df_pval$group1 <- 'listen'
    df_pval$group2 <- 'tap'
    
    ggplot(df_magn_mean, aes(task, magnitude_eeg, group=interaction(subject,rhythm,roi))) + 
        geom_hline(yintercept = 0, color='red', linetype='dashed') + 
        geom_point() + 
        geom_line() + 
        facet_grid(rhythm~roi) + 
        scale_y_continuous(breaks=c(0,3), name='mean magnitude', limits=c(NA,NA)) + 
        xlab('') + 
        theme_cowplot() + 
        theme(
            axis.line.x = element_blank(), 
            axis.ticks.x = element_blank(), 
            axis.text = element_text(color='black', size=14), 
            axis.title = element_text(color='black', size=fontsize), 
            strip.text = element_text(color='black', size=fontsize), 
            strip.background = element_blank(), 
            strip.text.x = element_text(color='black', size=fontsize, face='bold', margin=margin(0,0,20,0)), 
        )  + 
        add_pvalue(df_pval, color='blue')
    
}


FIG_zMeterRel_task <- function(){
    
    df_pval <- filter(df_z_meter_ttest_task, p<0.05)
    df_pval$label <- format.pval(df_pval$p, digits=1)
    df_pval$y.position <- 1.2
    df_pval$group1 <- 'listen'
    df_pval$group2 <- 'tap'
    
    ggplot(df_z_meter, aes(task, zscore_eeg, group=interaction(subject,rhythm,roi))) + 
        geom_hline(yintercept = 0, color='red', linetype='dashed') + 
        geom_hline(aes(yintercept=zscore_coch), color='grey70', size=3, alpha=0.6) + 
        geom_point() + 
        geom_line() + 
        facet_grid(rhythm~roi) + 
        scale_y_continuous(breaks=c(0,1), name='meter-rel zscore', limits=c(NA,1.3)) + 
        xlab('') + 
        theme_cowplot() + 
        theme(
            axis.line.x = element_blank(), 
            axis.ticks.x = element_blank(), 
            axis.text = element_text(color='black', size=14), 
            axis.title = element_text(color='black', size=fontsize), 
            strip.text = element_text(color='black', size=fontsize), 
            strip.background = element_blank(), 
            strip.text.x = element_text(color='black', size=fontsize, face='bold', margin=margin(0,0,20,0)), 
        )  + 
        geom_text(data=df_z_meter_ttest_coch, inherit.aes=FALSE, aes(x=task, label=signif), y=1.1, color='blue', size=7) + 
        add_pvalue(df_pval, color='blue')
        
}







