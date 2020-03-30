library(tidyverse)

dat <- read_csv('/nfs/public-data/cyberhelp/usage_logs/active_users.csv')

dat %>%
  select(date, rstudio_users, slurm_active) %>%
  pivot_longer(-date) %>%
  ggplot(aes(x = date, y = value)) +
    geom_line() +
    geom_point(size = 3) +
    facet_wrap(~ name, scales = 'free_y', labeller = labeller(name = c(rstudio_users = 'Number of active RStudio sessions',
                                                                       slurm_active = 'Number of active Slurm nodes'))) +
    theme_bw() +
    theme(strip.background = element_blank())
  
