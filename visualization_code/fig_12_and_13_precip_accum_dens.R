# Fig. 13, 14 and statistics for precipitation
#
# Figure 13 caption:
# Cumulative sum of accumulated daily precipitation for Aug. to Dec. 2020. The
# olive lines indicate the values measured with the Pluvio rain gauge without (P-No correction)
# or with correction (P-Forland, P-Wolff, P-Kochendorfer). The model values are marked in red
# (ICON-LEM) and blue (ICON-NWP). A limit of 0.05 mm h−1 is set for the precipitation based
# on the limit of the Pluvio and bins of 2 mm day−1 are used. Data between 00 and 03 UTC is
# excluded due to the spin-up time.
#
# Figure 14 caption: 
# Probability density distribution of hourly accumulated precipitation from Aug. to
# Dec. 2020. The green line indicates the mean of the Pluvio corrections and red is ICON-LEM. A
# limit of 0.05 mm h−1 is set for the precipitation based on the limit of the Pluvio.
#
#### HEADER ####-------------------------------------------------------------

library("tidyr")
library("ncdf4")
library("dplyr")
library("tibble")
library("ggplot2")

#### MAIN #####----------------------------------------------------------------

ncroot <- ""

ncpath <- "data/nyalesund_precip_nwp_lem_pluvio_1h_202008-12_nospinup.nc"

ncfilename <- paste(ncroot, ncpath, sep = "")
ncfile <- nc_open(ncfilename) 

df_icon <- tibble(time = ncvar_get(ncfile, "time"), 
                  accum_icon_lem = ncvar_get(ncfile,"accum_precip_lem"),
                  accum_icon_nwp = ncvar_get(ncfile, "accum_precip_nwp"))
# Filter floating point chaos in nwp data
df_icon$accum_icon_nwp[df_icon$accum_icon_nwp > 1000] = 0.
df_icon$accum_icon_nwp[df_icon$accum_icon_nwp < 1e-10 ] = 0.

df_pluvio <- tibble(time = ncvar_get(ncfile, "time"), 
                    accum_pluvio = ncvar_get(ncfile,"accum_1h_pluv"),
                    accum_pluvio_k = ncvar_get(ncfile,"accum_1h_kochendorfer"),
                    accum_pluvio_w = ncvar_get(ncfile,"accum_1h_wolff"),
                    accum_pluvio_f = ncvar_get(ncfile,"accum_1h_forland") )
df_icon$time <- as.POSIXct(df_icon$time, origin="2020-08-01 00:00:00", tz = "UTC")
df_pluvio$time <- as.POSIXct(df_pluvio$time, origin="2020-08-01 00:00:00", tz = "UTC")

df_precip <-  tibble(time = ncvar_get(ncfile, "time"), 
                     accum_pluvio = ncvar_get(ncfile,"accum_1h_pluv"),
                     accum_pluvio_k = ncvar_get(ncfile,"accum_1h_kochendorfer"),
                     accum_pluvio_w = ncvar_get(ncfile,"accum_1h_wolff"),
                     accum_pluvio_f = ncvar_get(ncfile,"accum_1h_forland"),
                     accum_icon_lem = ncvar_get(ncfile,"accum_precip_lem"),
                     accum_icon_nwp = ncvar_get(ncfile, "accum_precip_nwp"))
df_precip$time <- as.POSIXct(df_precip$time, origin="2020-08-01 00:00:00", tz = "UTC")
# Filter floating point chaos in nwp data
df_precip$accum_icon_nwp[df_precip$accum_icon_nwp > 1000] = 0.
df_precip$accum_icon_nwp[df_precip$accum_icon_nwp < 1e-10 ] = 0.

df_precip["accum_pluvio_mean"] = (df_precip$accum_pluvio + df_precip$accum_pluvio_k 
                                  + df_precip$accum_pluvio_w + df_precip$accum_pluvio_f )/4
df_precip["accum_pluvio_mean_corr"] = (df_precip$accum_pluvio_k  + df_precip$accum_pluvio_w 
                                       + df_precip$accum_pluvio_f )/3
### 2. Plots ###----------------------------------------------------------------
precip_lim = 0.05 
# The limit is necessary because smaller values are not saved. See pluvio technical details.
df_icon$accum_icon_lem[df_icon$accum_icon_lem>precip_lim]
# In percent
df_hist_two <- data.frame(values=c(df_icon$accum_icon_lem[df_icon$accum_icon_lem>precip_lim],
                                   df_precip$accum_pluvio_w[df_precip$accum_pluvio_w>precip_lim]), 
                          names=c(rep("ICON LES", length(df_icon$accum_icon_lem[df_icon$accum_icon_lem>precip_lim])),
                                  rep("P-Wolff", length(df_precip$accum_pluvio_w[df_precip$accum_pluvio_w>precip_lim]))))

