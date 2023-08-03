#Made by Maarten Jensen (Umea University) & Kurt Kreulen (TU Delft) for ASSOCC

#first empty working memory
rm(list=ls())

# #then install packages (NOTE: this only needs to be done once for new users of RStudio!)
#install.packages("gridExtra")
#install.packages("grid")
#install.packages("plotly")
#install.packages("tidyr")]
#install.packages("ggpubr", repos = "https://cloud.r-project.org/", dependencies = TRUE)

#then load relevant libraries
library(ggplot2)
library(plotly)
library(tidyr)
library(ggpubr)
library(psych)
library(ggforce)
library(ggalt)
library(plyr)
library(grid)
library(wesanderson)
library("gridExtra")




### MANUAL INPUT: specify and set working directory ###
workdirec <-"C:/Users/Bart de Bruin/Documents/PhD/Cognitive Architecture Paper/Model/Output" 


setwd(workdirec)
source("functions_behaviorspace_table_output_handling.R")

### MANUAL INPUT: Optionally specify filepath (i.e. where the behaviorspace csv is situated) ###
#NOTE: if csv files are placed in the workdirec, then leave filesPath unchanged
filesPath <- ""
### MANUAL INPUT: specify filenames ###
dataFilePattern <- "csv"
filesNames   <- list.files(path=".", pattern=dataFilePattern)

# READ DATA ---------------------------------------------------------------
# READ DATA ---------------------------------------------------------------
ReadData <- function(p_files_path, p_files_names) {
  
  #read in datafiles using filesNames and filesPath variables
  for (i in 1:length(p_files_names)) {
    print(paste("read csv from:", p_files_path, p_files_names[i], sep=""))
    #bind data from dataframe into new dataframe
    if (exists('t_df') && is.data.frame(get('t_df'))) {
      temp_df <- read.csv(paste(p_files_path, p_files_names[i], sep=""), sep = ",",head=FALSE,stringsAsFactors = TRUE)
      t_df <- rbind(t_df, temp_df)
    }  else {
      t_df <- read.csv(paste(p_files_path, p_files_names[i], sep=""), sep = ",",head=FALSE,stringsAsFactors = TRUE)
    }
  }
  return(t_df)
}

unpacklists <- function(t_df){
}





df <- ReadData(filesPath, filesNames)

# REMOVE INVALID RUNS ---------------------------------------------------------------
#runs that have a lower amount of maximum infected are seen as invalid and are therefore removed
#specify the minimum number of infected people for a run to be considered as valid (5 person by default)
#the next will fail if the number of infected is not in the data as -> count.people.with..is.infected..
#df <- cleanData(df, 0)

# REMOVE IRRELEVANT VARIABLES ---------------------------------------------------------------

#Loop through dataframe and identify variables that do NOT vary (i.e. that are FIXED)
#Unfixed variables are either independent or dependent and therefore relevant to include in the analysis
df <- removeVariables(df)

# RENAME VARIABLES ---------------------------------------------------------------
printColumnNames(df)

### MANUAL INPUT: specify new (easy-to-work-with) variable names ###
new_variable_names <- list(
  "who_number",
  "Population_Scenario",
  "Hedonism",
  "Stimulation",
  "Self_Direction",
  "Universalism",
  "Benevolence",
  "Tradition",
  "Conformity",
  "Security",
  "Power",
  "Achievement",
  "Openness",
  "Conscientiousness",
  "Extraversion",
  "Agreeableness",
  "Neuroticism"
)

#change variable names
variable_names <- names(df)
if (length(variable_names) == length(new_variable_names)) {
  clean_df <- changeColumnNames(df, new_variable_names)
} else {
  print (length(variable_names))
  print (length(new_variable_names))
  print("ERROR: the number of variable names you specified is not the same as the number of variables present within the dataframe; please check again")
}

#remove redundant objects from working memory
rm(list = "df", "new_variable_names")

