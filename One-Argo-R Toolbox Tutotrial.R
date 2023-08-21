# GO-BGC workshop R tutorial_Part_1
# August 20, 2023
# Demonstrates the downloading of BGC-Argo float data with sample plots,
# a discussion of available data, quality control flags etc.

# Close figures, clean up workspace, clear command window
cat("\014")
rm(list = ls())

# Fill here the path to the code directory, you can instead set the code
# directory as the working directory with setwd()
path_code = ""
 
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


# Initialize the toolbox--------------------------------------------------
# This function defines standard settings and paths and creates Index
# and Profiles folders in your current path. It also downloads the Sprof 
# index file from the GDAC to your Index folder. The Sprof index is 
# referenced when downloading and subsetting float data based on user 
# specified criteria in other functions.

initialize_argo() # Take some minutes to download the global Index


# Exercise 1: Examine global structures--------------------------------------------------
# Look at the profile ID numbers and available sensors for the
# profiles that have been executed by new GO-BGC float #5906439.

float_idx <-which(Float$wmoid=='5906439') # float IDs for float #5906439 in the S_file index
float_idx 

prof_ids = c(Float$prof_idx1[float_idx]:Float$prof_idx2[float_idx]) # profile IDs for float #5906439 in the S_file index
prof_ids 

dates = Sprof$date[prof_ids] # dates of each profile from float #5906439
dates  

sensors = unique(Sprof$sens[prof_ids]) # sensors available for float #5906439
sensors 


# Exercise 2: SOCCOM float ------------------------------------------------
# In this exercise, we download the NetCDF file for a Southern Ocean  
# BGC float, inspect its contents, show the trajectory, plot profiles
# for unadjusted and adjusted data, and show the effect of adjustments 
# made to the nitrate concentrations.

# Download NetCDF file for float #5904183, a SOCCOM float with multiple seasons under ice
WMO = 5904183
download_float(WMO)

#  Display attributes, dimensions, and variables available in the NetCDF
float_file = nc_open(paste0("Profiles/", WMO,"_Sprof.nc"))

# Extract informational data from the NetCDF
names (float_file$var) 

# Load the float data into R
# We see that NITRATE is available, so load it (along with TEMP and PSAL) from the NetCDF
data_df = load_float_data( float_ids= WMO, # specify WMO number
                        variables=c('PSAL','TEMP','NITRATE'), # specify variables
                        format="dataframe" # specify format;  
)

colnames(data_df) # show data that has been loaded into dataframe


# Show the trajectory of the downloaded float
show_trajectories(float_ids=WMO, 
                  return_ggplot="True" # return the plot to ggplot panel
)


# Show all profiles for salinity and nitrate from the downloaded float
# this plots the raw, unadjusted data, and includes multiple profiles 
# compromised by biofouling that has affected the optics.

show_profiles( float_ids=WMO, 
               variables=c('PSAL','NITRATE'),
               obs='on', # 'on' shows points on the profile at which each measurement was made
               raw="yes" # show the unadjusted data ,
               
)


# this plots the adjusted data.
show_profiles(float_ids=WMO, 
              variables=c('PSAL','NITRATE'),
              obs='on', # 'on' shows points on the profile at which each measurement was made
              raw="no",
)

# this plots the adjusted, good (qc flag 1) and probably-good (qc flag 2) data.
show_profiles(float_ids = WMO, 
              variables=c('NITRATE'),
              obs='on', # 'on' shows points on the profile at which each measurement was made
              qc_flags =c(1:2) # tells the function to plot good and probably-good data
)


# Exercise 3: Ocean Station Papa floats -----------------------------------
# In this exercise, we define a region in the Northeast Pacific along with
# a duration of time, and identify the float profiles matching that
# criteria. We show the trajectories of all the matching floats and plot
# profiles that match the criteria for one of the floats.

# Set limits near Ocean Station Papa from 2020 to 2023
lat_lim=c(45, 60)
lon_lim=c(-150, -135)
start_date="2020-01-01"
end_date="2023-12-31"

# Select profiles based on those limits with specified sensor (Oxygen)

OSP_data= select_profiles ( lon_lim, 
                            lat_lim, 
                            start_date,
                            end_date,
                            mode="D",
                            sensor=c('DOXY'), # this selects only floats with oxygen sensors
                            outside="none" #  All floats that cross into the time/space limits
)  # are identified from the Sprof index. The optional 
# 'outside' argument allows the user to specify
# whether to retain profiles from those floats that
# lie outside the space limits ('space'), time
# limits ('time'), both time and space limits 
# ('both'), or to exclude all profiles that fall 
# outside the limits ('none'). The default is 'none'


# Display the number of matching floats and profiles
print(paste('# of matching profiles:',sum(lengths(OSP_data$float_profs))))

print(paste('# of matching floats:',length(OSP_data$float_ids)))

# Show trajectories for the matching floats
# This function downloads the specified floats from the GDAC (unless the
# files have already been downloaded) and then loads the data for plotting.
# Adding the optional input pair 'color','multiple' will plot different
# floats in different colors
trajectory = show_trajectories(float_ids = OSP_data$float_ids,
                               return_ggplot = TRUE #do not plot and return a ggplot object
) # this plots different floats in different colors

plot(trajectory) # plot the ggplot object

# show domain of interest
trajectory = trajectory + geom_rect( aes(xmin = lon_lim[1], 
                                         xmax = lon_lim[2],
                                         ymin = lat_lim[1],
                                         ymax = lat_lim[2]),
                                     color="black",fill=NA
)


plot(trajectory) # plot the ggplot object


# Load the data for the matching float with format of data frame
data_OSP_df= load_float_data( float_ids= OSP_data$float_ids, # specify WMO number
                              float_profs=OSP_data$float_profs, # specify selected profiles
                              variables="ALL", # load all the variables
                              format="dataframe" # specify format;  
)

# Show sections of oxygen for the second float in the list of OSP floats
# this shows the delayed-model adjusted data 
# mixed layer depth is shown based on the temperature threshold
show_sections( float_ids=OSP_data$float_ids[2], 
               variables=c('DOXY'),
               plot_mld=1,   # tells the function to plot mixed layer depth
               raw="no",
               qc_flags =c(1:2)
               # tells the function to plot raw (unadjusted) data
) # tells the function to plot raw (unadjusted) data


# Show time series of near-surface oxygen evolution for two floats

show_time_series ( float_ids=OSP_data$float_ids[c(2,5)], 
                   variables=c('DOXY'),
                   plot_depth=20, # tells the function to plot the time-series for the given depth 
                   raw="no"   # tells the function to plot the data with given quality flag level
) 

