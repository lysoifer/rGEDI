#'Get GEDI Plant Area Index (PAI) Profile (GEDI Level2B)
#'
#'@description This function extracts the Plant Area Index (PAI) Profile from GEDI Level2B data.
#'
#'@usage getLevel2BPAIProfile(level2b)
#'
#'@param level2b A GEDI Level2B object (output of [readLevel2B()] function).
#'An S4 object of class "gedi.level2b".
#'
#'@return Returns an S4 object of class [data.table::data.table]
#'containing the elevation and relative heights.
#'
#'@seealso \url{https://lpdaac.usgs.gov/products/gedi02_bv002/}
#'
#'@details Characteristics. Flag indicating likely invalid waveform (1=valid, 0=invalid).
#'\itemize{
#'\item \emph{beam} Beam identifier
#'\item \emph{shot_number} Shot number
#'\item \emph{algorithmrun_flag} The L2B algorithm is run if this flag is set to 1 indicating data have sufficient waveform fidelity for L2B to run
#'\item \emph{l2b_quality_flag} L2B quality flag
#'\item \emph{delta_time} Transmit time of the shot since Jan 1 00:00 2018
#'\item \emph{lat_lowestmode} Latitude of center of lowest mode
#'\item \emph{lon_lowestmode} Longitude of center of lowest mode
#'\item \emph{elev_highestreturn} Elevation of highest detected return relative to reference ellipsoid
#'\item \emph{elev_lowestmode} Elevation of center of lowest mode relative to reference ellipsoid
#'\item \emph{height_lastbin} Height of the last bin of the pgap_theta_z, relative to the ground
#'\item \emph{pai_z} Plant Area Index profile
#'#'\item \emph{pavd_z} Plant Area Volume Density profile
#'}
#'
#'@examples
#'# Specifying the path to GEDI level2B data (zip file)
#'outdir = tempdir()
#'level2B_fp_zip <- system.file("extdata",
#'                   "GEDI02_B_2019108080338_O01964_T05337_02_001_01_sub.zip",
#'                   package="rGEDI")
#'
#'# Unzipping GEDI level2A data
#'level2Bpath <- unzip(level2B_fp_zip,exdir = outdir)
#'
#'# Reading GEDI level2B data (h5 file)
#'level2b<-readLevel2B(level2Bpath=level2Bpath)
#'
#'# Extracting GEDI Plant Area Index (PAI) Profile (GEDI Level2B)
#'level2BPAIProfile<-getLevel2BPAIProfile(level2b)
#'head(level2BPAIProfile)
#'
#'close(level2b)
#'@import hdf5r
#'@import utils
#'@importFrom hdf5r H5File
#'@export
getLevel2BProfiles<-function(level2b){
  level2b<-level2b@h5
  groups_id<-grep("BEAM\\d{4}$",gsub("/","",
                                     hdf5r::list.groups(level2b, recursive = F)), value = T)
  m.dt<-data.table::data.table()
  pb <- utils::txtProgressBar(min = 0, max = length(groups_id), style = 3)
  i.s=0
  for ( i in groups_id){
    i.s<-i.s+1
    utils::setTxtProgressBar(pb, i.s)
    level2b_i<-level2b[[i]]
    m<-data.table::data.table(
      beam<-rep(i,length(level2b_i[["shot_number"]][])),
      shot_number=level2b_i[["shot_number"]][],
      algorithmrun_flag=level2b_i[["algorithmrun_flag"]][],
      l2b_quality_flag=level2b_i[["l2b_quality_flag"]][],
      # ADDING QUALITY CONTROL PARAMETERS (SEE https://daac.ornl.gov/GEDI/guides/GEDI_HighQuality_Shots_Rasters.html)
      l2a_quality_flag = level2b_i[["l2a_quality_flag"]][],
      sensitivity = level2b_i[["sensitivity"]][],
      surface_flag = level2b_i[["surface_flag"]][],
      stale_return_flag = level2b_i[["stale_return_flag"]][],
      rh100 = level2b_i[["rh100"]][],
      omega = level2b_i[["omega"]][],
      l2b_algrun_flag = level2b_i[["algorithmrun_flag"]][],
      degrade_flag = level2b_i[["geolocation/degrade_flag"]][],
      dem = level2b_i[["geolocation/digital_elevation_model"]][],
      delta_time=level2b_i[["geolocation/delta_time"]][],
      lat_lowestmode=level2b_i[["geolocation/lat_lowestmode"]][],
      lon_lowestmode=level2b_i[["geolocation/lon_lowestmode"]][],
      elev_lowestmode=level2b_i[["geolocation/elev_lowestmode"]][], # = ground_elev
      ls_waterp = level2b_i[["land_cover_data/landsat_water_persistence"]][],
      urb_prop = level2b_i[["land_cover_data/urban_proportion"]][],
      leafoff_flag = level2b_i[["land_cover_data/leaf_off_flag"]][],
      leaf_off_doy = level2b_i[["land_cover_data/leaf_off_doy"]][],
      leaf_on_doy = level2b_i[["land_cover_data/leaf_on_doy"]][],
      cover = level2b_i[["cover"]][],
      pai = level2b_i[["pai"]][],
      pai_z=t(level2b_i[["pai_z"]][,1:level2b_i[["pai_z"]]$dims[2]]),
      pavd_z=t(level2b_i[["pavd_z"]][,1:level2b_i[["pavd_z"]]$dims[2]]))
    m.dt<-rbind(m.dt,m)
  }
  colnames(m.dt)<-c("beam","shot_number","algorithmrun_flag",
                    "l2b_quality_flag", "l2a_quality_flag",
                    "sensitivity",
                    "surface_flag",
                    "stale_return_flag",
                    "rh100", "omega",
                    "l2b_algrun_flag",
                    "degrade_flag",
                    "dem",
                    "delta_time","lat_lowestmode",
                    "lon_lowestmode",
                    "elev_lowestmode",
                    "ls_waterp",
                    "urb_prop",
                    "leafoff_flag",
                    "leafoff_doy",
                    "leafon_doy",
                    "cover",
                    "pai",
                    paste0("pai_z",seq(0,30*5,5)[-31],"_",seq(5,30*5,5),"m"),
                    paste0("pavd_z",seq(0,30*5,5)[-31],"_",seq(5,30*5,5),"m")
  )
  close(pb)
  return(m.dt)
}
