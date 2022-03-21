# xilinx adaptive challenge


## Introducion



## Demo videos


### Branch switch for different scenarios

![Scenario switch](./media/gifs/scenarioswitch.gif)  
Using crocessponding AI branch for different scenairos.
- Branch 0 (left top): for scenairo detection.
- Branch 1 (left bottom): enable in people scenairos.
- Branch 2 (right bottom): enable in car scenairos.

###  Inference interval
![Inferece interval](./media/gifs/Inferenceinterval.gif)  
https://youtu.be/EY3WWD4jYp4  
Realtime adjustment of inference interval in Jupyter.

### Model size
![Model size](./media/gifs/adjustmodelsize.gif)  
https://youtu.be/rI5IlkQ1GYE  
Running applications tracking for cars: Yolo + CarID   
Realtime adjustment of Model size. There are 4 different model size of CarID.  
The fps increases when using smaller model. 


### Adaptive optimization
![Adaptive optimization](./media/gifs/KV260-optimzation.gif)  
https://youtu.be/lOm2LP5qe-M  
This video show the performnace changes after using adpative optimization. 
- Branch 0 (Segmentation):  the inference interval increases (1->5) for less performace cost. 
- Branch 1 (Refindet&Openpose): the inferece is disabled, because there is no person.
- Branch 2 (Yolo): the size of the model decreases and the inference intrerval increases (1->2)  


### Hardwre switch
For different cases, we deployed different hardware configuration for switch.  
<!-- ![Firmware list](./media/figures/firmwares.png) -->
The bigger DPU (larger size or higher frequency) consumes more power even if there is no AI inference tasks. Hence, using smaller DPU in low workloads can lower the power consumption.

Currently, we delpoyed two sizes of DPUs: 1) B3136 and 2) B4096. The hardwre configuration are packaged into the different firmwares. 

![Hardware configuration B3136](./media/figures/firmware-reid.png)  
DPU size :B3136

![Hardware configuration B4096](./media/figures/firmware-cmpk4096.png)  
DPU size :B4096



<!-- ## Adaptive
1. Auto branch switch according to the input videos:
    - branch for cars
    - branch for people

2. Realtime adjustment of inference interval accoring to the platform status (e.g. fps, power and tempure):
    - buff or not buff

3. Realtime model swith accoding to the platform status
    - functionality of the program
    - size of the running model

4. Adaptive switch of the DPU size:
    - size of the DPU
    - frequency of the DPU
    - number of DPUs

## Use Model in the demo design -->

## To run the demo

Demo Includes parts: 1) video pipelines, 2) host program for management and 3) hardware firmwares. The details of the design is in the following sections. This section inlcudes the guide to start the demo.

