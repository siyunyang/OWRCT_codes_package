###Real Application
rm(list=ls())

library(xtable)
source("Crude.R")
source("IPWC.R")
source("LinearR.R")
source("PS_AIPW.R")
source("OW.R")


##Helper function to output all results
output_helper<-function(est,se,level=0.05)
{
  res=c(est,se,est-qnorm(1-level/2)*se,est+qnorm(1-level/2)*se,
        2*(1-pnorm(abs(est/se))))
  names(res)=c("Estimate","SE","95% CI","95% CI","p-value")
  return (res)
}

##Some baselines covariates
## age,race,siteid,gender,bmi,ahi_primary,ess_total

##Baseline outcomes
##Resting Blood Pressure
## avgseatedsystolic
## avgseatedpulse
##Baseline sleepness ess_total
baseline_covariates_name=c("age","race_1","race_2",
                           "site_1","site_2","bmi","gender",
                           "avgseatedsystolic",
                           "avgseatedpulse",
                           "ahi_primary","ess_total_base")

# baseline_covariates_name=c("age",
#                            "bmi","gender",
#                            "avgseatedsystolic",
#                            "ahi_primary","ess_total_base")

###Outcome Codename
##Blood Pressure
### bp24sbpweight
### bp24dbpweight

##Self reported index 
## ess_total (ESS)
## whiirs_total

##Binary Outcome: Resistant hypertension
##(data.follow$bp24sbpweight>140||data.follow$bp24dbpweight>90)
outcome_name=c("bp24sbpweight","bp24dbpweight",
               "ess_total","whiirs_total",
               "res_hyper")

##var for treatment info
treated_name=c("pooled_treatmentarm","rand_treatmentarm")

##Read data
##Due to confidential reason, we do not post the original datasets online
##Available upon request and permission by the researchers from BestAir project.
data.baseline=read.csv("bestair-baseline-dataset-0.3.0.csv")
data.follow=read.csv("bestair-month6-dataset-0.3.0.csv")
#data.follow=read.csv("bestair-month12-dataset-0.3.0.csv")


##Rename/Create variable
data.baseline$ess_total_base=data.baseline$ess_total

#Create binary outcome
data.follow$res_hyper=NA
data.follow$res_hyper[data.follow$bp24sbpweight>=130]=1
data.follow$res_hyper[data.follow$bp24sbpweight<130]=0


#Categorical into dummY
data.baseline$race_1=0
data.baseline$race_1[data.baseline$race==1]=1
data.baseline$race_2=0
data.baseline$race_2[data.baseline$race==2]=2

data.baseline$site_1=0
data.baseline$site_1[data.baseline$siteid==1]=1
data.baseline$site_2=0
data.baseline$site_2[data.baseline$siteid==2]=1




#####Analyze 6 months difference
##Merge
baseline_data=data.baseline[data.baseline$nsrrid%in%data.follow$nsrrid,
                            c("nsrrid",baseline_covariates_name)]

#Delete missing covariates
complete.index=which(!apply(baseline_data,1,FUN=function(x){any(is.na(x))}))
baseline_data=baseline_data[complete.index,]

outcome_data=data.follow[data.follow$nsrrid%in%baseline_data$nsrrid,
                         c(treated_name,outcome_name)]
pool_data=cbind(baseline_data,outcome_data)


###Analysis on sbp
sbp_data=subset(pool_data,!is.na(bp24sbpweight))

X=as.matrix(sbp_data[,baseline_covariates_name])
y=sbp_data$bp24sbpweight
Tr=sbp_data$pooled_treatmentarm
W=cbind(1,X)

res_unadj_follow_sbp=Crude(y=y,z=Tr,W=W)
res_ipw_follow_sbp=IPWC(y.all=y,z.all=Tr,W.all=W,q.all=0)
res_ow_follow_sbp=OW(y=y,z=Tr,W=W)
res_lr_follow_sbp=LR(y=y,z=Tr,W=X)
res_aipw_follow_sbp=tryCatch({AIPW(y=y,z=Tr,W=X)},error=function(e){return(list(tau=NA,se=NA))})


result_follow_sbp=rbind(
  output_helper(res_unadj_follow_sbp$tau,res_unadj_follow_sbp$se),
  output_helper(res_ipw_follow_sbp$tau,res_ipw_follow_sbp$se),
  output_helper(res_lr_follow_sbp$tau,res_lr_follow_sbp$se),
  output_helper(res_aipw_follow_sbp$tau,res_aipw_follow_sbp$se),
  output_helper(res_ow_follow_sbp$tau,res_ow_follow_sbp$se)
)
               