#### 3.3.2 Density plot two in one ####--------------------------------------
g_den_two <- ggplot(df_hist_two, aes(x=values, y=..count../sum(..count..)*100, 
                                     fill=names, color=names)) +
  geom_histogram(position="identity", binwidth=0.1, alpha=0.7, na.rm = TRUE)+ #, size = 0.9, na.rm = TRUE) +
  #scale_fill_manual(values=c("#69b3a2", "#404080")) +
  theme_bw()+
  xlab("Hourly accumulated precipitation (mm)") +
  ylab("Frequency %") +
  xlim(0,4)+
  #labs(title="Accumulated Precipitation", subtitle = "Limit > 0.05 mm/h") +
  theme(legend.position=c(0.73, 0.8),
        legend.title = element_blank(),
        legend.text = element_text(size=10),
        axis.text = element_text(size=11),
        axis.title = element_text(size=11)) +
  scale_color_manual("name",
                     labels=c("ICON-LEM", "P-Wolff"), 
                     values=c( "#ee3359", "#aab110")) +
  scale_fill_manual("name",
                   labels=c("ICON-LEM", "P-Wolff"), 
                   values=c( "#ee3359", "#aab110")) +
  geom_vline(xintercept=c(1.73,2.03), linetype="dashed", color=c("#ee3359","#aab110"))

g_den_two #svg 350*300

# Add lines with % values
100/length(df_icon$accum_icon_lem[df_icon$accum_icon_lem>precip_lim])*95
length(df_icon$accum_icon_lem[df_icon$accum_icon_lem>1.73])

100/length(df_pluvio$accum_pluvio_w[df_pluvio$accum_pluvio_w>precip_lim])*95
length(df_pluvio$accum_pluvio_w[df_pluvio$accum_pluvio_w>2.03])

### 2.4 Daily precipitation-----------------------------------------------------
# Add month and day as numeric values for loop
df_icon$day = as.integer(format(df_icon$time, format="%d"))
df_icon$month = as.integer(format(df_icon$time, format="%m"))
df_pluvio$day = as.integer(format(df_pluvio$time, format="%d"))
df_pluvio$month = as.integer(format(df_pluvio$time, format="%m"))

# Compute daily precipitation 
get_daily_sum <- function(df, var){
  # allocate storage for sum months*days
  data_sum <- numeric(5*31)
  c = 1
  for (m in 8:12){
    for ( d in 1:31){
      # Avoid non existing days
      subset_dim = dim(subset.data.frame(df_icon, day == d & month == m, accum_icon_lem))[1]
      if (subset_dim > 0) {
        data_sum[c] = sum(subset.data.frame(df, day == d & month == m, var), na.rm=TRUE)
      } else {
        data_sum[c] = NA
      }
      c = c+1
    }
  }
  return(data_sum)
}


daily_precip_nwp = round(get_daily_sum(df_icon, "accum_icon_nwp"), digits = 2)
daily_precip_lem = round(get_daily_sum(df_icon, "accum_icon_lem"), digits = 2)
daily_precip_pluvio = round(get_daily_sum(df_pluvio, "accum_pluvio"), digits = 2)
daily_precip_pluvio_k = round(get_daily_sum(df_pluvio, "accum_pluvio_k"), digits = 2)
daily_precip_pluvio_w = round(get_daily_sum(df_pluvio, "accum_pluvio_w"), digits = 2)
daily_precip_pluvio_f = round(get_daily_sum(df_pluvio, "accum_pluvio_f"), digits = 2)

# Total sums
sum(daily_precip_lem, na.rm = TRUE) # 206.29, before with spinup and no con: 228.97
sum(daily_precip_nwp, na.rm = TRUE) # 107.85, before with spinup and no con: 179.42
sum(daily_precip_pluvio, na.rm = TRUE) # 187.47,                   "         210.34
sum(daily_precip_pluvio_f, na.rm = TRUE) # 269.86,                 "         307.84
sum(daily_precip_pluvio_k, na.rm = TRUE) # 227.15,                "          254.34
sum(daily_precip_pluvio_w, na.rm = TRUE) # 265.87,                "          296.19

# Create bins to get (cumulative) bin sum
#df_icon_lem_bins = data.frame(daily_precip_lem, bin=cut(daily_precip_lem, seq(0,max(daily_precip_lem),0.5), include.lowest=TRUE))

