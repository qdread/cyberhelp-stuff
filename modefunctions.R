dat <- read.csv(textConnection("taxon_id,genus_species,plant_feeding,origin_Nearctic,origin_Neotropic,origin_European_Palearctic,origin_Asian_Palearctic,origin_Indomalaya,origin_Afrotropic,origin_Australasia,origin_Oceania,intentional_release,ever_introduced_anywhere,notes,host_type,established_indoors_or_outdoors,host_group,phagy,pest_type,ecozone,current_distribution_cosmopolitan_,phagy_main,feeding_type,feeding_main,confirmed_establishment
13,Abgrallaspis cyanophylli,Y,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA
2,Abgrallaspis cyanophylli,Y,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA
2,Abgrallaspis cyanophylli,Y,0,1,0,0,0,0,0,0,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA
2,Abgrallaspis cyanophylli,Y,0,1,0,0,0,0,0,0,NA,NA,NA,NA,NA,Leaf: Fruits,NA,Greenhouse,NA,NA,NA,NA,NA,NA
2,Abgrallaspis cyanophylli,Y,0,0,0,0,0,0,0,1,NA,NA,NA,NA,NA,NA,polyphagous,NA,Oceania,Yes,Polyphagous,herbivore,Herbivore,NA
2,Abgrallaspis cyanophylli,Y,0,1,0,0,0,0,0,0,NA,NA,NA,NA,NA,face fly,NA,NA,NA,NA,NA,NA,NA,NA
2,Abgrallaspis cyanophylli,Y,0,1,0,0,0,0,0,0,NA,NA,NA,NA,NA,Leaf: Fruits,NA,Greenhouse,NA,NA,NA,NA,NA,NA
2,Abgrallaspis cyanophylli,Y,0,1,0,0,0,0,0,0,NA,NA,NA,NA,NA,Leaf: Fruits,NA,Greenhouse,NA,NA,NA,NA,NA,NA"))

library(tidyverse)

mode_fn <- function(x) {
  orig_class <- class(x)
  out <- ifelse(any(!is.na(x)), names(rev(sort(table(x))))[1], NA)
  as(out, orig_class)
}

dat %>%
  group_by(genus_species) %>%
  summarize_all(DescTools::Mode, na.rm = TRUE)
