library(dplyr)
library(tidyr)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(RColorBrewer)
library(grid)
library(gridExtra)
library(maps)
library(mapdata)
library(sp)
library(maptools)
library(rgdal)
library(mapproj)
library(scales)
library(treemapify)
library(ckanr)
library(tidyverse)
library(jsonlite)
library(magrittr)
library(readr) 
library(dplyr)
library(xlsx)
library(openxlsx)
#--------------------------------------Loading required packages..............

#--------------------------------------Using the Api to extract the final merged dataset...........
Sys.setenv(CKANR_DEFAULT_URL="https://data.gov.ie")# set the server
get_default_url()

# search for the 
package_search(q="op-waiting-list-by-group-hospital", as="json") %>%
  fromJSON(flatten=TRUE) %>%
  extract2('result') %>%
  extract2('results') ->
  pkgs.ato
names(pkgs.ato)

#extract the titles in the package.
pkgs.ato$title %>%
  grep('OP', .) %>%
  extract(pkgs.ato$id, .) %T>%
  print() ->
  pid.ato.trans


pkg.ato.trans <- package_show(pid.ato.trans, as="table") %>% print()


dataframes_ <- c()
count <- 1
# extract the urls of each package and download the corresponding csv files
# store each datframe in a list then rename columns to a standard and merge all 6 datframes
# together
for(val in 2:6)
{
  url <- pkg.ato.trans$resources[val,]$url
  temp <- tempfile(fileext=".csv")
  download.file(url, temp)
  dataframes_[[count]] <- data.frame(read_csv(temp))
  unlink(temp)
  count = count +1
}

NewColumns <- c('Date','Hospital.Group', 'Hospital.HIPE','Hospital', 'Specialty.HIPE','Speacialty', 'AdultOrChild','Age.Profile', 'Time.Bands', 'Total')

for(i in 1:length(dataframes_)) {
  colnames(dataframes_[[i]]) <- NewColumns
}


final_dataset <- rbind(dataframes_[[1]], dataframes_[[2]],dataframes_[[3]],dataframes_[[4]],dataframes_[[5]])
drops <- c("Hospital.HIPE","Specialty.HIPE")
final_dataset[ , !(names(final_dataset) %in% drops)] -> op_waiting_list_frame


op_waiting_list_frame<-na.omit(op_waiting_list_frame)   #Remove the rows containing NAs

#preprocessing the dataset
#op_waiting_list<-as_tibble(op_waiting_list_frame[,-1])  #remove the index column
op_waiting_list<-op_waiting_list_frame %>% separate(Date,into=c("Year","Month","Day"),sep = "-",remove = F)
op_waiting_list$Year<-as.integer(op_waiting_list$Year)
op_waiting_list$Month<-as.integer(op_waiting_list$Month)
op_waiting_list$Day<-as.integer(op_waiting_list$Day)
op_waiting_list$Date<-date(op_waiting_list$Date)
op_waiting_list$AdultOrChild<-ifelse(op_waiting_list$Age.Profile=="16-64"|op_waiting_list$Age.Profile=="65+","Adult","Child")



#The whole summary table (aggregate everything result)
#Part 3:
op_waiting_summary<- op_waiting_list %>% group_by(Year,Hospital.Group,Hospital,Speacialty,AdultOrChild,Age.Profile,Time.Bands) %>% summarise(Total=sum(Total))
aggregate_1<-op_waiting_summary



#-----------Map visualization by county ----------------The average number of patients per hospital per month [1][2]

show_Avg_Patients_by_county<-function(year,op_waiting_list,ireland_shape)
{
  my_df<-fortify(ireland_shape)
  my_df<-as_tibble(my_df)
  my_df<-my_df %>% group_by(id)
  my_df_final<-my_df %>% filter(grepl("^[0-9]+\\.1$",group))
  
  label_list<-my_df_final %>% group_by(id) %>% summarise(cen_long=mean(long),cen_lat=mean(lat))
  my_df_final$id<-as.character(as.integer(my_df_final$id)+1)
  label_list$id<-as.character(as.integer(label_list$id)+1)
  label_list<-label_list %>% arrange(as.integer(id))
  label_list$name<-ireland_shape$NAME_1
  my_df_final <- my_df_final %>% inner_join(label_list,by="id")
  
  county<-data.frame(id=ireland_shape$ID_1,name=ireland_shape$NAME_1)
  county_hospital<-data.frame(Hospital=unique(op_waiting_list$Hospital),id=c(6,6,6,9,11,19,6,6,6,6,24,17,10,25,6,6,6,6,6,6,15,2,15,6,6,5,21,7,16,20,7,23,22,4,4,4,4,8,4,4,13,13,22,3,13))
  new_op_waiting_list<-op_waiting_list %>% inner_join(county_hospital,by="Hospital")
  
  tem_op_waiting_list_by_county<-new_op_waiting_list %>% filter(Year==year) %>% group_by(id) %>% summarise(Year=unique(Year),Avg_Waiting_num=mean(Total),Hos_num=length(unique(Hospital)))
  print(min(tem_op_waiting_list_by_county$Avg_Waiting_num))
  print(max(tem_op_waiting_list_by_county$Avg_Waiting_num))
  m<-label_list$id[!label_list$id %in% as.character(tem_op_waiting_list_by_county$id)]
  m_df<-data.frame(Year=unique(tem_op_waiting_list_by_county$Year),id=m,Avg_Waiting_num=0,Hos_num=0)
  
  new_op_waiting_list_by_county<-rbind(tem_op_waiting_list_by_county,m_df)
  my_df_final<-my_df_final %>% inner_join(new_op_waiting_list_by_county,by="id")
  
  print(max(my_df_final$Hos_num))
  
  my_df_final
}