get_precip_bin_sum <- function(arr_in, bin_max){
  # create df with bins of 2 mm/d
  df_bins = data.frame(arr_in, bin=cut(arr_in, seq(0,bin_max,2))) #bin=cut(arr_in, seq(0,bin_max,0.5)))   #, include.lowest=TRUE))
  
  # number of bins:
  nbins = length(levels(df_bins$bin))
  bin_sum = numeric(nbins)
  
  for (i in seq(1,nbins,1)){
    bin_sum[i] = sum(df_bins[df_bins$bin == levels(df_bins$bin)[i],1], na.rm = TRUE)
  }
  
  # get cumulative sum of bins
  bin_cumsum = cumsum(bin_sum)
  df_return = data.frame(bin_sum, bin_cumsum, "bins"=levels(df_bins$bin) ) 
  return(df_return)
}

# Use maximum of all so that the number of bins is the same
bin_maxlim = max(daily_precip_pluvio_w, na.rm = TRUE) +2
# dataframe for cumsum
df_precip_bins = tibble( values = c(ICON_LES_bin_cumsum = get_precip_bin_sum(daily_precip_lem, bin_maxlim )$bin_cumsum, 
                                    ICON_NWP_bin_cumsum = get_precip_bin_sum(daily_precip_nwp,  bin_maxlim )$bin_cumsum,
                                    Pluvio_bin_cumsum = get_precip_bin_sum(daily_precip_pluvio,  bin_maxlim )$bin_cumsum,
                                    P_Forland_bin_cumsum = get_precip_bin_sum(daily_precip_pluvio_f, bin_maxlim )$bin_cumsum,
                                    P_Kochendorfer_bin_cumsum = get_precip_bin_sum(daily_precip_pluvio_k,  bin_maxlim )$bin_cumsum,
                                    P_Wolff_bin_cumsum = get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim )$bin_cumsum ),
                         bins = c(rep(seq(1,length(get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim )$bins))*2,times=6)),
                         names=c(rep("y ICON LES", length(get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim )$bins)),
                                 rep("z ICON NWP", length(get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim )$bins)),
                                 rep("a P-No correction", length(get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim )$bins)),
                                 rep("b P-Kochendorfer",  length(get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim )$bins)),
                                 rep("c P-Wolff",  length(get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim )$bins)),
                                 rep("d P-Forland",  length(get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim )$bins))
                         ) )

# I had to reduce the data set by several days in September because they had some errors in the Meteograms.
#### 2.4.2 Cumulative sum plot ###----------------------------------------------
g_cum_daily <- ggplot(data=df_precip_bins, aes(x=bins, y=values, color = names))+
  geom_line(size=0.8)+
  scale_color_manual(labels=c("P-No correction","P-Kochendorfer","P-Wolff",
                              "P-Forland","ICON-LEM", "ICON-NWP"), 
                     values=c( "#06D6A0", "#666a09", "#aab110",
                               "#898f0c","#ee3359", "#3185fc")) +
  xlab("Daily accumulative precipitation mm/day") +
  ylab("Cumulative sum of accum. precip mm") +
  labs(subtitle="Binwidth 2 mm/d")+
  theme_bw()+
  theme(legend.position=c(0.15, 0.75),
        legend.title = element_blank(), 
        axis.text = element_text(size=14),
        axis.title = element_text(size=14),
        legend.text = element_text(size=12)) 

g_cum_daily

#### 2.4.3 Daily precip distrib plot ####-----------------------------------------------------------------
df_hist_daily <- data.frame(values=c(daily_precip_lem,
                                   daily_precip_nwp,
                                   daily_precip_pluvio,
                                   daily_precip_pluvio_k,
                                   daily_precip_pluvio_w,
                                   daily_precip_pluvio_f),
                          names=c(rep("y ICON LES", length(daily_precip_lem)),
                                  rep("z ICON NWP", length(daily_precip_nwp)),
                                  rep("a P-No correction",  length(daily_precip_pluvio)),
                                  rep("b P-Kochendorfer",  length(daily_precip_pluvio_k)),
                                  rep("c P-Wolff",  length(daily_precip_pluvio_w)),
                                  rep("d P-Forland",  length(daily_precip_pluvio_f))
                          ))

tmp_bins = seq(1,length(get_precip_bin_sum(daily_precip_pluvio_w,  bin_maxlim)$bins))
tmp_data = get_precip_bin_sum(daily_precip_lem, bin_maxlim )$bin_sum

daily_precip_distrib_plot <- ggplot(data=df_hist_daily,
                            aes(x=values, y=..count../sum(..count..)*100, color=names))+
  stat_density(geom="line", position="identity", na.rm = TRUE)+
  #facet_wrap(~names) +
  xlab("Accumulated precipitation bin [mm/d]") +
  ylab("Frequency %")+
  labs(subtitle = "Binwidth 2 mm/d") +
  theme_bw()

