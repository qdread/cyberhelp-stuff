library(glmmTMB)
library(betareg)

PO4_day30 <- PO4 %>% 
  filter(Day == 30) %>% 
  mutate(g_per_g = mg.per.g.dry.soil / 1000,
         Trt. = relevel(factor(Trt.), ref = 'DIW'))

PO4_alldays <- PO4 %>% 
  mutate(g_per_g = mg.per.g.dry.soil / 1000,
         Trt. = relevel(factor(Trt.), ref = 'DIW'),
         Day = factor(Day, ordered = TRUE))

fit_betareg <- betareg(g_per_g ~ O2.level * Trt., data = PO4_day30)

summary(fit_betareg)
plot(fit_betareg)

fit_betareg_onlytrt <- betareg(g_per_g ~  Trt., data = PO4_day30)
summary(fit_betareg_onlytrt)

fit_beta_mixedeffects <- glmmTMB(g_per_g ~ O2.level + Trt. + (1|Day), family = beta_family(link = "logit"), data = PO4_alldays, control = glmmTMBControl(optCtrl = list(iter.max = 1000, eval.max = 1000)))

summary(fit_beta_mixedeffects)
