

#first empty working memory
rm(list=ls())

# #then install packages (NOTE: this only needs to be done once for new users of RStudio!)

#install.packages("ggplot2")
#install.packages("moments")
#install.packages("RColorBrewer")
#install.packages("data.table")
#install.packages("plotly")
#install.packages("dplyr")
#install.packages("ggpubr", repos = "https://cloud.r-project.org/", dependencies = TRUE)

#extrafont::loadfonts(device="win")
#then load relevant libraries
library(ggplot2)
library(plotly)
library(tidyr)
library(ggpubr)
library(moments)
library(data.table)
library(RColorBrewer)
library(viridis)
library(hrbrthemes)
library(scales)
library(zoo)
library(dplyr)

### MANUAL INPUT: specify and set working directory ###
workdirec <-"C:/Users/20225262/OneDrive - TU Eindhoven/Documents/Papers/Moral Expension/Model/Output" 


setwd(workdirec)
source("functions_behaviorspace_table_output_handling.R")

### MANUAL INPUT: Optionally specify filepath (i.e. where the behaviorspace csv is situated) ###
#NOTE: if csv files are placed in the workdirec, then leave filesPath unchanged
filesPath <- ""
### MANUAL INPUT: specify filenames ###
filesNames <- ("Model2.0 Experiment 1-table.csv")

# READ DATA ---------------------------------------------------------------

df <- loadData(filesPath, filesNames)

# REMOVE INVALID RUNS ---------------------------------------------------------------
#runs that have a lower amount of maximum infected are seen as invalid and are therefore removed
#specify the minimum number of infected people for a run to be considered as valid (5 person by default)
#the next will fail if the number of infected is not in the data as -> count.people.with..is.infected..
#df <- cleanData(df, 0)

# REMOVE IRRELEVANT VARIABLES ---------------------------------------------------------------

#Loop through dataframe and identify variables that do NOT vary (i.e. that are FIXED)
#Unfixed variables are either independent or dependent and therefore relevant to include in the analysis
#df <- removeVariables(df)

# RENAME VARIABLES ---------------------------------------------------------------
printColumnNames(df)

