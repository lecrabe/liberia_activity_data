# Processing chain for the generation activity data in Liberia
The material on this repo has been developed to run inside SEPAL (https://sepal.io)

The aim of the processing chain is to develop activity data for the Liberia REDD+ process

## Characteristics of the FREL 
The FREL combine GFC dataset, with an agricultural commodity layer and a priority landscape layer to produce a deforestation and degradation map.

- Period for 2007-2016

- 30% canopy cover threshold for the forest definition

- 1ha threshold for separation of tree cover loss between deforestation and degradation, and of tree cover between forest and trees outside forest

#### Legend
1: Non Forest

2: Forest

3: Deforestation

4: Degradation

11: Agricultural commodities

12: Trees outside forest

### How to run the processing chain
In SEPAL, open a terminal and start an instance #4 

Clone the repository with the following command:

``` git clone https://github.com/lecrabe/liberia_activity_data.git ```

Open another SEPAL tab, go to Process/rstudio and under the clone directory, open and ``` source()``` the following scripts under `ws_20180301`:

##### s0_parameters.R
This script needs to be run EVERY TIME your R session is restarted. 

It will setup the right parameters and variables environment.

The first time it runs, it can take a few minutes as the necessary packages may be installed.

Once it has run the first time, it takes a few seconds and initializes everything.


##### s1_download_gfc_2016.R
This script needs to be run ONCE.

It will download the necessary data tiles from [GFC repository](https://earthenginepartners.appspot.com/science-2013-global-forest/download_v1.5.html) merge tiles together and clip it to the boundaing boxes of your AOI

It takes ~20 min to run with an instance #4 

##### s2_combine_into_dd_map_v3.R
This script will combine the different layers to produce a DD map

The corresponding decision tree is represented below:

![Alt text](/docs/decision_tree_20181014.jpeg?raw=true "Decision tree")

It takes ~5 min to run with an instance #4 

The final map is cropped to the boundaries of the priority landscapes:

![Alt text](/docs/dd_map_cropped_20181014.png?raw=true "PL crop")

## Accuracy assessment of the maps
Each map (priority landscape 1 and 2, rest of the country) is sampled using the SAE-design tool inside SEPAL

The specific instructions to run the aa_xxx scripts are available in attachment

Formatting of the reference data and additional analyses can be carried out using the r_x scripts. Each of the scripts can be run using the source() button in RStudio. 

##### r0_download_data.R
This script needs to be run ONCE.
It will download the reference data needed to do to the analysis.

##### r1_combine_and_format.R
This script formats, cleans and provides a quick analysis on duplicated sapmles.
If the reference data is updated this script can be rerun

##### r2_activity_data.R
This script is the R script version of the SAEA application in SEPAL 

##### r3_drivers_analysis.R
This script outputs some figures for drivers of deforestation and forest degradation.

## Change detection using the BFAST algorithm

The land cover map developed for the year 2015 is complemented with a detailed mapping of the main commodity farms and combined with land cover changes obtained from analysis of dense time series of satellite imagery using the BFAST algorithm developed by the University of Wageningen.

Example of urban extension on humid zones in the vicinity of Monrovia:

![Alt text](/docs/bfast_swamp_monrovia.png?raw=true "Swamps")

Example of mining in the North of the country:

![Alt text](/docs/bfast_mining.png?raw=true "Mining")
Instructions are available under the `docs/sop/` folder