0. Follow the [official instructions](https://xilinx.github.io/kria-apps-docs/main/build/html/index.html) to set up KV260 (smart camera and AIBox-ReID are needed).

1. Download VVAS libs to kv260 (/opt/xilinx/lib/):
    - dpuinfer for AI inference to support new model and switch: [libivas_xdpuinfer.so](./vvas_so_lib/libivas_xdpuinfer.so)
    - Crop for Openopse: [libivas_crop_openopse.so](./vvas_so_lib/libivas_crop_openopse.so)
    - To support Openopse: [libivas_openpose.so](./vvas_so_lib/libivas_openpose.so)
    - Tracking update: [libaa2_reidtracker.so](./vvas_so_lib/libaa2_reidtracker.so)
    - Draw chart/wareform: [libivas_sensor.so](./vvas_so_lib/libivas_sensor.so)
    - Draw running indicator: [libivas_runindicater.so](./vvas_so_lib/libivas_runindicater.so)
    - Draw segmentation: [libivas_performancestatus.so](./vvas_so_lib/libivas_performancestatus.so)
    - Draw pose: [libivas_drawpose.so](./vvas_so_lib/libivas_drawpose.so)
    - Draw box/roadline: [libivas_xboundingbox.so](./vvas_so_lib/libivas_xboundingbox.so)

2. **IMPORTANT**: Update gstreamer plugin lib to support multiple inference channel (/usr/lib/).   
    
    - [libgstivasinpinfermeta-1.0.so.0](./gst_update/libgstivasinpinfermeta-1.0.so.0)
    - [libgstivasinpinfermeta-1.0.so.0.1602.0](./gst_update/libgstivasinpinfermeta-1.0.so.0.1602.0)

    *Note*: need sudo to overwrite original files.

2. Download [new models](./models/models.zip) and extract to kv260 (/opt/xilinx/share/vitis_ai_library/):


3. Download [new json file for VVAS configuration](./json_configuration/ivas.zip) and extract to kv260 (/opt/xilinx/share)  
    **Note**: Please find the separate section for configuration description. 

4. Download [scripts to start video pipeline](./shell-scripts/gst_reid_4k.sh) to /home/scripts/.
    
    Now you should be able to run the video pipeline. 

    The shell scripts can take input parameter for different requirements:


        Help:
        -f video file source
        -b (optional) segmentation use black background
        -r (optional) model for branch 1  [(reid), openopse]
        -s (optional) to sync videos or not

    Use the following command to run video pipeline:

        sudo ./scripts/gst_reid_4k2.sh -f <video> -r <AI program>


5. Download [Host program](./host_program/video-management-%20example.ipynb) to kv260. Use jupyter to run it.
    
    Example use of python interfaces:
    ```python
    traffic_modelctr = kv260adpModelCtr()
    # Set UI with pipe path
    traffic_modelctr.setIndicaterUI('on',FFC_UI_BRANCH2)
    traffic_modelctr.setIndicaterUI('off',FFC_UI_BRANCH1)
    # SET branch with pipe path
    traffic_modelctr.setDPUenable('on',FFC_DPU_BRANCH_CAR_CTR)
    traffic_modelctr.setDPUenable('off',FFC_DPU_BRANCH_PEO_CTR)
    # SET inference interval with pipe path
    traffic_modelctr.setDPUInvteral(30,FFC_DPU_SEG_CTR)
    # Create a ctr with pipe path and set new model
    modelctr = kv260adpModelCtr("/home/petalinux/.temp/dpu_seg_rx")
    modelctr.setNewModel("ENet_cityscapes_pt","SEGMENTATION","/opt/xilinx/share/vitis_ai_library/models/B3136/")
    ```

6. (Optional) load the hardware with the B4096 DPU: 

        sudo xmutil unloadapp
        sudo xmutil loadapp cmpk4096



## Video pipelines in the demo:
###  Architecture of the video pipeline and management branch:
The management branch is responible for checking the scenerio of input videos. The structure of video pipeline is (1080P mode) as follow:

![architecture of the video pipeline ](./media/figures/pipelinestructure.svg)  
(Figure: video pipeline in 1080P mode.)

As shown in the figure, the management branch runs as a asistant branch with the main task branch. Using a copyed stream from main branch, the management branch can check the input scenarios. 

**In the 1080P mode, the inference information from different branch needs to be drawn on the same frame. However the original Meta Affixer plugin does not support conbination of inference results from different branches. it returns error, when there are muliple inference results. We modified the gstreamer plugin (libgstivasinpinfermeta) to support this feature. Now, the info in the master sink port will be kept, while others will be dropped.**

Considering that the scenairos will not change frequenctly, the inference runs every few seconds. The inference interval can be adjusted by pre-designed interfaces.
    
In our demo, we included two kinds of model for scenerio classification: 
1. For segmentation 
    There are two models from ***Model Zoo*** are used in our demo to satisfy different requirments of the accuracy:        
    - pt_ENet_cityscapes_512_1024_8.6G_2.0
    - pt_SemanticFPN-resnet18_cityscapes_256_512_10G_2.0 

    *Note1*: The input size of "512*1024" decreases the performance significantly.  
    *Note2*: current VVAS on KV260 does not support segmentation officially. we use custom pulgins to support Segmentation.

2. Lane detection:
    Lane detection are very useful to detect the region of interest. We use the model for the model zoo:
    - cf_VPGnet_caltechlane_480_640_0.99_2.5G_2.0
        
        *Note*: current VVAS on KV260 does not support Lane detection officially. we use custom pulgins to support Lane detection.


### Main task branches:
The main video pipelines are responible for operating AI models for corresponding scenors. In our demo, we implemented two typical scenarios in smart city system: 1) people and 2) car scenarios. In each scenario, we also intregarte a number of video pipelines for dynamical switch. 

![Video pipeline](./media/figures/pipelines.svg)  
(Figure: Pipeline of the management branch)

the structures of the video pipeline are shown in the figure. Considering the different applications, the video pipeline can run one stage or two stage AI inference.


#### Branch for people scenarios:
In people scenarios, the demo can run three kinds of task: 1) people detection, 2) REID and 3) openopse, and there are three kinds of models are used in the demo.
1. refinedet. It is from the kv260 REID example.
2. PesionID. It is from the Kv260 REID example.
3. Openpose. 
    - cf_SPnet_aichallenger_224_128_0.54G_2.0


#### Bracn for car scenarios:
In the car scenarios, the demo can run two task: 1) object detection and 2) car track.
    
1. yolo 
    The object detection model we used here is Yolo from Model Zoo. 
    -	dk_yolov2_voc_448_448_34G_2.0
    -   dk_yolov2_voc_448_448_0.66_11.56G_2.0
    - 	dk_yolov2_voc_448_448_0.71_9.86G_2.0
    - 	dk_yolov2_voc_448_448_0.77_7.82G_2.0

    *Note*: In the demo, there are 4 different sizes for realtime swith and performance adjustment. 

2. CarID
    We traned our own model for carid.
    ********
    - RN18_08
    - RN18_06
    - RN18_04
    - RN18_02

3. OFA (Test)


2) people branch
    refinedet  (model zoo & offically supported)
    personID   (from REID)
    openpose  (model zoo & self made)