### MANUAL INPUT: specify new (easy-to-work-with) variable names ###
new_variable_names <- list(
  "run_number",
  "value_mean",
  "ep_linear",
  "tick",
  "Stage_1.00",
  "Stage_1.25",
  "Stage_1.50",
  "Stage_1.75",
  "Stage_2.00",
  "Stage_2.25",
  "Stage_2.50",
  "Stage_2.75",
  "Stage_3.00",
  "ME_ST_OTC",
  "ME_OTC_SE",
  "ME_SE_C",
  "ME_C_ST"

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



clean_df <- clean_df %>% group_by(tick, value_mean,
                                  ep_linear) %>% 
  summarise(across( Stage_1.00:ME_C_ST  , mean))  



# TRANSFORM DATAFRAME -----------------------------------------------------

#Create a long format dataframe: long dataframes enable you to plot multiple y-variables in one single graph
### MANUAL INPUT: make sure that you specify which variables are to be considered as metrics (i.e. dependent variables)
#Note that you need to specify the range of outcome variables! (see the last input to the 'gather' function)
df_long <- gather(clean_df, variable, measurement, Stage_1.00:ME_C_ST)

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
#df_long$run_number <- as.integer(df_long$run_number)
df_long$variable <- as.factor(df_long$variable)

# PLOTTING -----------------------------------------------------

# Below you can find some ggplot commands for building useful visualizations
# If you would like to build something different, check out the world wide web! :-)
# You can also contact Kurt or Maarten if you're stuck!
# http://r-statistics.co/Complete-Ggplot2-Tutorial-Part1-With-R-Code.html

# Value_change --------------------------------------------------

 MEHOL <- df_long%>% filter((
            variable == "Stage_1.00" |
            variable == "Stage_1.25" |
            variable == "Stage_1.50" |
            variable == "Stage_1.75" |
            variable == "Stage_2.00" |
            variable == "Stage_2.25" |
            variable == "Stage_2.50" |
            variable == "Stage_2.75" |
            variable == "Stage_3.00" ),
         ep_linear == "true", value_mean == 60) %>%
  dplyr::sample_frac(1) %>%
   ggplot( aes(x = tick,
               y = measurement, fill = variable)) +
  # geom_line(linewidth=0.75,alpha=1) +
   geom_area(position = "fill", colour = "black", size = .2, alpha = .4) +
 # stat_smooth(
  #  geom = 'area', span = 0.2,
  #  alpha = 0.4) + 
  xlab("t (Weeks)") +
  ylab("People") + 
  scale_fill_viridis(discrete = T) +
   scale_x_continuous() +
  scale_y_continuous(labels = scales::percent, limit=c(0,NA),oob=squish) +
 # scale_color_manual(name = "Stages of Moral Expansion",
  #                   values = colorRampPalette(brewer.pal(11, "Spectral"))(9)) +
  facet_grid(. ~ "EP Linear, Homogeneous") +
  #guides(color = guide_legend(override.aes = list(size=9, alpha=1, fill=NA))) +
 
  theme_ipsum() +
  theme(strip.background = element_rect(fill="black"),
        strip.text = element_text(size=12, colour="white", face = "bold"))

MEHOL
 
 MEHOE <- df_long%>% filter((
   variable == "Stage_1.00" |
     variable == "Stage_1.25" |
     variable == "Stage_1.50" |
     variable == "Stage_1.75" |
     variable == "Stage_2.00" |
     variable == "Stage_2.25" |
     variable == "Stage_2.50" |
     variable == "Stage_2.75" |
     variable == "Stage_3.00" ),
   ep_linear == "false", value_mean == 60) %>%
   dplyr::sample_frac(1) %>%
   ggplot( aes(x = tick,
               y = measurement, fill = variable)) +
   # geom_line(linewidth=0.75,alpha=1) +
   geom_area(position = "fill", colour = "black", size = .2, alpha = .4) +
   # stat_smooth(
   #    geom = 'area', span = 0.2,
   #   alpha = 0.4) + 
   xlab("t (Weeks)") +
   ylab("People") + 
   scale_fill_viridis(discrete = T) +
   scale_x_continuous() +
   scale_y_continuous(labels = scales::percent) +
   # scale_color_manual(name = "Stages of Moral Expansion",
   #                   values = colorRampPalette(brewer.pal(11, "Spectral"))(9)) +
   facet_grid(. ~ "EP Exponential, Homogeneous") +
   theme_ipsum() +
   theme(strip.background = element_rect(fill="black"),
         strip.text = element_text(size=12, colour="white", face = "bold"))
 
 MEHEL <- df_long%>% filter((
   variable == "Stage_1.00" |
     variable == "Stage_1.25" |
     variable == "Stage_1.50" |
     variable == "Stage_1.75" |
     variable == "Stage_2.00" |
     variable == "Stage_2.25" |
     variable == "Stage_2.50" |
     variable == "Stage_2.75" |
     variable == "Stage_3.00" ),
   ep_linear == "true", value_mean == 70) %>%
   dplyr::sample_frac(1) %>%
   ggplot( aes(x = tick,
               y = measurement, fill = variable)) +
   # geom_line(linewidth=0.75,alpha=1) +
   geom_area(position = "fill", colour = "black", size = .2, alpha = .4) +
   # stat_smooth(
   #    geom = 'area', span = 0.2,
   #   alpha = 0.4) + 
   xlab("t (Weeks)") +
   ylab("People") + 
   scale_fill_viridis(discrete = T) +
   scale_x_continuous() +
   scale_y_continuous(labels = scales::percent) +
   # scale_color_manual(name = "Stages of Moral Expansion",
   #                   values = colorRampPalette(brewer.pal(11, "Spectral"))(9)) +
   facet_grid(. ~ "EP Linear, Heterogeneous") +
   theme_ipsum() +
   theme(strip.background = element_rect(fill="black"),
         strip.text = element_text(size=12, colour="white", face = "bold"))
 MEHEL
 MEHEE <- df_long%>% filter((
   variable == "Stage_1.00" |
     variable == "Stage_1.25" |
     variable == "Stage_1.50" |
     variable == "Stage_1.75" |
     variable == "Stage_2.00" |
     variable == "Stage_2.25" |
     variable == "Stage_2.50" |
     variable == "Stage_2.75" |
     variable == "Stage_3.00" ),
   ep_linear == "false", value_mean == 70) %>%
   dplyr::sample_frac(1) %>%
   dplyr::sample_frac(1) %>%
   ggplot( aes(x = tick,
               y = measurement, fill = variable)) +
   # geom_line(linewidth=0.75,alpha=1) +
   geom_area(position = "fill", colour = "black", size = .2, alpha = .4) +
   # stat_smooth(
   #    geom = 'area', span = 0.2,
   #   alpha = 0.4) + 
   xlab("t (Weeks)") +
   ylab("People") + 
   scale_fill_viridis(discrete = T) +
   scale_x_continuous() +
   scale_y_continuous(labels = scales::percent) +
   # scale_color_manual(name = "Stages of Moral Expansion",
   #                   values = colorRampPalette(brewer.pal(11, "Spectral"))(9)) +
   facet_grid(. ~ "EP Exponential, Heterogeneous") +
   theme_ipsum() +
   theme(strip.background = element_rect(fill="black"),
         strip.text = element_text(size=12, colour="white", face = "bold"))
 MEHEE

 esfigure <- ggarrange (MEHOL, MEHOE, MEHEL, MEHEE,
                        labels = c("A", "B", "C", "D"),
                        ncol = 2, nrow = 2,
                        legend = "right",
                        common.legend = TRUE)
 
 esfigure 
 
 esfiguretitle <- annotate_figure(esfigure,
                                  top = text_grob("Values", color = "steelblue", face = "italic", size = 14, hjust = -1.2))

 legendfigure <- ggarrange(as_ggplot(get_legend(vcTP)) + theme(plot.margin = margin(0, 0, 0, -0.75, "cm")), as_ggplot(get_legend(TTP)), ncol=1, nrow=2,legend="none")
 
 legendfigure
 vfigure <-  ggarrange (TTP,TPs, TGr,TSo, TSp,
                        labels = c("D", "H", "L","P","T"),
                        ncol = 1, nrow =5,
                        legend = "none",
                        common.legend = TRUE)
 
 
 vfiguretitle <- annotate_figure(vfigure,
                                 top = text_grob("Traits", color = "steelblue", face = "italic", size = 16, hjust = 0))
 
 cfigure <- ggarrange(esfiguretitle, vfiguretitle,legendfigure, ncol=3, nrow= 1, widths = c(5,1,0.7),
                      common.legend = FALSE) 
 vcfigure <- annotate_figure(cfigure, top=text_grob("Value Dynamics per PVO-group within mixed populations with 95% value-based social networks", color = "black", face = "bold", size = 20))
 vcfigure
 
 
 dfch <- data.frame(
   xvar= c('Hedonism', 'Stimulation', 'Self_Direction', 'Universalism', 'Benevolence', 'Conformity', 'Tradition', 'Security', 'Power', 'Achievement'),
  y = c(86.074, 80.103, 60.92425, 42.446, 17.445999999999998, 36.062, 19.568, 35.5415,  59.07575, 77.415),
  w = c(10, 10, 10, 15, 15, 10, 10, 10, 15, 15))
 data2 <- melt(dfch, id=c("xvar", "w"))
 
 73.1
 66.085
 64.450625
 46.712500000000006	
 35.547
 21.171
 13.0335
 37.81125
 55.549375
 67.48
 59.641

 
 
 # Create dataset
 data <- data.frame(
   id=c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
   individual= c( 'Self Direction', 'Stimulation', 'Hedonism', 'Achievement', 'Power', 'Security', 'Tradition', 'Conformity', 'Benovolence', 'Universalism'),
   value= c(  64.450625,  66.085,   73.1,    67.48, 55.549375,     37.81125,  13.0335	,    21.171	,    35.547	,    46.712500000000006		)
 )
 
 # ----- This section prepare a dataframe for labels ---- #
 # Get the name and the y position of each label
 label_data <- data
 
 # calculate the ANGLE of the labels
 number_of_bar <- nrow(label_data)
 angle <-  90 - 360 * (label_data$id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)
 
 # calculate the alignment of labels: right or left
 # If I am on the left part of the plot, my labels have currently an angle < -90
 label_data$hjust<-ifelse( angle < -90, 1, 0)
 
 # flip angle BY to make them readable
 label_data$angle<-ifelse(angle < -90, angle+180, angle)
 
 
 # Start the plot
 p <- ggplot(data, aes(x=as.factor(id), y=value, fill=individual)) +       # Note that id is a factor. If x is numeric, there is some space between the first bar
   
   # This add the bars with a blue color
   geom_bar(stat="identity") +
   
   # Limits of the plot = very important. The negative value controls the size of the inner circle, the positive one is useful to add size over each bar
   ylim(-50,150) +
   scale_color_manual(limits = dfch$xvar, values=colorRampPalette(brewer.pal(11, "Spectral"))(10)) +
   
   # Custom the theme: no axis title and no cartesian grid
   theme_minimal() +
   theme(
     legend.position = "none",
     axis.text = element_blank(),
     axis.title = element_blank(),
     panel.grid = element_blank(),
     plot.margin = unit(c(-1,-1,0,0), "cm")      # Adjust the margin to make in sort labels are not truncated!
   ) +
   
   # This makes the coordinate polar instead of cartesian.
   coord_polar(start = 0 ) 
   
   # Add the labels, using the label_data dataframe that we have created before
  # geom_text(data=label_data, aes(x=id, y=0, label=individual, hjust=c(0, 0, 0, 0, 0, 1, 1, 1, 1, 1)), color="black", fontface="bold",alpha=1, size=5.5, angle= label_data$angle, inherit.aes = FALSE ) 
 
 p
 
 

 
 59.641
 8.96
 32.638
 67.256
 29.583
 


 
 # Create dataset
 data <- data.frame(
   id=c(1, 2, 3, 4, 5),
   individual= c( 'Openness', 'Conscientiousness', 'Extraversion', 'Agreeableness', 'Neuroticism'),
   value= c(  59.641,  8.96, 32.638, 67.256, 29.583),
   k = c(  59.641,  8.96, 32.638, 67.256, 29.583)
 )
 
 # ----- This section prepare a dataframe for labels ---- #
 # Get the name and the y position of each label
 label_data <- data
 
 # calculate the ANGLE of the labels
 number_of_bar <- nrow(label_data)
 angle <-  90 - 360 * (label_data$id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)
 
 # calculate the alignment of labels: right or left
 # If I am on the left part of the plot, my labels have currently an angle < -90
 label_data$hjust<-ifelse( angle < -90, 1, 0)
 
 # flip angle BY to make them readable
 label_data$angle<-ifelse(angle < -90, angle+180, angle)
 
 
 # Start the plot
 p <- ggplot(data, aes(x=as.factor(id), y=value, fill=individual)) +       # Note that id is a factor. If x is numeric, there is some space between the first bar
   
   # This add the bars with a blue color
   geom_bar(stat="identity", width = 0.9, position = position_dodge(0.5)) +
   
   # Limits of the plot = very important. The negative value controls the size of the inner circle, the positive one is useful to add size over each bar
   ylim(-50,120) +
   scale_color_manual(limits = dfch$xvar, values=colorRampPalette(brewer.pal(11, "Spectral"))(10)) +
   
   # Custom the theme: no axis title and no cartesian grid
   theme_minimal() +
   theme(
     legend.position = "none",
     axis.text = element_blank(),
     axis.title = element_blank(),
     panel.grid = element_blank(),
     plot.margin = unit(c(1,0,0,0), "cm")      # Adjust the margin to make in sort labels are not truncated!
   ) +
   
   # This makes the coordinate polar instead of cartesian.
 #  coord_polar(start = 0 ) +
   
   # Add the labels, using the label_data dataframe that we have created before
   geom_text(data=label_data, aes(x=id, y=k+10, label=individual, hjust= c(0,0,0,0,0)), color="black", fontface="bold",alpha=1, size=6, angle= 90, inherit.aes = FALSE ) 
 
 p