daily_precip_distrib_plot

#barplot( tmp_data)
df_precip_bins$bins

limits <- c(0.05, 5, 10,15,20,100)
values <- c(100,200,300,400,500)
xlem <- daily_precip_lem[daily_precip_lem >= precip_lim]
xnwp <- daily_precip_nwp[daily_precip_nwp >= precip_lim]
xpluv <- daily_precip_pluvio[daily_precip_pluvio >= precip_lim]
xpluvw <- daily_precip_pluvio_w[daily_precip_pluvio_w >= precip_lim]
xpluvf <- daily_precip_pluvio_f[daily_precip_pluvio_f >= precip_lim]
xpluvk <- daily_precip_pluvio_k[daily_precip_pluvio_k >= precip_lim]


for (i in 1:length(values)){
     print(i)
    xlem[(xlem>=limits[i]) & (xlem < limits[i+1]) & !is.na(xlem)] <- values[i]
    xnwp[(xnwp>=limits[i]) & (xnwp<limits[i+1]) & !is.na(xnwp)] <- values[i]
    xpluv[(xpluv>=limits[i]) & (xpluv<limits[i+1])
                            & !is.na(xpluv)] <- values[i]
    xpluvw[(xpluvw>=limits[i]) & (xpluvw<limits[i+1])
                             & !is.na(xpluvw)] <- values[i]
    xpluvf[(xpluvf>=limits[i]) &(xpluvf<limits[i+1])
                              & !is.na(xpluvf)] <- values[i]
    xpluvk[(xpluvk>=limits[i]) & (xpluvk<limits[i+1])
                                           & !is.na(xpluvk)] <- values[i]
}

x <- c(xlem, xnwp, xpluv, xpluvf, xpluvk, xpluvw)
y <- c(rep("LEM", length(xlem)), rep("NWP", length(xnwp)), rep("Pluvio",length(xpluv)),
       rep("Pluvio-F", length(xpluvf)), rep("Pluvio-K", length(xpluvk)),
       rep("Pluvio-W", length(xpluvw)))
precip_table <- table(x,y)

precip_table
# Number of days with more than 10 mm/d: 
# ICON-LEM=5, NWP=1, P=5, PF=8, PK=7, PW=7
#
# Increase the right margin
par(mar = c(4, 5, 3, 5))
barplot(precip_table,
    #    main = "Stacked bar chart",
      #  sub = "Binned Accumulated preciptation per day",
        names.arg = c("IL", "IN", "P", "PF", "PK", "PW"),
        xlab = "",
        ylab = "Number of days",
        axes = TRUE,
        col = c("#993404", "#FB6A4A",
                "#FED976", "#FFFFCC", 
                "#000fff"),
       legend.text =c("0.05-5","5-10",
                      "10-15", "15-20", ">20"),
       args.legend = list(x = "topright",
                       inset = c(-0.35, 0.55), 
                       title="mm/day"))

### 3. Statistics ###-----------------------------------------------------------
# Reference for equations is Wilks 2011, Chapter 8
# Here again a limit is set to account for pluvio sensitivity

### 3.1. 2x2 Contigency table ###------------------------------------------------
model_t_obs_t = df_icon$time[(df_icon$accum_icon_lem >= precip_lim)&(df_pluvio$accum_pluvio >= precip_lim)]
model_f_obs_f = df_icon$time[(df_icon$accum_icon_lem < precip_lim)&(df_pluvio$accum_pluvio < precip_lim)]
model_t_obs_f = df_icon$time[(df_icon$accum_icon_lem >= precip_lim)&(df_pluvio$accum_pluvio < precip_lim)]
model_f_obs_t = df_icon$time[(df_icon$accum_icon_lem < precip_lim)&(df_pluvio$accum_pluvio >= precip_lim)]

a = length(model_t_obs_t)   # with spinup 216
b = length(model_t_obs_f)   # with spinup 205
c = length(model_f_obs_t)   # with spinup 206
d = length(model_f_obs_f)   # with spinup 2422
# Total length is same as sum of above.
n = length(df_icon$time)    # with spinup 3047

# Proportion correct (either false-false or true-true)
PC = (a+d)/n    # 0.87, this is good
# False alarm rate
F = b/(b+d)     # 0.08, this is good
# Heidke skill score
HSS = 2*(a*d-b*c) / ((a+c)*(d+c)+(a+b)*(d+b)) # 0.43, this is good 

2129/24

3047/24
length(df_pluvio$accum_pluvio >= precip_lim)/24

1440/60

#### 3.2 Extrema 
daily_precip_nwp
daily_precip_pluvio_w