#---------------------------------------------------------------------------------

ireland_shape<-readOGR("//fs2/18234602/Desktop/CaseStudiesThree/Ireland/IRL_adm1.shp")
m_color<-brewer.pal(n=9,"Oranges")

p1<-show_Avg_Patients_by_county(2014,op_waiting_list,ireland_shape)
p2<-show_Avg_Patients_by_county(2015,op_waiting_list,ireland_shape)
p3<-show_Avg_Patients_by_county(2016,op_waiting_list,ireland_shape)
p4<-show_Avg_Patients_by_county(2017,op_waiting_list,ireland_shape)
p5<-show_Avg_Patients_by_county(2018,op_waiting_list,ireland_shape)

final_df<-rbind(p1,p2,p3,p4,p5)
aggregate_2<-final_df %>% select(Year,name,Avg_Waiting_num,Hos_num) %>% distinct()




p<- final_df %>% ggplot()+
  geom_polygon(aes(x=long,y=lat,group=group,fill=Avg_Waiting_num),color="#FDAE6B")+
  coord_map("mercator")+
  scale_fill_gradientn(colors = m_color,limits=c(1,120))+
  theme_void()+
  guides(fill=guide_colorbar(title = "Avg Patients by county"))+
  theme(plot.title = element_text(size=10))+
  facet_wrap(~Year)

p     #Show the result  (Graph 1)

#-------------------------------Map Visualisation by county the number of hospitals...

m_color<-brewer.pal(n=5,"PuRd")
p6<-show_Avg_Patients_by_county(2018,op_waiting_list,ireland_shape)

p6 %>% ggplot()+
  geom_polygon(aes(x=long,y=lat,group=group,fill=Hos_num),color="#FDAE6B")+
  coord_map("mercator")+
  scale_fill_gradientn(colors = m_color,limits=c(0,15))+
  theme_void()+
  guides(fill=guide_colorbar(title = "Hospitals distribution"))+
  theme(plot.title = element_text(size=10))

#------------------Graph 2






#----------------------------------------Show the average total By age group (Childern/Adult) By year (Graph 3)
op_waiting_list_by_year_and_agetype<-op_waiting_list %>% group_by(Year,AdultOrChild) %>% summarise(Total=mean(Total))

aggregate_3<-op_waiting_list_by_year_and_agetype
colnames(aggregate_3)<-c("Year","AdultOrChild","Mean")

ggplot(data=op_waiting_list_by_year_and_agetype,aes(x=Year,y=Total,fill=AdultOrChild))+
  geom_col(position = "dodge")


#----------------------------------------Show the average total By Waiting time and year (Graph 4)
op_waiting_list_by_year_and_waitingtime<-op_waiting_list %>% group_by(Year,Time.Bands) %>% summarise(Total=mean(Total))

aggregate_4<-op_waiting_list_by_year_and_waitingtime
colnames(aggregate_4)<-c("Year","Time Bands","Mean")


ggplot(data=op_waiting_list_by_year_and_waitingtime,aes(x=Year,y=Total,fill=Time.Bands))+geom_col(position="dodge")+theme_classic()


#----------------------------------------Show the average total waiting time by age_profile,Hospital group and year (Graph 5)
op_waiting_list_by_year_and_ageprofile<-op_waiting_list %>% group_by(Year,Age.Profile,Hospital.Group) %>% summarise(Total=mean(Total))

aggregate_5<-op_waiting_list_by_year_and_ageprofile
colnames(aggregate_5)<-c("Year","Age Profile","Hospital group","Mean")

ggplot(data=op_waiting_list_by_year_and_ageprofile,aes(x=Year,y=Total,fill=Age.Profile))+geom_col(position = "dodge")+facet_wrap(~Hospital.Group)+theme_classic()


#----------------------------------------Time series analyis:
#-------------Show the number of patients by hospital (Faceted By Hospital and color by Group) (Graph 6)

hospital_p<-op_waiting_list %>% group_by(Date,Hospital.Group,Hospital) %>% summarise(mTotal=mean(Total))
hospital_e<-hospital_p
colnames(hospital_e)[3]<-"groupVar"
background<-geom_line(data=hospital_e,na.rm = T,aes(x=Date,y=mTotal,group=groupVar),color="GRAY",alpha=0.6,size=0.25)

mean_num_per_day<-hospital_p %>% group_by(Date) %>% summarise(mean=mean(mTotal))

