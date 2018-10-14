### Automatic processing chain for activity data in Liberia
The material on this repo has been developed to run inside SEPAL (https://sepal.io)

The aim of the processing chain is to combine GFC dataset, with an agricultural commodity layer and a priority landscape layer to produce a deforestation and degradation map.

### Characteristics of the output
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

``` git clone https://github.com/lecrabe/liberia_activity_data_2018.git ```

Open another SEPAL tab, go to Process/rstudio and under the clone directory, open and ``` source()``` the following scripts:

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

##### Accuracy assessment of the maps
Each map (priority landscape 1 and 2, rest of the country) is sampled using the SAE-design tool inside SEPAL

The specific instructions to run the aa_xxx scripts are available in attachment
 

