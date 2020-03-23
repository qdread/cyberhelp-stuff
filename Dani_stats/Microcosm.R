# Notes: The data are from microcosm experiments I conducted where I exposed an agricultural 
# soil to 8 different aqueous salt treatments (DIW is deionized water control) under
# micro-aerophilic (O2) and anaerobic (No O2) conditions. I measured variables
# (PO4-P, NH4-N, NO3-N, DCB extractable iron, Oxalate extractable iron, hydroxylamine
# extractable iron (total dissolved iron)) from either the soil or the overlying aqueous solution
# at 0, 15, and 30 days. Concentration data were scaled to mg per g of dry soil. The experiment
# was blocked by Rep because each rep (4 total) was set up at a different time. The goal
# of the experiment was to simulate saltwater intrusion on a farm field and to determine
# how different ionic constituents of seawater and their combinations affect the levels of
# these variables.

# I imported and plotted the data for each variable below and created summary stats and a plot
# Scroll to the end where it says "Data transformations and linear regression" to take a
# look at how I approached transforming the data and developing a regression model for PO4.


#=====load packages====
library(readxl) # read in Excel files
library(readr) # read .csv files
library(Hmisc) # correlation tests, careful of masked packages
library(tidyverse) # keep ya data clean
library(stats) # stats!
library(lubridate) # handle dates
library(zoo) # date time manipulation stuff
library(viridis)
library(ggformula)
library(scales)
library(MASS)      # for box cox transformation
library(arm)       # for std coeffs
library(lme4)      # for Linear Mixed-Effects Models using Eigen and S4
library(nlme)      # for Linear and Nonlinear Mixed Effects Models
library(car)       # for correlation scatterplot
library(multcomp)  # for post-hoc tests

setwd("C:/Users/Dani/Desktop/Microcosm paper")
#=====PO4 summ stats and plot=====
PO4 <- read_excel("PO4_microcosms_final.xlsx", 
                  sheet = "All", col_types = c("blank", 
                                               "blank", "text", "blank", "blank", 
                                               "blank", "blank", "numeric", "numeric", 
                                               "numeric", "text", "blank", "blank", 
                                               "blank", "numeric"))



PO4_summ <- PO4 %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(final.conc), sd = sd(final.conc), sem = sd(final.conc)/sqrt(length(final.conc))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2")))
write.csv(PO4_summ, file="PO4summ.csv")

