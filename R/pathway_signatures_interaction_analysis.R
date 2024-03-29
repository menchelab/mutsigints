library(here)
fig.dir = here("figures/pathways_analysis")

if(! file.exists(fig.dir)){
    dir.create(fig.dir)
}

source(here("R/load_packages.R"))

mutated.pathways.tissues = readRDS(file = here("data/RDS/PCAWG/10_onco_pathways",
                                               "pcawg_pathways.RDS"))

PCAWG.full.subset.ann.pathways = readRDS(file = here("data/RDS/PCAWG/10_onco_pathways",
                                                     "PCAWG.full.subset.ann.pathways.RDS"))


PATH_MIN_TISSUES = 30


skin.data = get_tissue_pathway_activities("Skin_Melanoma", 
                                          sigs.input = PCAWG.full.subset.ann.pathways,
                                          pathways.input = mutated.pathways.tissues)

skin.data$sigs.logged = skin.data$sigs %>% 
    mutate(across(.cols = everything(), ~ log(.x + 1 )))

skin.concat = merge(skin.data$sigs.logged, skin.data$paths, by = "row.names")


skin.concat %>% 
    mutate (`RTK RAS` = factor(`RTK RAS`, levels = c(0, 1,2,3))) %>%
    ggplot(aes(x = `RTK RAS`, y = UV, 
                           group = `RTK RAS`, fill = `RTK RAS`) ) + 
    geom_boxplot() + geom_jitter() + 
    theme_bw(base_size = 13)


rtk.rlm = robustbase::lmrob(UV ~ `RTK RAS`, data = skin.concat)

rtk.lm = lm(UV ~ `RTK RAS`, data = skin.concat)

rtk.rev.rlm = robustbase::lmrob(`RTK RAS` ~ UV, data = skin.concat)

rtk.rev.lm = lm(`RTK RAS` ~ UV, data = skin.concat)


skin.hippo.apo.rlm = robustbase::lmrob(APOBEC ~ HIPPO, data = skin.concat)

skin.hippo.apo.lm = lm(APOBEC ~ HIPPO, data = skin.concat)

skin.hippo.apo.logit = glm(HIPPO ~ APOBEC, data = skin.concat, family = binomial)





skin.rlm = MASS::rlm(skin.concat[, "Ageing"] ~ skin.concat[, "TGF-Beta"])

skin.rlm2 = MASS::rlm(skin.concat[, "TGF-Beta"] ~ skin.concat[, "Ageing"])


skin.lmrob = robustbase::lmrob(skin.concat[, "Ageing"] ~ skin.concat[, "TGF-Beta"])

skin.lmrob2 = robustbase::lmrob(skin.concat[, "TGF-Beta"] ~ skin.concat[, "Ageing"])

skin.rlm = MASS::rlm(skin.concat[, "Ageing"] ~ skin.concat[, "HIPPO"])
sfsmisc::f.robftest(skin.rlm, var = -1)

skin.rlm2 = MASS::rlm(skin.concat[, "HIPPO"] ~ skin.concat[, "Ageing"])
sfsmisc::f.robftest(skin.rlm2, var = -1)

skin.lmrob = robustbase::lmrob(skin.concat[, "Ageing"] ~ skin.concat[, "HIPPO"])

skin.lmrob0 = robustbase::glmrob(skin.concat[, "HIPPO"] ~ 1, family = binomial)
skin.lmrob2 = robustbase::glmrob(skin.concat[, "HIPPO"] ~ 1 + skin.concat[, "APOBEC"], 
                                 family = binomial)

anova(skin.lmrob0, skin.lmrob2)

colSums(skin.concat[, c("HIPPO", "Ageing")] > 0)


skin.concat[, c("HIPPO", "Ageing")] %>% rstatix::wilcox_test(Ageing ~ HIPPO)

skin.concat[, c("HIPPO", "APOBEC")] %>% 
    mutate(HIPPO = factor(HIPPO)) %>% 
    ggplot(aes(x = HIPPO, y = APOBEC, color = HIPPO, group = HIPPO)) + 
    geom_boxplot() + geom_jitter(color = "black")



rob.lin.mod = MASS::rlm(tissue.concat[, sig] ~ tissue.concat[, pathway])
int.mat[sig, pathway] = summary(rob.lin.mod)$coefficients[, "Value"][2]
p.values[sig, pathway] = tryCatch({
    sfsmisc::f.robftest(rob.lin.mod, var = -1)$p.value},
    error = function(e) {return(1)})