3) car/traffic branch
    yolo voc2 ()(model zoo & offically supported)
    carID (5 different sizes) (self made & offically supported)  



## Host program

To trigger dynamical switch, there is a python host program to interact with video pipeplines. Because the host program is a separate program, it use IPC to read infomation and send command. 

To use the named pipe to control the video pipeline, there are a few step:
1. Install the new library file (so) to replace the official plugins. 
2. Prepare the configuration file (json) to set communication methods.   
3. Use gstreamer to start a pipeline or use the my shell script to strat the video pipeline.
4. start the Python program to control the video pipeline by sending commands  


All the control interfaces are designed in python. So you can easily control the video pipeline. Here I list the python APIs in our demo for controling the video pipelines. Please see [host example](./host_program/video-management-%20example.ipynb) for detailed usage.

```python
class kv260adpModelCtr(object):    
    def __init__(self,write_path="",*args, **kw):        
    def setNewModel(self,modelname, modelclass, modelpath, write_path = ""):
    def setNewREIDModel(self,modelname,modelpath,write_path = ""):
    def setDPUInvteral(self,inverteral,write_path = ""):
    def setDPUenable(self,enable,write_path = ""):
    def setIndicaterUI(self,on,write_path = ""):
    def getFPSfromFile(self, file):
    def getSegmentationResult(self,file):

```


### Communication between plugins and the host:

In our demo, there are three kinds of  Inter-process communication (IPC) to transfer data between host program and gstreamer video pipeline: 
1. named pipe (fifo)
    named pipe is the main method to send control commonds to the video pipeline. The custom plugin reads new commonds from named pipe before processing the new frame. Users can set read or send named pipe for dpuinfer and draw plugins. Currently, it is the most stable method for communcation.

2. file
    for convenience, it is supported to used file to report video pipeline status. For example. our plugin can output the segmentation results to a file for further analysis. Writing file cost more time, but it is easy for host program to access. 

3. shared memory
    Python does not support shared memory natively. In our demo, it is used between pipelines to share information between different branches. 



### Generate Models
#### Use Models from Model Zoo
#### Tranning CarID
#### OFA model


## Modification in VVAS and Gst:

### dpuinfer plugin for supporting new models
The DPU-infer plugins are modified to support new models and the features of realtime adjustment.

1. New models:
To support new models, we modified the offical dpuinfer plugin: 1) Dpu.


we mainly used the models supported by Vitis AI library.  

Basically, we use the model the Vitis AI library and 








Because the current version of VVAS plugin on kv260 does not support the features 



2. Senor plugin to monitor the realtime status
3. Chart plugin to draw wareform
4. Modification in other officical plugins
5. Gst Modification



## Python and shell scripts:

5. Custom VVAS plugins:











### New



## demo to show final resualt
.......


### Model used in our demo

There is one branch for scenario control and two branches for corresponding AI inference.

In our demo, we integrated 5 different types of AI models: 

1) control branch
    segmentation ( s1,s2 ),  
    roadline (model zoo &  self made)

2) people branch
    refinedet  (model zoo & offically supported)
    personID   (from REID)
    openpose  (model zoo & self made)

3) car/traffic branch
    yolo voc2 ()(model zoo & offically supported)
    carID (5 different sizes) (self made & offically supported)  


### pipeline generated in our demo


The control branch is used to provide necessary information for scenario (car or people) detection and control.
    segmentation*
    roadline

The prople branch provides two kinds of mode for people scenario:
    refinedet -> crop -> id* -> tracking
    refinedet -> crop -> openopose
    refinedet (no tracking)

The car branch provides two kinds of mode for car  scenario:
    yolo_v2(adas)* -> crop -> carid* -> tracking
    yolo_v2(adas)* (no tracking)

The test branch:
    yolo_v2(adas)* -> ofa
### functionality switch - adaptivity in functionality

//--------------------------------------------///

1. branch for car : carid
2. branch for people : openpose (with draw and modified crop pulgin) / REID
3. branch for control: segmeation (with draw) and roadline (with draw)

## 4K or 1080P








### hardware switch
1. size of the DPU
    B3136
    B4096
2. frequence of the DPU
    100  200
    275  550


### model size swith
1. carid: 5 different size
2. segmentation: 2 different size

### inference control
1. inference interval
2. enable and disable
3. isbuff

### chart pulgin
1. draw/fill line
6. sample rate
7. refresh rate

2. fps
3. power/temp
4. file
5. DPU time




## code and guide
1. github code: VVAS 
    - build environmemnt
    - compile

2. JSON control
    - ffc 
    - DPU 
        - new model
            - seg
            - road
        - interval
        - enable
        - buff
    - chart 
        - fps
        - power
        - file
        - ffc
        - txt
    - crop
        - w & h
    - post seg
        - txt
        - overlay
    - reid / carid

3. gst
    - inference meta mixed

4. hardware generated

5. preparing model
    - seg: two
    - carid: 5
    - roadline
    - openpose

6. FFC & MMSHARE & FILE