PO4_plot <- ggplot(PO4_summ, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
    ylab(expression(bold(paste(PO[4], "-P ", "(mg", " ", l^-1, ")", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#6495ED", "#B5651D"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.05, 0.8),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(PO4_plot)

# plot area 5" x 15"

PO4_summ_adj <- PO4 %>%
  mutate(Trt. = factor(Trt., levels = c("DIW", "CaSO4", "Na2SO4", "NaCl", "NaCl + CaSO4",
                                        "NaCl + Na2SO4", "NaCl + Na2SO4 + CaSO4", "Inst. Ocean"))) %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(mg.per.g.dry.soil), sd = sd(mg.per.g.dry.soil), sem = sd(mg.per.g.dry.soil)/sqrt(length(mg.per.g.dry.soil))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2"))) %>%
  mutate(mean = replace(mean, mean <=0, 0.00001))
write.csv(PO4_summ_adj, file = "PO4summ_adj.csv")

# plot area 5" x 15"

PO4_plot_adj <- ggplot(PO4_summ_adj, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
  ylab(expression(bold(paste(PO[4], "-P ", "(mg", " ", g^-1," dry soil)", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#6495ED", "#B5651D"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.05, 0.8),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(PO4_plot_adj)

# plot area 5" x 15"

#=====NH4 summ stats and plot====
NH4 <- read_excel("NO3_NH4_microcosms_final.xlsx", 
                  sheet = "NH4", col_types = c("blank", 
                                               "text", "numeric", "numeric", "numeric", 
                                               "text", "text", "numeric", "numeric", 
                                               "numeric", "numeric"))


NH4_summ <- NH4 %>%
  mutate(Trt. = factor(Trt., levels = c("DIW", "CaSO4", "Na2SO4", "NaCl", "NaCl + CaSO4",
                                        "NaCl + Na2SO4", "NaCl + Na2SO4 + CaSO4", "Inst. Ocean"))) %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(conc.mg.l), sd = sd(conc.mg.l), sem = sd(conc.mg.l)/sqrt(length(conc.mg.l))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2"))) %>%
  mutate(mean = replace(mean, mean <=0, 0.00001))
write.csv(NH4_summ, file = "NH4summ.csv")

NH4_plot <- ggplot(NH4_summ, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
  ylab(expression(bold(paste(NH[4], "-N ", "(mg", " ", l^-1, ")", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#6495ED", "#B5651D"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.05, 0.8),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(NH4_plot)

# plot area 5" x 15"

NH4_summ_adj <- NH4 %>%
  mutate(Trt. = factor(Trt., levels = c("DIW", "CaSO4", "Na2SO4", "NaCl", "NaCl + CaSO4",
                                        "NaCl + Na2SO4", "NaCl + Na2SO4 + CaSO4", "Inst. Ocean"))) %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(mg.per.g.dry.soil), sd = sd(mg.per.g.dry.soil), sem = sd(mg.per.g.dry.soil)/sqrt(length(mg.per.g.dry.soil))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2"))) %>%
  mutate(mean = replace(mean, mean <=0, 0.00001))
write.csv(NH4_summ_adj, file = "NH4summ_adj.csv")

# plot area 5" x 15"

NH4_plot_adj <- ggplot(NH4_summ_adj, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
  ylab(expression(bold(paste(NH[4], "-N ", "(mg", " ", g^-1," dry soil)", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#6495ED", "#B5651D"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.05, 0.8),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(NH4_plot_adj)

# plot area 5" x 15"

#======NO3 summ stats and plot======
NO3 <- read_excel("NO3_NH4_microcosms_final.xlsx", 
           sheet = "NO3", col_types = c("blank", 
                                        "text", "numeric", "numeric", "numeric", 
                                        "text", "text", "numeric", "numeric", 
                                        "numeric", "numeric"))



NO3_summ <- NO3 %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(conc.mg.l), sd = sd(conc.mg.l), sem = sd(conc.mg.l)/sqrt(length(conc.mg.l))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2"))) %>%
  mutate(mean = replace(mean, mean <=0, 0.00001))
write.csv(NO3_summ, file = "NO3summ.csv")

NO3_summ_adj <- NO3 %>%
  mutate(Trt. = factor(Trt., levels = c("DIW", "CaSO4", "Na2SO4", "NaCl", "NaCl + CaSO4",
                                        "NaCl + Na2SO4", "NaCl + Na2SO4 + CaSO4", "Inst. Ocean"))) %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(mg.per.g.dry.soil), sd = sd(mg.per.g.dry.soil), sem = sd(mg.per.g.dry.soil)/sqrt(length(mg.per.g.dry.soil))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2"))) %>%
  mutate(mean = replace(mean, mean <=0, 0.00001))
write.csv(NO3_summ_adj, file = "NO3summ_adj.csv")

NO3_plot <- ggplot(NO3_summ, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
  ylab(expression(bold(paste(NO[3], "-N ", "(mg", " ", l^-1, ")", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#6495ED", "#B5651D"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.05, 0.8),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(NO3_plot)

# plot area 5" x 15"

NO3_plot_adj <- ggplot(NO3_summ_adj, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
  ylab(expression(bold(paste(NO[3], "-N ", "(mg", " ", g^-1," dry soil)", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#6495ED", "#B5651D"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.05, 0.8),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(NO3_plot_adj)

# plot area 5" x 15"

#=====DCB total iron summ stats and plot======
DCB <- read_excel("DCB_final.xlsx", 
                  sheet = "DCB_final", col_types = c("blank", 
                                                     "text", "numeric", "numeric", "numeric", 
                                                     "text", "blank", "blank", "blank", 
                                                     "blank", "blank", "numeric"))


DCB_summ <- DCB %>%
  mutate(Trt. = factor(Trt., levels = c("DIW", "CaSO4", "Na2SO4", "NaCl", "NaCl + CaSO4",
                                        "NaCl + Na2SO4", "NaCl + Na2SO4 + CaSO4", "Inst. Ocean"))) %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(mg.per.g.dry.soil), sd = sd(mg.per.g.dry.soil), sem = sd(mg.per.g.dry.soil)/sqrt(length(mg.per.g.dry.soil))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2"))) %>%
  mutate(mean = replace(mean, mean <=0, 0.00001))
write.csv(DCB_summ, file = "DCBsumm.csv")

DCB_plot <- ggplot(DCB_summ, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
  ylab(expression(bold(paste(Fe, " (mg", " ", g^-1," dry soil)", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#9E1A1A", "#708090"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.95, 0.2),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(DCB_plot)

#=====Ox non-crystalline iron summ stats and plot======
OX <- read_excel("Ox_final.xlsx", sheet = "Ox_final", 
                             col_types = c("blank", "text", "text", 
                                           "numeric", "numeric", "blank", "blank", 
                                           "blank", "numeric", "blank", "blank"))

OX_summ <- OX %>%
  mutate(Trt. = factor(Trt., levels = c("DIW", "CaSO4", "Na2SO4", "NaCl", "NaCl + CaSO4",
                                        "NaCl + Na2SO4", "NaCl + Na2SO4 + CaSO4", "Inst. Ocean"))) %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(mg.per.g.dry.soil), sd = sd(mg.per.g.dry.soil), sem = sd(mg.per.g.dry.soil)/sqrt(length(mg.per.g.dry.soil))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2"))) %>%
  mutate(mean = replace(mean, mean <=0, 0.00001))
write.csv(OX_summ, file = "OXsumm.csv")

OX_plot <- ggplot(OX_summ, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
  ylab(expression(bold(paste(Fe, " (mg", " ", g^-1," dry soil)", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#9E1A1A", "#708090"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.95, 0.2),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(OX_plot)

#====Hydrox total dissolved iron summ stats and plot====
HYDRX <- read_excel("Hydrox_final.xlsx", 
                           sheet = "hydrox.final", col_types = c("blank", 
                                                                 "numeric", "blank", "blank", "numeric", 
                                                                 "numeric", "numeric", "text", "numeric", 
                                                                 "numeric", "text", "blank", "blank", 
                                                                 "blank", "numeric"))

HYDRX_summ <- HYDRX %>%
  mutate(Trt. = factor(Trt., levels = c("DIW", "CaSO4", "Na2SO4", "NaCl", "NaCl + CaSO4",
                                        "NaCl + Na2SO4", "NaCl + Na2SO4 + CaSO4", "Inst. Ocean"))) %>%
  group_by(Trt., Day, O2.level) %>%
  dplyr::summarize(., mean = mean(ug.per.g.dry.soil), sd = sd(ug.per.g.dry.soil), sem = sd(ug.per.g.dry.soil)/sqrt(length(ug.per.g.dry.soil))) %>%
  within(., O2.level <- factor(O2.level, levels = c("O2", "No O2"))) %>%
  mutate(mean = replace(mean, mean <=0, 0.00001))
write.csv(HYDRX_summ, file = "HYDRXsumm.csv")

HYDRX_plot <- ggplot(HYDRX_summ, aes(x= Trt., y=mean, fill=O2.level)) +
  geom_bar(aes(fill=O2.level), position=position_dodge(width=0.9), stat = "identity", color= "black") +
  geom_errorbar(aes(ymax = mean + sem, ymin=mean - sem), position=position_dodge(width = 0.9),
                color="black", width=0.3, size=0.5) + 
  xlab("Treatment") + # change title axis
  ylab(expression(bold(paste(Fe, " (??g", " ", g^-1," dry soil)", sep="")))) +
  facet_wrap(~Day, ncol=3) +
  scale_x_discrete(labels = wrap_format(10))+
  scale_fill_manual(name = "Oxygen level", values=c("#9E1A1A", "#708090"))+
  theme_bw() + # change background and theme to black and white
  theme(strip.text.x = element_text(size = 14),
        axis.title.x=element_text(size=14,face='bold', vjust=1), # move the x axis label down, make the font bigger and bold
        axis.title.y=element_text(size=14,face="bold",hjust=0.5,vjust =1,angle=90), # move the y axis over, make font bigger and bold, and keep it rotated at 90 degrees
        axis.text.x=element_text(size=10, hjust= 0.5, vjust=0.6, angle=90, color="black"),
        axis.text.y=element_text(size=14),
        panel.grid.major=element_blank(), # get rid of the grid
        panel.grid.minor=element_blank(),
        panel.border = element_blank(),
        axis.line.x = element_line(color = 'black'),
        axis.line.y = element_line(color = 'black'),
        legend.position=c(0.05, 0.8),
        legend.text=element_text(size=12),
        legend.title=element_text(size=14),
        legend.key=element_blank())
plot(HYDRX_plot)

#====Data transformations and linear regression====
# PO4 
hist(PO4$mg.per.g.dry.soil) # Data look like an exponential distribution
# Box cox transformation by treatment (8 levels of salt combination) and O2 level (2 levels: O2 or No O2)
boxcox(PO4$mg.per.g.dry.soil ~ PO4$Trt. * PO4$O2.level * PO4$Day)
boxcox(PO4$mg.per.g.dry.soil ~ PO4$Trt. * PO4$O2.level * PO4$Day, plotit=FALSE) # lamda = 0.1
max(boxcox(PO4$mg.per.g.dry.soil ~ PO4$Trt. * PO4$O2.level * PO4$Day, plotit=FALSE)$y)

hist(bcPower(PO4$mg.per.g.dry.soil, 0.1))
qqnorm(bcPower(PO4$mg.per.g.dry.soil, 0.1))
# After viewing hist and qqnorm, not totally satisfied with the transformation result
# but will run models with transformed data anyway just to see

# Is there a main effect of O2.level?
# Is there a main effect of Trt.?
# Is there an interactive effect of O2.level*Trt.? O2.level*Day? Trt.*Day?
# Is there an effect of Day? (Likely yes between 0 and 15 and 30 and 0 but not sure about 15 and 30)
# model (blocked by Rep)

# Linear mixed effects model
fit_lmer <- lmer(bcPower(mg.per.g.dry.soil, 0.1) ~ O2.level*Trt.*Day, data = PO4)
anova(fit_lmer)
# Warning: "boundary (singular) fit: see ?isSingular", Rep has s.d. and variance of zero.
# Try model without Rep

# Linear fixed effects model (leave out random effect of Rep.)
fit_lm <- lm(bcPower(mg.per.g.dry.soil, 0.1) ~ O2.level*Trt.*Day, data = PO4)
anova(fit_lm)

# Results:
# Response: bcPower(mg.per.g.dry.soil, 0.1)
# Df Sum Sq Mean Sq  F value    Pr(>F)    
# O2.level            1 11.952  11.952  66.1433 1.124e-13 ***
# Trt.                7  8.604   1.229   6.8018 4.580e-07 ***
# Day                 1 95.410  95.410 527.9933 < 2.2e-16 ***
# O2.level:Trt.       7  0.207   0.030   0.1635    0.9919    
# O2.level:Day        1  6.039   6.039  33.4208 3.817e-08 ***
# Trt.:Day            7  0.893   0.128   0.7057    0.6672    
# O2.level:Trt.:Day   7  0.340   0.049   0.2689    0.9651    
# Residuals         159 28.732   0.181    

# Interactive effect between O2.level and Day expected because Day 0 is included. Every
# measurement should be roughly the same at Day 0.

# Can use "pf" to adjust p-values. pf(F.ratio, numDF, denomDF)
# n = denominator degrees of freedom
# n = (O2.level-1)(Trt.-1)(Day-1) = (2-1)*(8-1)*(3-1)


# Want to determine overall main effects of O2.level and Trt. and then do paired t-tests
# at Day 30 between O2 levels within each treatment (to increase power of test)

# I would like to repeat this analysis for all variables