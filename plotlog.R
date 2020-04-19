library(tidyverse)

dat <- read_csv('/nfs/public-data/cyberhelp/usage_logs/active_users.csv')

# Plot RStudio active sessions and Slurm active nodes by day, excluding weekends.
p <- dat %>%
  mutate(weekend = if_else(weekdays(date) %in% c('Saturday', 'Sunday'), 'weekend', 'weekday')) %>%
  select(date, weekend, rstudio_users, slurm_active) %>%
  pivot_longer(-c(date, weekend)) %>%
  ggplot(aes(x = date, y = value)) +
  geom_line() +
  geom_point(aes(color = weekend), size = 3) +
  scale_color_manual(values = c('black', 'gray75')) +
  facet_wrap(~ name, nrow = 2, labeller = labeller(name = c(rstudio_users = 'Number of active RStudio sessions',
                                                            slurm_active = 'Number of active Slurm nodes')),
			scales = 'free_y') +
  theme_bw() +
  theme(strip.background = element_blank(), 
        legend.position = c(.1, .35),
        legend.title = element_blank(),
        legend.key = element_blank(),
        legend.background = element_blank(),
        axis.title.y = element_blank()) +
  ggtitle('RStudio and Slurm usage report', format(Sys.time(), '%B %d, %Y'))

ggsave('/nfs/public-data/cyberhelp/usage_logs/usage_report.pdf', p, height = 5, width = 8)

