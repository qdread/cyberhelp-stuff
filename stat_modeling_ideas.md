---
output:
  pdf_document: default
  html_document: default
---
# Ideas and resources for statistical modeling 

Originally compiled by QDR, July 2020, for summer institute participants  
Modified by QDR, 20 Aug 2020, to focus more on SEMs

## Mixed models

Also sometimes called multilevel models, mixed-effects models, or random effects models. The idea behind these models is that you have individual observations that are somehow grouped. We model the y values for those individual observations (households in your case) as if they were drawn from a distribution, where each group (cluster in your case) has its own mean. This allows us to have a higher sample size than if we just averaged each cluster and used one value per cluster, but it also accounts for the fact that households within cluster aren't statistically independent.

The R package `lme4` is probably the best package for working with multilevel models. If you want to fit Bayesian multilevel models, my favorite package is the `brms` package -- the creator of the package, Paul Bürkner, is very responsive to questions from users. It is basically a wrapper for Stan, which is a language used for building and fitting Bayesian models.

There are tons of resources about these kinds of models online. Looking through the package tutorials and vignettes is probably a good way to get started:

- [lme4 package vignette](https://cran.r-project.org/web/packages/lme4/vignettes/lmer.pdf)
- [brms package vignette](https://cran.r-project.org/web/packages/brms/vignettes/brms_overview.pdf)

Also [this book by Gelman and Hill](http://www.stat.columbia.edu/~gelman/arm/) is really great for learning about mixed models, albeit written from a Bayesian perspective. It also gets into a more philosophical discussion of causal inference which would be really important for your work. Another good Bayesian introductory book is the ["Puppy Book" by John Kruschke](https://sites.google.com/site/doingbayesiandataanalysis/), not its actual name but it has puppies on the cover. It teaches the concepts very lucidly, using R, JAGS, and Stan. (JAGS is an older alternative to Stan.)
## Structural equation models (SEMs)

You will also hear the term path analysis (which is a specific kind of SEM), or network models or graph models (a larger family of models that includes SEMs). SEMs allow you to draw out your hypothesis about the causal relationships between variables in your system, represented by a network diagram with arrows going from cause to effect. In this model, there is not necessarily a distinction between independent and dependent (x and y) variables. A variable can be both a cause and an effect.

To me the most useful book is James Grace's book on structural equation models. It's focused on ecology applications but can be applied to other topics. [Here is a link to the book.](https://www.cambridge.org/core/books/structural-equation-modeling-and-natural-systems/D05B2328107F91AF772182F3AF88EB12) It might be a little out of date, now that it is around 10 years old, but it still has a lot of good material.

The R package `lavaan` is probably the best one for working with these kind of models. <https://lavaan.ugent.be/> It is pretty straightforward to set up and fit a SEM with the lavaan package. But it is more complicated if you want to also incorporate a multilevel random effects structure into the model. Judging from the lavaan site, it looks like it has some limited support for doing a [multilevel structural equation model](https://lavaan.ugent.be/tutorial/multilevel.html) which might be useful for you. 

The Bayesian alternative to the `lavaan` package is the [blavaan package](https://faculty.missouri.edu/~merklee/blavaan/). It uses Stan under the hood. However, Gelman, the creator of Stan, [is a little skeptical about SEMs in general](https://statmodeling.stat.columbia.edu/2020/03/30/structural-equation-modeling-and-stan/). But I would not let that stop you. Also you can fit SEMS in `brms`, as [this tutorial describes](https://rpubs.com/jebyrnes/brms_bayes_sem).

At SESYNC, Kristal Jones (former staff scientist who is now based elsewhere but still affiliated with some SESYNC groups) is probably the person who used SEMs the most in her own research. In the past, Kelly Hondula directed people interested in SEMs to her. (Disclaimer: She just had a baby so may be difficult to get in touch with.) Rachael and myself have used them too, and probably others I'm not aware of.

## Model selection and validation

Model selection means taking multiple "candidate models" and choosing the model or models that perform the best. Usually we would want to define performance as striking the best balance between fitting the data well (describing variation in the data) but not overfitting (because then it would not be able to predict with new data points). 

For model selection with the lme4 mixed models in R, I have used the [MuMIn package](https://www.rdocumentation.org/packages/MuMIn/versions/1.43.17) in the past. It looks like there is a package that came out more recently that might have a better method for model selection with the mixed models, that I haven't used yet but I have heard of people using, the [cAIC4 package](https://arxiv.org/pdf/1803.05664.pdf).

As for model validation, I would really strongly encourage checking out the book [Introduction to Statistical Learning in R](http://faculty.marshall.usc.edu/gareth-james/ISL/) -- the book PDF is freely available. I worked through the entire book and it really explained a lot to me. It goes into some basic machine learning stuff, which you also might want to think about.