df_long <- gather(clean_df, variable, measurement, Hedonism:Neuroticism)

# SPECIFY VARIABLE MEASUREMENT SCALES -----------------------------------------------------
### MANUAL INPUT: in order for ggplot and plotly to work, one must specify the following: ###
#-> continuous decimal (floating) variables as 'numeric'
#-> continuous integer variables as 'integer'
#-> discrete (or categorical) variables as 'factor'

#print an overview of variables and their measurement scales
str(df_long)
#transform 'measurement' variable to numeric (as to avoid ggplot errors)
df_long$measurement <- as.numeric(df_long$measurement)
#round 'measurement' variable to 4 decimals
df_long$measurement <- round(df_long$measurement, 4)
#convert categorical variables to factors (as to avoid ggplot errors)
df_long$variable <- as.factor(df_long$variable)

scaleOrderValues <- c('Self_Direction', 'Stimulation', 'Hedonism', 'Achievement', 'Power', 'Security', 'Conformity', 'Tradition', 'Benevolence', 'Universalism')


VGR <- df_long%>% 
  filter(( variable == "Hedonism"|
             variable == "Stimulation" |
             variable == "Self_Direction" |
             variable == "Universalism" |
             variable == "Benevolence" |
             variable == "Tradition" |
             variable == "Conformity" |
             variable == "Security" |
             variable == "Power" |
             variable == "Achievement" ),
         Population_Scenario == "growth") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderValues) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Value Prioritization") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderValues)+
  facet_grid(. ~ "PVO: GROWTH") +
  guides(fill=guide_legend(title="Value")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+

  theme_bw()
VGR

VPR <- df_long%>% 
  filter(( variable == "Hedonism"|
             variable == "Stimulation" |
             variable == "Self_Direction" |
             variable == "Universalism" |
             variable == "Benevolence" |
             variable == "Tradition" |
             variable == "Conformity" |
             variable == "Security" |
             variable == "Power" |
             variable == "Achievement" ),
         Population_Scenario == "personal") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderValues) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Value Prioritization") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderValues)+
  facet_grid(. ~ "PVO: PERSONAL") +
  guides(fill=guide_legend(title="Value")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
VPR

VSP <- df_long%>% 
  filter(( variable == "Hedonism"|
             variable == "Stimulation" |
             variable == "Self_Direction" |
             variable == "Universalism" |
             variable == "Benevolence" |
             variable == "Tradition" |
             variable == "Conformity" |
             variable == "Security" |
             variable == "Power" |
             variable == "Achievement" ),
         Population_Scenario == "self-protection") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderValues) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Value Prioritization") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderValues)+
  facet_grid(. ~ "PVO: SELF PROTECTION") +
  guides(fill=guide_legend(title="Value")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
VSP

VSC <- df_long%>% 
  filter(( variable == "Hedonism"|
             variable == "Stimulation" |
             variable == "Self_Direction" |
             variable == "Universalism" |
             variable == "Benevolence" |
             variable == "Tradition" |
             variable == "Conformity" |
             variable == "Security" |
             variable == "Power" |
             variable == "Achievement" ),
         Population_Scenario == "social") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderValues) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Value Prioritization") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderValues)+
  facet_grid(. ~ "PVO: SOCIAL") +
  guides(fill=guide_legend(title="Value")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
VSC

VMX <- df_long%>% 
  filter(( variable == "Hedonism"|
             variable == "Stimulation" |
             variable == "Self_Direction" |
             variable == "Universalism" |
             variable == "Benevolence" |
             variable == "Tradition" |
             variable == "Conformity" |
             variable == "Security" |
             variable == "Power" |
             variable == "Achievement" ),
         Population_Scenario == "mixed") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderValues) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Value Prioritization") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderValues)+
  facet_grid(. ~ "PVO: MIXED") +
  guides(fill=guide_legend(title="Value")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
VMX

scaleOrderTraits <- c('Openness', 'Conscientiousness', 'Extraversion', 'Agreeableness', 'Neuroticism')

TGR <- df_long%>% 
  filter(( variable == "Openness"|
             variable == "Conscientiousness" |
             variable == "Extraversion" |
             variable == "Agreeableness" |
             variable == "Neuroticism" ),
         Population_Scenario == "growth") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderTraits) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Trait Score") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderTraits)+
  facet_grid(. ~ "PVO: GROWTH") +
  guides(fill=guide_legend(title="Trait")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
TGR

TPR <- df_long%>% 
  filter(( variable == "Openness"|
             variable == "Conscientiousness" |
             variable == "Extraversion" |
             variable == "Agreeableness" |
             variable == "Neuroticism" ),
         Population_Scenario == "personal") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderTraits) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Trait Score") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderTraits)+
  facet_grid(. ~ "PVO: PERSONAL") +
  guides(fill=guide_legend(title="Trait")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
TPR

TSP <- df_long%>% 
  filter(( variable == "Openness"|
             variable == "Conscientiousness" |
             variable == "Extraversion" |
             variable == "Agreeableness" |
             variable == "Neuroticism" ),
         Population_Scenario == "self-protection") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderTraits) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Trait Score") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderTraits)+
  facet_grid(. ~ "PVO: SELF PROTECTION") +
  guides(fill=guide_legend(title="Trait")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
TSP

TSC <- df_long%>% 
  filter(( variable == "Openness"|
             variable == "Conscientiousness" |
             variable == "Extraversion" |
             variable == "Agreeableness" |
             variable == "Neuroticism" ),
         Population_Scenario == "social") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderTraits) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Trait Score") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderTraits)+
  facet_grid(. ~ "PVO: SOCIAL") +
  guides(fill=guide_legend(title="Trait")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
TMX

TMX <- df_long%>% 
  filter(( variable == "Openness"|
             variable == "Conscientiousness" |
             variable == "Extraversion" |
             variable == "Agreeableness" |
             variable == "Neuroticism" ),
         Population_Scenario == "mixed") %>%
  dplyr::sample_frac(1) %>%
  ggplot(aes(x = factor(variable, level = scaleOrderTraits) , y=measurement, fill=variable)) +
  geom_violin(trim=FALSE) +
  geom_boxplot(width=0.1, fill="black")+
  labs(x = "", y = "Trait Score") +
  scale_x_discrete(labels = NULL, breaks = NULL) +
  scale_fill_brewer(palette="Paired", breaks=scaleOrderTraits)+
  facet_grid(. ~ "PVO: MIXED") +
  guides(fill=guide_legend(title="Trait")) +
  theme(strip.background = element_rect(fill="#C0C0C0"),
        strip.text = element_text(size=100, colour="white"))+
  
  theme_bw()
TMX
  
  
  
esfigure <- ggarrange (VGR, VPR, VSP, VSC, VMX,
                       labels = c("A", "B", "C", "D", "E"),
                       ncol = 1, nrow = 5,
                       legend = "left",
                       common.legend = TRUE)
esfiguretitle <- annotate_figure(esfigure,
                                 top = text_grob("Values", color = "black", face = "italic", size = 12, hjust = -1.2))



vfigure <-  ggarrange (TGR, TPR, TSP, TSC, TMX,
                       labels = c("a", "b", "c", "d", "e"),
                       ncol = 1, nrow = 5,
                       legend = "right",
                       common.legend = TRUE)


vfiguretitle <- annotate_figure(vfigure,
                                 top = text_grob("Traits", color = "black", face = "italic", size = 12, hjust = 2))

cfigure <- ggarrange(esfiguretitle, vfiguretitle, ncol=2, nrow= 1,
                     common.legend = FALSE)
vcfigure <- annotate_figure(cfigure, top=text_grob("The Cognitive Architectures within the Five Population Value Orientations (PVO)", color = "black", face = "bold", size = 14))
vcfigure

