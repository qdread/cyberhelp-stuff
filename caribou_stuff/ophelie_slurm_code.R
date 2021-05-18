getmodelselection <- function(herd){
  #data(finalDF)
  df2 <- finalDF
  colnames(df2)[which(colnames(df2) %in% colnames(df2 %>% dplyr::select(ends_with('early summer'))))] <-
    str_replace(colnames(df2 %>% dplyr::select(ends_with('early summer'))),'early summer','insect')
  colnames(df2)[which(colnames(df2) %in% colnames(df2 %>% dplyr::select(ends_with('late summer'))))] <-
    str_replace(colnames(df2 %>% dplyr::select(ends_with('late summer'))),'late summer','summer')
  colnames(df2)
  df2 <- df2 %>% dplyr::select(!starts_with('tmax') &! starts_with('tmin'))
  getDev <- function(x) x - median(x, na.rm = TRUE)
  df2 <- df2 %>% group_by(herd) %>% mutate(calving.deviation = getDev(calving.day))
  getScaleDF <- function(df, myherd){
    newdf <- droplevels(na.omit(subset(df, herd == myherd)))
    scaled.covars <- as.data.frame(scale(newdf[,c(15:34)]))
    newdf <- droplevels(na.omit(cbind(newdf[,c('ID_Year','ID','herd','Year', 'calving.day', 'calving.deviation')], scaled.covars)))
    return(newdf)
  }
  domodels <- function(df){
    mod <- lme(calving.day ~ tmean_insect + prcp_insect + windspeed_insect +
                 ndays.hightemp_insect + ndays.lowwind_insect +
                 tmean_summer + prcp_summer + windspeed_summer +
                 tmean_fall + prcp_fall + windspeed_fall +
                 tmean_winter + prcp_winter + windspeed_winter +
                 tmean_spring + prcp_spring + windspeed_spring +
                 tmean_migration + prcp_migration + windspeed_migration,
               #(1|ID) + (1|Year),
               data = df, random = list(Year = ~ 1|Year, ID = ~1|ID) ,
               na.action = "na.fail", method = "ML")
    msmod <- dredge(mod)
    return(mod.selection = msmod)
  }
  df.scaled <- getScaleDF(df2, myherd = herd)
  mod.selection <- domodels(df.scaled)
  sel <- subset(mod.selection, delta <= 2)
  save(sel, file=paste0('//nfs/ocouriot-data/parturitions/parturitions_outputs/selection_lme_calving_day2_',herd,'.RData'))
}
library(rslurm)


data(finalDF)
df2 <- finalDF
herd <- levels(df2$herd)
pars <-  data.frame(herd=herd, stringsAsFactors = FALSE)
setwd("//nfs/ocouriot-data/parturitions/parturitions_outputs")
domodels3 <- slurm_apply(getmodelselection, pars, jobname = "test_dredge",
                         pkgs = c("lme4","MuMIn","nlme","stringr","dplyr"), nodes = 8, #cpus_per_node = 2,
                         global_objects = c("finalDF"),
                         processes_per_node = 1, submit=T, slurm_options = list(exclusive="user"))

get_job_status(domodels3)
out <- get_slurm_out(domodels3)
cleanup_files(domodels3)