lin.mod = lm(tissue.concat[, sig] ~ tissue.concat[, pathway])
int.mat[sig, pathway] = summary(lin.mod)$coefficients[, "Estimate"][2]
p.values[sig, pathway] = summary(lin.mod)$coefficients[,"Pr(>|t|)"][2]



# Thinking of skin situation ----------------------------------------------

sig = "UV"
path = "RTK RAS"

int.cols = skin.concat[, c(sig, path)]

cont.table = table(as.data.frame(int.cols > 0))

ft = fisher.test(cont.table)


# panc_endocrine ----------------------------------------------------------


"Panc_Endocrine"

pancendo.data = get_tissue_pathway_activities("Panc_Endocrine", 
                                          sigs.input = PCAWG.full.subset.ann.pathways,
                                          pathways.input = mutated.pathways.tissues)


get_sig_path_lms(pancendo.data$sigs, pancendo.data$paths, 
                            sig.log = TRUE, 
                            robust = TRUE,
                            path.to.sig = FALSE,
                            p.val.threshold = 0.05, 
                            p.adjust = TRUE, method = "BH")


pancendo.data$sigs.logged = pancendo.data$sigs %>% 
    mutate(across(.cols = everything(), ~ log(.x + 1 )))
pancendo.concat = merge(pancendo.data$sigs.logged, pancendo.data$paths, by = "row.names")

sig = "MMR"
path = "NOTCH"

int.cols = pancendo.concat[, c(sig, path)]

robustbase::lmrob(
    tissue.concat[, sig] ~ tissue.concat[, pathway])


bone.osteosarc = get_tissue_pathway_activities("Bone_Osteosarc", 
                                               sigs.input = PCAWG.full.subset.ann.pathways,
                                               pathways.input = mutated.pathways.tissues)
  
bone.osteosarc.regs = get_sig_path_lms(bone.osteosarc$sigs, bone.osteosarc$paths, 
                                       interaction_function = get_sig_path_lms, 
                                       path.min.tissues = 30,
                                       p.val.threshold = 0.1,
                                       p.adjust = TRUE,
                                       method = "BH",
                                       sig.log = TRUE,
                                       robust = TRUE,
                                       path.to.sig = FALSE)

  

logged.sbs17 = log(bone.osteosarc$sigs[,"SBS17"] + 1)
paths.binary = as.numeric(bone.osteosarc$paths[,"Cell Cycle"] > 0)

robustbase::glmrob(paths.binary ~ 1 + sample(logged.sbs17), family = binomial)
robustbase::glmrob(paths.binary ~ 1 + logged.sbs17, family = binomial)



glm.out = glm(paths.binary ~ 1 + logged.sbs17, family = binomial)


# Pancreatic adenocarcinoma -----------------------------------------------


pancadeno.data = get_tissue_pathway_activities("Panc_AdenoCA", 
                                              sigs.input = PCAWG.full.subset.ann.pathways,
                                              pathways.input = mutated.pathways.tissues)

pancadeno.data$sigs.logged = pancadeno.data$sigs %>% 
    mutate(across(.cols = everything(), ~ log(.x + 1 )))

pancadeno.concat = merge(pancadeno.data$sigs.logged, 
                         pancadeno.data$paths, by = "row.names")

panc.lm = lm(SBS40 ~ NOTCH, data = pancadeno.concat)
summary(panc.lm)


panc.odds.mat = get_sig_path_lms(pancadeno.data$sigs,
                                 pancadeno.data$paths, 
                                 p.val.threshold = 0.1,
                                 robust = FALSE,
                                 p.adjust = TRUE,
                                 method = "BH",
                                 sig.log = TRUE,
                                 path.to.sig = TRUE)


ggheatmap_wrapper(panc.odds.mat)




ova.data = get_tissue_pathway_activities("Ovary_AdenoCA", 
                                               sigs.input = PCAWG.full.subset.ann.pathways,
                                               pathways.input = mutated.pathways.tissues)

ova.odds.mat = get_sig_path_lms(ova.data$sigs,
                                ova.data$paths, 
                                 p.val.threshold = 0.1,
                                 robust = FALSE,
                                 p.adjust = TRUE,
                                 method = "BH",
                                 sig.log = TRUE,
                                 path.to.sig = TRUE)