##ESS_total
ess_data=subset(pool_data,!is.na(ess_total))
X=as.matrix(ess_data[,baseline_covariates_name])
y=ess_data$ess_total
Tr=ess_data$pooled_treatmentarm
W=cbind(1,X)

res_unadj_follow_ess=Crude(y=y,z=Tr,W=W)
res_ipw_follow_ess=IPWC(y.all=y,z.all=Tr,W.all=W,q.all=0)
res_ow_follow_ess=OW(y=y,z=Tr,W=W)
res_lr_follow_ess=LR(y=y,z=Tr,W=X)
res_aipw_follow_ess=tryCatch({AIPW(y=y,z=Tr,W=X)},error=function(e){return(list(tau=NA,se=NA))})

result_follow_ess=rbind(
  output_helper(res_unadj_follow_ess$tau,res_unadj_follow_ess$se),
  output_helper(res_ipw_follow_ess$tau,res_ipw_follow_ess$se),
  output_helper(res_lr_follow_ess$tau,res_lr_follow_ess$se),
  output_helper(res_aipw_follow_ess$tau,res_aipw_follow_ess$se),
  output_helper(res_ow_follow_ess$tau,res_ow_follow_ess$se)
)


res_hyper_data=subset(pool_data,!is.na(res_hyper))
X=as.matrix(res_hyper_data[,baseline_covariates_name])
y=res_hyper_data$res_hyper
Tr=res_hyper_data$pooled_treatmentarm
W=cbind(1,X)

res_unadj_follow_res=Crude(y=y,z=Tr,W=W,binary=1)
res_ipw_follow_res=IPWC(y.all=y,z.all=Tr,W.all=W,q.all=0,binary=1)
res_ow_follow_res=OW(y=y,z=Tr,W=W,binary=1)
res_lr_follow_res=LR(y=y,z=Tr,W=X,binary=1)
res_aipw_follow_res=tryCatch({AIPW(y=y,z=Tr,W=X,binary=1)},error=function(e){      return(list(mean_diff=NA,log_odds_ratio=NA,
                                                                                                                        log_risk_ratio=NA,se_risk_ratio=NA,
                                                                                                                        se_odds_ratio=NA,se_mean_diff=NA))})

##Log binomial, fitted 0 or 1, numerical error
#res_lr_follow_res=LR(y=y,z=Tr,W=X,binary=1,filter_numeric_error = F,logit_link=0)

##Mean Difference
result_follow_res_mean_diff=rbind(
  output_helper(res_unadj_follow_res$mean_diff,res_unadj_follow_res$se_mean_diff),
  output_helper(res_ipw_follow_res$mean_diff,res_ipw_follow_res$se_mean_diff),
  output_helper(res_lr_follow_res$mean_diff,res_lr_follow_res$se_mean_diff),
  output_helper(res_aipw_follow_res$mean_diff,res_aipw_follow_res$se_mean_diff),
  output_helper(res_ow_follow_res$mean_diff,res_ow_follow_res$se_mean_diff)
)

##Risk Ratio
result_follow_res_rr=rbind(
  output_helper(res_unadj_follow_res$log_risk_ratio,res_unadj_follow_res$se_risk_ratio),
  output_helper(res_ipw_follow_res$log_risk_ratio,res_ipw_follow_res$se_risk_ratio),
  output_helper(res_lr_follow_res$log_risk_ratio,res_lr_follow_res$se_risk_ratio),
  output_helper(res_aipw_follow_res$log_risk_ratio,res_aipw_follow_res$se_risk_ratio),
  output_helper(res_ow_follow_res$log_risk_ratio,res_ow_follow_res$se_risk_ratio)
)

##Odds Ratio
result_follow_res_or=rbind(
  output_helper(res_unadj_follow_res$log_odds_ratio,res_unadj_follow_res$se_odds_ratio),
  output_helper(res_ipw_follow_res$log_odds_ratio,res_ipw_follow_res$se_odds_ratio),
  output_helper(res_lr_follow_res$log_odds_ratio,res_lr_follow_res$se_odds_ratio),
  output_helper(res_aipw_follow_res$log_odds_ratio,res_aipw_follow_res$se_odds_ratio),
  output_helper(res_ow_follow_res$log_odds_ratio,res_ow_follow_res$se_odds_ratio)
)

result_follow=rbind(result_follow_sbp,
               result_follow_ess,
               result_follow_res_mean_diff,result_follow_res_rr,result_follow_res_or)


print(xtable(result_follow,digits=3))
