# GO-BGC workshop R tutorial_Part_2
# August 20, 2023
# Retrieve the float data with oxygen measurements to 
# study the oxygen dynamics in the North subpolar Atlantic


# Close figures, clean up workspace, clear command window
cat("\014")
rm(list = ls())


# Fill here the path to the code directory, you can instead set the code
# directory as the working directory with setwd()
path_code = "/Users/yibinhuang/Downloads/BGC-ARGO_R_WORKSHOP-in_progress"


# One-Argo toolbox setting up
##############
##############
# Load the functions and libraries--------------------------------
setwd(path_code)
func.sources = list.files(path_code,pattern="*.R")
func.sources = func.sources[which(func.sources %in% c('Main_workshop.R',
                                                      "bgc_argo_workshop_R_license.R")==F)]

if(length(grep("Rproj",func.sources))!=0){
  func.sources = func.sources[-grep("Rproj",func.sources)]
}
invisible(sapply(paste0(func.sources),source,.GlobalEnv))

aux.func.sources = list.files(paste0(path_code,"/auxil"),pattern="*.R")
invisible(sapply(paste0(path_code,"/auxil/",aux.func.sources),source,.GlobalEnv))

initialize_argo() # Take some minutes to download the global Index
###############
###############



# ============== User Inputs ================================
  
# lat and lon bounds for North Atlantic.
lat_NA = c( 50,70)
lon_NA = c(-60,20);

# date range from 2022 to 2023

t1="2022-01-01"
t2="2023-12-31"

# list of variables to extract
vars2get = c('DOXY') # Only allow to specify one sensor in the current function settiing

#  choose which QFs you want to extract
QF2use = c(1, 2, 8); #  good and probably good data. 
                     #  Need to add 8 because for some Provor floats, 
                    # salinity is interpolated onto DOXY so it gets a 8 flag. 

# get float ID and profiles that have Oxygen, and is in Delayed mode
NA_DOXY_data= select_profiles ( lon_NA, 
                            lat_NA, 
                            t1,
                            t2,
                            sensor=vars2get, # this selects only floats with oxygen sensor
                            outside="none",
                            mode="D") # Delayed-mode



# make plot of location
trajectory = show_trajectories(float_ids = NA_DOXY_data$float_ids,
                               return_ggplot = TRUE #do not plot and return a ggplot object
) # this plots different floats in different colors

trajectory = trajectory + geom_rect( aes(xmin = lon_NA[1], 
                                         xmax = lon_NA[2],
                                         ymin = lat_NA[1],
                                         ymax = lat_NA[2]),
                                     color="black",fill=NA
)

plot(trajectory)



# extract data and put into a table and csv
# ================ DOXY Floats ====================
# Load the float data in the R with the format of data frame if "format" is specificed
data_DOXY = load_float_data( float_ids=NA_DOXY_data$float_ids, # specify WMO number
                           format="dataframe", # specify format; 
                           variables=c(vars2get,"TEMP","PSAL"),
)


# remove lines where DOXY, TEMP, PSAL, or PRES are NaNs. 
data_DOXY= subset(data_DOXY,
                  data_DOXY$TEMP_ADJUSTED_QC %in% QF2use)

data_DOXY= subset(data_DOXY,
                  data_DOXY$PRES_ADJUSTED_QC%in% QF2use)


data_DOXY= subset(data_DOXY,
                  data_DOXY$PSAL_ADJUSTED_QC %in% QF2use)

data_DOXY= subset(data_DOXY,
                  data_DOXY$DOXY_ADJUSTED_QC %in% QF2use)


# Export the float data for further analysis ------------------------------------
setwd(path_code)
# The output file stored in "path_code"
write.table(data_DOXY, 
            'NAtlantic_DOXYdata.csv',
            row.names = F);