aggregate_6<-hospital_p %>% inner_join(mean_num_per_day,by="Date")

colnames(aggregate_6)<-c("Date","Hospital Group","Hospital","Mean (Per Hospital)","Mean (Per Day)")

m<-hospital_p %>% ggplot(aes(x=Date,y=mTotal))+
  background+
  geom_line(data=mean_num_per_day,aes(x=Date,y=mean),col="red",size=0.7,linetype="dashed")+
  geom_line(size=1.5,na.rm=T,aes(group=Hospital,col=Hospital.Group))+
  scale_x_date(name="year",breaks = "1 year",labels = date_format("%Y"))+
  scale_y_continuous(labels = comma)+
  theme_classic()+
  theme(plot.margin = margin(14,7,3,1.5),axis.text.x = element_text(angle = 30,hjust = 1,size=7),axis.title.x = element_blank(),strip.text.x = element_text(size=7,face="bold"))+
  facet_wrap(~ Hospital,ncol = 6)

m



#--------------------------------------------Summary by diseases Using TreeMap/ Showing the top 30 frequent diseases by year (Graph 7) 
speciality_p<-op_waiting_list %>% group_by(Year,Speacialty) %>% summarise(mTotal=mean(Total))
speciality_p<-speciality_p %>% group_by(Year) %>% top_n(n=30,wt=mTotal)

aggregate_7<-speciality_p

colnames(aggregate_7)<-c("Year","Specialty","Mean")

gg<-speciality_p %>% ggplot(aes(area=mTotal,fill=mTotal,subgroup=Year,label=Speacialty))+
  geom_treemap()+
  geom_treemap_text(fontface="italic",color="white",place="centre",grow=T)+
  scale_fill_gradientn(colours = terrain.colors(30,alpha = 0.8))+
  facet_wrap(~ Year)+
  theme(legend.position = "bottom")+
  labs(title="The average number of waiting people by Speciality over 5 years")
gg

#--------------------------------------------Map for population of county (Graph 8)
Ireland_Population<- data.frame(id=as.character(c(1:26)),population=c(45845,56416,103333,448181,137383,500000,208826,132424,163995,80421,58732,25815,175529,31127,101802,117428,133936,52772,63702,53803,58178,140281,101518,72027,116543,114719),stringsAsFactors = F)

show_ireland_population_by_map<-function(Ireland_Population,ireland_shape)
{
  my_df<-fortify(ireland_shape)
  my_df<-as_tibble(my_df)
  my_df<-my_df %>% group_by(id)
  my_df_final<-my_df %>% filter(grepl("^[0-9]+\\.1$",group))
  label_list<-my_df_final %>% group_by(id) %>% summarise(cen_long=mean(long),cen_lat=mean(lat))
  my_df_final$id<-as.character(as.integer(my_df_final$id)+1)
  label_list$id<-as.character(as.integer(label_list$id)+1)
  label_list<-label_list %>% arrange(as.integer(id))
  label_list$name<-ireland_shape$NAME_1
  my_df_final <- my_df_final %>% inner_join(label_list,by="id") %>% inner_join(Ireland_Population,by="id")
  my_df_final 
}


m1_color<-brewer.pal(n=9,"PuRd")
my_df_final<-show_ireland_population_by_map(Ireland_Population,ireland_shape)

aggregate_8<-my_df_final %>% select(name,population) %>% distinct()
colnames(aggregate_8)<-c("County Id","Name","Population")

my_df_final %>% ggplot()+
  geom_polygon(aes(x=long,y=lat,group=group,fill=population),color="#c994c7")+
  coord_map("mercator")+
  scale_fill_gradientn(colors = m1_color,limits=c(min(Ireland_Population$population),max(Ireland_Population$population)))+
  theme_void()+
  theme(legend.position = "none",plot.title = element_text(size=10))+
  labs(title = "The population distribution in Ireland (2018)")


#-------------------------------Export to Xlsx File::
M_file<-createWorkbook()
addWorksheet(M_file,"aggregated by all")
addWorksheet(M_file,"aggregated by county")
addWorksheet(M_file,"aggregated by year,agetype")
addWorksheet(M_file,"aggregated by year,waitingtime")
addWorksheet(M_file,"aggregated by year,ageprofile")
addWorksheet(M_file,"aggregated by Hospital,Group")
addWorksheet(M_file,"aggregated by speciality")
addWorksheet(M_file,"The population")


writeData(M_file,sheet="aggregated by all",x=aggregate_1)
writeData(M_file,sheet="aggregated by county",x=aggregate_2)
writeData(M_file,sheet="aggregated by year,agetype",x=aggregate_3)
writeData(M_file,sheet="aggregated by year,waitingtime",x=aggregate_4)
writeData(M_file,sheet="aggregated by year,ageprofile",x=aggregate_5)
writeData(M_file,sheet="aggregated by Hospital,Group",x=aggregate_6)
writeData(M_file,sheet="aggregated by speciality",x=aggregate_7)
writeData(M_file,sheet="The population",x=aggregate_8)
saveWorkbook(M_file,"Final_Aggregation_result.xlsx")

