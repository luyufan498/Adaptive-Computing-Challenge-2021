# All-in-one Self-adaptive Computing Platform for Smart City Applications 
<!-- {ignore=true} -->

![LOGO](./media/gifs/LOGO_GIF2.gif)


## Content

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Content](#content)
- [1. Introduction](#1-introduction)
  - [Key features/functions](#key-featuresfunctions)
  - [Requirements](#requirements)
- [2. Demo videos](#2-demo-videos)
  - [Branch switch for different scenarios (4k resolution with 4 channels @ 1080p)](#branch-switch-for-different-scenarios-4k-resolution-with-4-channels-1080p)
  - [Inference interval](#inference-interval)
  - [Model size and type](#model-size-and-type)
  - [Adaptive optimization](#adaptive-optimization)
  - [Dynamic Hardware switching](#dynamic-hardware-switching)
- [3. Detailed instructions to run the demo](#3-detailed-instructions-to-run-the-demo)
  - [Environment setup](#environment-setup)
  - [Gstreamer video processing pipes](#gstreamer-video-processing-pipes)
  - [Set up and run host program](#set-up-and-run-host-program)
  - [Switch of Hardware design](#switch-of-hardware-design)
- [4. Gstreamer video processing pipes in the demo](#4-gstreamer-video-processing-pipes-in-the-demo)
  - [Architecture of the video processing pipeline:](#architecture-of-the-video-processing-pipeline)
  - [Management branch:](#management-branch)
  - [Main AI inference branches:](#main-ai-inference-branches)
    - [Branch for people scenario:](#branch-for-people-scenario)
    - [Branch for car scenarios:](#branch-for-car-scenarios)
- [5. The plugin to get and draw real-time data on video frames](#5-the-plugin-to-get-and-draw-real-time-data-on-video-frames)
- [6. Host program](#6-host-program)
  - [Communication between plugins and the host:](#communication-between-plugins-and-the-host)
- [7. Generate Models](#7-generate-models)
  - [Training CarID](#training-carid)
  - [Once-for-all network (OFA)](#once-for-all-network-ofa)
- [8. Experiment results](#8-experiment-results)
  - [Energy consumption (ZCU104)](#energy-consumption-zcu104)
  - [DPU inference latency (ZCU104)](#dpu-inference-latency-zcu104)
  - [FPS results in different scenarios (ZCU104)](#fps-results-in-different-scenarios-zcu104)
- [9. Conclusion](#9-conclusion)
- [10. Appendix](#10-appendix)
  - [Configuration of the JSON file for plugin libs](#configuration-of-the-json-file-for-plugin-libs)
    - [libivas_xdpuinfer.so](#libivas_xdpuinferso)
    - [libivas_xdpuinfer.so](#libivas_xdpuinferso-1)
    - [libivas_runindicater.so](#libivas_runindicaterso)
    - [libivas_sensor.so](#libivas_sensorso)
  - [Shell Scripts](#shell-scripts)
    - [gst_1080P.sh](#gst_1080psh)
    - [gst_4k.sh](#gst_4ksh)

<!-- /code_chunk_output -->



## 1. Introduction

Deep neural networks (DNNs) is the key technique in modern artificial intelligence (AI) that has provided state-of-the-art accuracy on many applications, and due to this, they have received significant interest. The ubiquity of smart devices and autonomous robot systems are placing heavy demands on DNNs-inference hardware with high energy and computing efficiencies along with rapid development of AI techniques. The high energy efficiency, computing capabilities and reconfigurability of FPGA make it a promising platform for hardware acceleration of such computing tasks. 

In this challenge, we have designed a flexible video processing framework on a KV260 SoM, which can be used in a smart camera application for intelligent transportation system (ITS) in smart city. Our framework is not only capable to automatically detect application scenarios (e.g. Car or Pedestrian) using a semantic segmentation and road line detection network, and it is also able to automatically select the best of the DNN models for the application scenarios. Thanks for the dynamic reconfiguration and rum-time management APIs, our system is able to dymanicly switching the DNN inference model at run-time without stop the video pipeline. This finally allows our smart camera system to be truly adaptive, and achieve the best performance in a smarter way.

### Key features/functions
- Support application scenarios detection (e.g. Car, Pedestrian, and many more) using semantic segmentation and road line detection networks.
- Extend the existing VVAS framework (v1.0) with supports of many more DNN models: semantic segmentation, lane detection, pose detection, OFA, and many more when using our flexible JSON interface.
- Support dynamic model switching for both software and hardware video processing pipelines.
- Support run-time performance monitoring with graphic interface on monitor (e.g. Power consumption, FPS, temperature, CPU/Memory, and many more system information).
- Support switching DNN inference models dynamically (e.g. using models with different pruning factors) in the run-time without affecting the system performance.
- Support mitigation to other Xilinx Ultrascale+ MPSoC platform

### Requirements
- Vitis-AI 1.4.1
- Vivado 2021.1
- PetaLinux 2021.1
- VVAS 1.0
- KV260 or any compatible Xilinx Ultrascale+ MPSoC, e.g. ZCU104, Ultra96
- HDMI monitor and cable
- HD camera (Optional)


## 2. Demo videos


### Branch switch for different scenarios (4k resolution with 4 channels @ 1080p)

![Scenario switch](./media/gifs/scenarioswitch.gif)

This video shows the switch of AI processing branches for different scenarios. According to the detected scenarios, the corresponding AI inference will be enabled or disabled.
- Branch 0 (left top): for scenario classification.
- Branch 1 (left bottom): enable in people scenarios.
- Branch 2 (right bottom): enable in car scenarios.

###  Inference interval

![Inference interval](./media/gifs/Inferenceinterval.gif)  

[See HD version in YouTube](https://youtu.be/EY3WWD4jYp4)  
This shows the real-time adjustment of inference interval in Jupyter.

### Model size and type
![Model size](./media/gifs/adjustmodelsize.gif)  

[See HD version in YouTube](https://youtu.be/rI5IlkQ1GYE)  
Running applications tracking for cars: Yolo + CarID + tracking
This video shows the real-time adjustment of model size in Jupyter. There are 4 different model sizes of CarID for different workloads.  This video shows the case that FPS increases significantly with smaller model. 

It is also supported to change types of AI model for different functionalities.    
***Note***: Due to the resolution problems in preprocessing plugins in VVAS 1.0, it requires CPU for do preprocessing tasks.

### Adaptive optimization
![Adaptive optimization](./media/gifs/KV260-optimzation.gif)  

[See HD version in YouTube](https://youtu.be/lOm2LP5qe-M)  
This video shows the performance changes with above adaptive optimization methods. 
- Branch 0 (Segmentation): the inference interval increases (1->5) for less performance cost. 
- Branch 1 (Refindet & Openpose): the inference is disabled, because there is no person.
- Branch 2 (Yolo): the size of the model decreases and the inference interval increases (1->2)  


<!-- ###  UI overlay for one channel and four channels

For one channel and four channels, we provides two kinds of UI overlay for it. 

![](./media/gifs/1080p-carid1.gif)

In the one channel mode, everything will be draw on the same 1080P output. As shown in the video, the segmentation result from management branch and data waveform are put on the top right corner of frames. Users can 

![](./media/gifs/4k_reid_yolo.gif)


In the four channels mode, the output is 4K resolution. The results drawn on 4 1080P videos streams. As shown in the video, the segmentation results from management branch is put on the top left corner, while the data waveforms are put on the top right.  The results from branch 1 and 2 are put on the bottom. -->






### Dynamic Hardware switching
For different cases, we deployed different hardware configurations for switching as well.  
<!-- ![Firmware list](./media/figures/firmwares.png) -->
The bigger DPU (e.g. larger size or higher frequency) consumes more power even if there is no AI inference tasks. Hence, using smaller DPU in low workloads can lower the power consumption.

Currently, we use two different sizes of DPU: 1) B3136 and 2) B4096. The hardware configuration is packaged into the different firmware. 

DPU size :B3136  
<img src="./media/figures/firmware-reid.png" width="400">
<!-- ![Hardware configuration B3136](./media/figures/firmware-reid.png)   -->



DPU size :B4096 Firmware name: cmpk4096 https://github.com/luyufan498/Adaptive-Computing-Challenge-2021/tree/main/firmware   
<img src="./media/figures/firmware-cmpk4096.png" width="400">
<!-- ![Hardware configuration B4096](./media/figures/firmware-cmpk4096.png)   -->

***For details of different hardware configurations and performance adjustments, please see our previous project in Hackster.io:*** [Adaptive deep learning hardware for video analytics](https://www.hackster.io/378085/adaptive-deep-learning-hardware-for-video-analytics-f8d064).


<img src="https://github.com/luyufan498/Adaptive-deep-learning-hardware/raw/main/pic/system.png" width="400">




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

## 3. Detailed instructions to run the demo

There are a number of parts in our demo: 1) Gstreamer video processing pipes, 2) Host program for management and 3) Hardware firmware. Please follow the instructions to run the demo.


### Environment setup 


0. Follow the [official instructions](https://xilinx.github.io/kria-apps-docs/main/build/html/index.html) to set up KV260 (smart camera and AIBox-ReID are needed).


1. (Optional) For your convenience, I have packaged everything you need into [KV260AllYOUNEED.zip](https://drive.google.com/file/d/1N8x7gpwLpRtQlCu-r8Hx58hQGSzwCZY_/view?usp=sharing). You can just download it and extract (overwrite) it to your KV260 system.  If you are using the packaged ZIP file, you can skip the next step and run it directly.

```shell
unzip -o -d / KV260AllYOUNEED.zip
```

### Library, configuration and models

2. Download our customized VVAS libs to kv260 (/opt/xilinx/lib/):
    - dpuinfer for AI inference to support new model and switch: [libivas_xdpuinfer.so](./vvas_so_lib/libivas_xdpuinfer.so)
    - Crop for Openopse: [libivas_crop_openopse.so](./vvas_so_lib/libivas_crop_openopse.so)
    - To support Openopse: [libivas_openpose.so](./vvas_so_lib/libivas_openpose2.so)
    - Tracking update: [libaa2_reidtracker.so](./vvas_so_lib/libaa2_reidtracker.so)
    - Draw chart/wareform: [libivas_sensor.so](./vvas_so_lib/libivas_sensor.so)
    - Draw running indicator: [libivas_runindicater.so](./vvas_so_lib/libivas_runindicater.so)
    - Draw segmentation: [libivas_performancestatus.so](./vvas_so_lib/libivas_performancestatus.so)
    - Draw pose: [libivas_drawpose.so](./vvas_so_lib/libivas_drawpose.so)
    - Draw box/roadline: [libivas_xboundingbox.so](./vvas_so_lib/libivas_xboundingbox.so)

    __Note__: to create your own VVAS libs for your customized model, please follow my projects: [VVAS_CMPK](./VVAS_CMPK).



    Your folder should look like this:

    <img src="./media/figures/libs.png" width="400">


3. **IMPORTANT**: Update gstreamer plugin lib to support multiple inference channels (/usr/lib/).   
    - [libgstivasinfermeta-1.0.so.0](./gst_update/libgstivasinfermeta-1.0.so.0)
    - [libgstivasinfermeta-1.0.so.0.1602.0](./gst_update/libgstivasinfermeta-1.0.so.0.1602.0)

    *Note*: need sudo to overwrite original files.

4. Download [new models](./models/models.zip) and extract to kv260 (/opt/xilinx/share/vitis_ai_library/):

After that your model folder should look like this:
``` shell
xilinx-k26-starterkit-2021_1:~$ tree /opt/xilinx/share/vitis_ai_library/ -L 3
/opt/xilinx/share/vitis_ai_library/
`-- models
    |-- B3136
    |   |-- ENet_cityscapes_pt
    |   |-- SemanticFPN_cityscapes_256_512
    |   |-- caltechlane
    |   |-- carid
    |   |-- densebox_640_360
    |   |-- personreid-res18_pt
    |   |-- refinedet_pruned_0_96
    |   |-- sp_net
    |   |-- ssd_adas_pruned_0_95
    |   |-- yolov2_voc
    |   `-- yolov3_city
    |-- kv260-aibox-reid
    |   |-- personreid-res18_pt
    |   `-- refinedet_pruned_0_96
    `-- kv260-smartcam
        |-- densebox_640_360
        |-- refinedet_pruned_0_96
        `-- ssd_adas_pruned_0_95

20 directories, 0 files

```


5. Download [new json file for VVAS configuration](./json_configuration/ivas.zip) and extract to kv260 (/opt/xilinx/share)  
    **Note**: Please find the appendix section for description of configuration. 


After that your model folder should look like this:
```shell
xilinx-k26-starterkit-2021_1:~$ tree /opt/xilinx/share/ivas/ -L 3
/opt/xilinx/share/ivas/
|-- aibox-reid
|   |-- crop.json
|   |-- dpu_seg.json
|   |-- draw_reid.json
|   |-- ped_pp.json
|   |-- refinedet.json
|   `-- reid.json
|-- branch1
|   |-- drawPipelinestatus.json
|   |-- drawfpsB1.json
|   `-- fpsbranch1.json
|-- branch2
|   |-- dpu_yolo2.json
|   |-- drawPipelinestatus.json
|   |-- drawbox.json
|   |-- fpsbranch2.json
|   `-- ped_pp.json
|-- cmpk
|   |-- analysis
|   |   |-- 4K
|   |   `-- drawTemp.json
|   |-- openpose
|   |   |-- crop.json
|   |   |-- draw_pose.json
|   |   `-- openpose.json
|   |-- preprocess
|   |   |-- resize_cmpk.json
|   |   |-- resize_reid.json
|   |   `-- resize_smartcam.json
|   |-- reid
|   |   |-- carid.json
|   |   |-- crop.json
|   |   |-- draw_reid.json
|   |   `-- reid.json
|   |-- runstatus
|   |   |-- pp1status.json
|   |   `-- pp2status.json
|   `-- segmentation
|       |-- dpu_seg.json
|       |-- dpu_seg_large.json
|       |-- drawSegmentation.json
|       |-- drawSegmentationLR.json
|       |-- drawSegmentationTR.json
|       `-- preprocess_seg_smartcam.json
`-- smartcam
    |-- facedetect
    |   |-- aiinference.json
    |   |-- drawresult.json
    |   `-- preprocess.json
    |-- myapp
    |   |-- dpu_seg.json
    |   |-- dpu_ssd.json
    |   |-- dpu_yolo2.json
    |   |-- drawPLTemp.json
    |   |-- drawPerformance.json
    |   |-- drawPipelinestatus.json
    |   |-- drawPower.json
    |   |-- drawSegmentation.json
    |   |-- drawTemp.json
    |   |-- drawbox.json
    |   |-- preprocess.json
    |   `-- preprocess_seg.json
    |-- refinedet
    |   |-- aiinference.json
    |   |-- drawresult.json
    |   `-- preprocess.json
    |-- ssd
    |   |-- aiinference.json
    |   |-- drawresult.json
    |   |-- label.json
    |   `-- preprocess.json
    |-- yolov2_voc
    |   |-- aiinference.json
    |   |-- drawresult.json
    |   |-- label.json
    |   `-- preprocess.json
    `-- yolov3_city
        |-- aiinference.json
        |-- drawresult.json
        |-- label.json
        `-- preprocess.json

```



6. Now, you should be ready run the video pipeline. Download [scripts to start video pipeline](./shell-scripts/gst_4k.sh) to /home/scripts/.
   
   <!-- The provided shell scripts can take input parameters for the configuration of video processing :
        Help:
        -f video file source
        -b (optional) segmentation use black background
        -r (optional) model for branch 1  [(reid), openopse]
        -s (optional) to sync videos or not -->

    Use the following command to run video pipeline:

        sudo ./scripts/gst_reid_4k2.sh -f <video> -r <AI program>
    
    For details, please see appendix section: [gst_4k.sh](#gst_4ksh)


### Set up and run host program

5. Download [Host program](./host_program/video-management-%20example.ipynb) to kv260. Use Jupyter to run it.
    
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

    ![](/media/figures/jupyter.png)

### Switch of Hardware design

6. (Optional) load the hardware with the B4096 DPU: 

        sudo xmutil unloadapp
        sudo xmutil loadapp cmpk4096

## 4. Gstreamer video processing pipes in the demo
###  Architecture of the video processing pipeline:
 The structure of video processing pipes is as follows. In our demo, there are two types of branches: 1) management branch and 2) main AI inference branch.

![Architecture of the video pipeline ](./media/figures/pipelinestructure.svg)   
(Figure: video pipeline in 1080P mode.)

![](./media/gifs/1080p-carid1.gif)

In the one channel (1080P) mode, everything will be drawn on the same 1080P output. As shown in the video, the segmentation result from management branch and data waveform are put in the top right corner of frames. The size and the position can be adjusted by configuration files.


**In the 1080P mode, the inference information from different branch needs to be drawn on the same frame. However, the original Meta Affixer plugin does not support combination of inference results from different branches. It returns error, when there are multiple inference results. We modified the gstreamer plugin (libgstivasinpinfermeta) to support this feature. Now, the info from the master sink port will be kept, while others will be dropped.**

The shell script for 1080P can be downloaded: [gst_1080p.sh](./shell-scripts/gst_1080P.sh). Please see appendix for more details.

![Architecture of the video pipeline 4k](./media/figures/pipelinestructure4k.svg)    
(Figure: video pipeline in 4K mode.)

**In the 4K mode, there is a separate branch (1080p) to draw waveforms and GUI.**

![](./media/gifs/4k_reid_yolo.gif) 


In the four channels (4k) mode, the output is 4K resolution. The results drawn on 4 1080P videos streams. As shown in the video, the segmentation results from management branch is put in the top left corner, while the data waveforms are put on the top right.  The results from branch 1 and 2 are put on the bottom.

The shell script for 4K can be downloaded: [gst_4k.sh](./shell-scripts/gst_4k.sh.sh). Please see appendix for more details.



### Management branch:

The management branch is responsible for checking the scenario of input videos. As shown in the figures, the management branch runs as an assistant branch with the main AI inference branch.  This branch takes a copied video stream from main AI inference branch as an input, so that it can monitor the video stream simultaneously.

***Note***: considering performance costs, the AI inference in management branch runs on seconds basis. The inference interval can be adjusted by pre-designed interfaces in real time.
    
In our demo, we include two kinds of models for scenario classification:

1. For segmentation 
    There are two models from ***Model Zoo*** are used in our demo to satisfy different requirements of the accuracy:        
    - pt_ENet_cityscapes_512_1024_8.6G_2.0
    - pt_SemanticFPN-resnet18_cityscapes_256_512_10G_2.0 

    *Note1*: The input size of "512*1024" decreases the performance significantly.  
    *Note2*: current VVAS (v1.0) on KV260 does not support segmentation officially. We use custom plugins to support Segmentation.

2. Lane detection:
    Lane detection are very useful to detect the region of interest. We use the model for the model zoo:
    - cf_VPGnet_caltechlane_480_640_0.99_2.5G_2.0
        
    *Note*: current VVAS on KV260 does not support Lane detection officially. We use custom plugins to support Lane detection.


### Main AI inference branches:
The main AI inference branches are responsible to operate AI models for corresponding scenarios. In our demo, we include two typical scenarios for smart city systems: 1) people scenario and 2) car scenario. Videos from different scenarios will be processed by the corresponding branch. If the scenario is not detected, the corresponding branch will also be disabled.

![Video pipeline](./media/figures/pipelines.svg)  
(Figure: Pipeline of the management branch)

The structures of the video pipeline are shown in the figure. Considering the different requirements of applications, the video processing pipe can run one stage or two stage AI inference. 'Video Pipe (a)' represents a typical one stage AI application (e.g. object detection and segmentation), where there is only one AI model to conduct the inference once per frame. 'Video Pipe (b)' represents a two-stage AI application (e.g. tracking, ReID and car plates detection), where there are two AI models ruining simultaneously and the second one may run multiple times due the detection results from the first one.

#### Branch for people scenario:
In people scenario, the demo can run three kinds of tasks: 1) People detection, 2) ReID and 3) Pose detection. 
1. People detection: refinedet. It is from the kv260 ReID example. 
2. ReID: refinedet + crop + personid + tracking. It is from the Kv260 ReID example. 
3. Pose detection: refinedet + crop + spnet.
    ***Note***: we use cf_SPnet_aichallenger_224_128_0.54G_2.0 from Xilinx ***Model Zoo v1.4***.


#### Branch for car scenarios:
In the car scenarios, the demo can run two tasks: 1) object detection and 2) car track.
    
1. Yolo 
    The object detection models we used are from ***Model Zoo v1.4***. We integrate 4 sizes of Yolo models in our demo, so that we can dynamically switch it according the video processing speed.  
    -	dk_yolov2_voc_448_448_34G_2.0
    -   dk_yolov2_voc_448_448_0.66_11.56G_2.0
    - 	dk_yolov2_voc_448_448_0.71_9.86G_2.0
    - 	dk_yolov2_voc_448_448_0.77_7.82G_2.0

2. CarID
    We trained and pruned 4 different size of carid model for model switch.
    - RN18_08 [B3136](./models/models/B3136/carid/RN18_08/RN18_08.xmodel)
    - RN18_06 [B3136](./models/models/B3136/carid/RN18_06/RN18_06.xmodel)
    - RN18_04 [B3136](./models/models/B3136/carid/RN18_04/RN18_04.xmodel)
    - RN18_02 [B3136](./models/models/B3136/carid/RN18_02/RN18_02.xmodel)

    ***Note***: RN18_\<xx\> means the percentage of the pruned weights. For example, RN18_08 means 80% of the weights was pruned, so it is the smallest one here.  

3. OFA and ResNet-50
   The OFA model we used are from ***Model Zoo V2.0***. We integrated them in Vitis-AI library 1.4.
   
    | Model        | Accuracy (Top1/Top5 ImageNet-1k)            | Parameter size (MB) | 
    | ---------- | ----------------- | ----------- | 
    | OFA700 | 74.9%/92.4% | 10.75   |    
    | OFA1000 | 77.0%/92.8% | 18.02   |
    | OFA2000 | 79.7%/94.7% | 32.88   |
    | ResNet-50 | 83.2%/96.5% | 26.22    |

## 5. The plugin to get and draw real-time data on video frames

![sensor](./media/gifs/chart.gif)


In our demo, we designed a dedicated plugin lib (libivas_xdpuinfer.so) to get data and draw waveform. Please see ***Appendix*** section for detailed configuration.

1. Sample data

    The fist functionality of this lib is getting platform status data. Currently, this lib supports 7 different data sources: 5 preset sources (LPD temperature, FPD temperature, total power consumption, PL temperature and FPS) and 2 custom sources. 
    
    When using Preset data sources except FPS, the plugin will read the proc file in the petalinux system to get the platform status. 
    
    When using the custom data sources, the plugin will read the data from a custom file. In this way, users can display custom data or use it in other boards (e.g. we have tested it in ZCU104). 

    FPS is a spacial data sources. Plugin calculates the average FPS of the current video processing branch. However, it can not get the fps information from other branches, which is inconvenient in 4K mode. In our demo, the FPS data can be output to a file, so that the plugin in display branch can read it from custom data files. 
    

2. Draw chart

    Another functionality of this lib is to draw waveforms with acceptable performance cost. As shown in the performance figure, lib can draw the waveform in two different modes: 1) Filled mode and 2) Line mode. The title and real-time data can also be drawn on the frames.
    
    Due to CPU costs of Draw, we also provide a number of parameters for optimization. It is supported to disable the title, data and overlay. There is also an optimization option for this lib, so that you can draw half of pixels only on UV planes to lower the costs. In the best case, filled mode costs 150 us, while the line mode costs 50 us.  
   


## 6. Host program

To trigger dynamical switch, a Python host program to interact with the plugins in video processing pipeline has been also developped. Because the host program is a separate program, it uses IPC to read information and send command. 

To use the named pipe to control the video pipeline, there are a few steps:
1. Install the new library file (so) to replace the official plugins. 
2. Prepare the configuration file (JSON) to set communication methods.   
3. Use Gstreamer to start a pipeline or use the provided shell script to start the video pipeline.
4. Start the Python program to control the video pipeline by sending commands  


All the control interfaces are designed in python. So you can easily control the video pipeline. Here I list the python APIs in our demo for controlling the video pipelines. Please see [host example](./host_program/video-management-%20example.ipynb) for the detailed instructions.

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

In our demo, there are three kinds of Inter-process communication (IPC) to transfer data between host program and gstreamer video pipeline: 

1. Named Pipe (FIFO):  
    
    Named pipe is the main method in our demo to communicate with VVAS plugins. Our custom plugins read new commands from the named pipe. The path of named pipe can be set in the configuration JSON. Currently, in our demo, it is the most stable method to send commands. 

2. File:

    For convenience, it is also supported to used file to report running status of the VVAS processing pipeline. For example, our plugin can output the segmentation results to a file for further analysis. The path of the output file can be set in the configuration. Note: Although it is easy for host program to access, writing file does cost more time. 

3. Shared Memory

    Python does not support ***shared memory*** natively to communicate with VVAS plugins. In our demo, it is used to transfer data between the plugins in different video processing branches.



## 7. Generate Models 

Model Zoo has provided a lot of models, which are easy to use. However, most of those models are not available in other sizes. Hence, we used two method in our demo to generate different size of models: 1) pruning and 2) OFA.

### Training CarID

The CarID was trained using [reid_baseline_with_syncbn framework: ](https://github.com/DTennant/reid_baseline_with_syncbn), please follow their installation and configuration instructions on the Github page.

The CarID model was trained using: [VRIC: Vehicle Re-Identificaton in Context](https://qmul-vric.github.io/)

![VRIC dataset](./media/figures/veri_examples.png)

To prune the model, we used the Torch-Pruning PyTorch package: [Torch-Pruning](https://github.com/VainF/Torch-Pruning);


### Once-for-all network (OFA)

[Once-for-all network (OFA)](https://github.com/mit-han-lab/once-for-all) is also used to generate different sizes of models. 

In the demo, we use OFA trained network as a super network as well as searching algorithm, to generate multiple subnetworks according to our requirements. We firstly use latency as an input parameter in the search algorithm. 

![](./media/figures/ofa_opt.svg)

The figure describes the model generation technique, where Model is optimized in terms of latency and accuracy. In OFA framework, random search is firstly used to determine a set of subnetworks (Subnet N) those are close to the defined latency and evolutionary search is then used to find out the subnetworks (Subnet K) with the highest accuracy among the previously selected set of subnetworks.

## 8. Experiment results

### Energy consumption (ZCU104)
- The total energy consumption has been reduced up to __53.8% and 61.6%__ for car and pedestrian scenarios respectively.

![](./media/figures/energy.png)

### DPU inference latency (ZCU104)
- The detailed DPU inference latencies for each model is shown in the figure below.

![](./media/figures/latency.png)

### FPS results in different scenarios (ZCU104)
- By switching the different sizes of DNN models at run-time, the FPS has been increased immediately. For example, beyond the switch point the average frame rates are raised from __17.04 FPS to 29.4 FPS and 6.9 FPS to 30.8 FPS__ in car and pedestrian scenarios. Meanwhile, due to finishing tasks early, it also saved energy consumption up to __34%__ in overall.

![](./media/figures/FPS.png)

## 9. Conclusion 
In conclusion, in this project, we have developed a flexible framework that could be integrated into the existing Xilinx Vitis-AI (v1.4.1) and VVAS (v1.0) software packages. The proposed framework is capable of offering high-speed dynamic DNN model switching at run-time for both hardware and software pipelines, which is able to further improve both energy and computing efficiency of the existing video processing pipeline. To verify the framework, we have extended the existing VVAS (v1.0) package, and support more DNN model from Vitis-AI model zoo, and performed extensive testing on both Xilinx KV260 and ZCU104 development boards. 


## 10. Appendix

### Configuration of the JSON file for plugin libs
Here we only list the most import libs, please see [JSON example](./json_configuration/) for other libs. 


#### libivas_xdpuinfer.so

```json
{
  "xclbin-location":"/lib/firmware/xilinx/kv260-smartcam/kv260-smartcam.xclbin",
  "ivas-library-repo": "/opt/xilinx/lib/",
  "element-mode":"inplace",
  "kernels" :[
    {
      "library-name":"libivas_xdpuinfer.so",
      "config": {
        "model-name" : "SemanticFPN_cityscapes_256_512",
        "model-class" : "SEGMENTATION",
        "model-path" : "/opt/xilinx/share/vitis_ai_library/models/B3136",
        "run_time_model" : true,
        "need_preprocess" : true,
        "performance_test" : true,
        "debug_level" : 0,
        "ffc_txpath":"/tmp/ivasfifo_tomain",
        "ffc_rxpath":"/home/petalinux/.temp/dpu_seg_rx",
        "interval_frames":3,
        "buff_en":false,
        "branch_id":10
      }
    }
  ]
}
```
libivas_xdpuinfer.so is modified from VVAS example. Hence we only add explaination of new added key:

| Key        | value             | description | 
| ---------- | ----------------- | ----------- | 
| ffc_txpath | path of fifo file | Send data from plugins   |    
| ffc_rxpath | path of fifo file | Send data to plugins   |
| model-class |                 | Two new added class: SEGMENTATION and ROADLINE |
| interval_frames | number of frames   | start interval, it can be set by the command in runtime|
| buff_en | true/false | buffer the inference result of not during the Ai inference interval. Not suitable for segmentation, because it has been included in libivas_postsegmentation.so |
| branch_id | int | unique ID of branch  for following plugin to recognize |




#### libivas_xdpuinfer.so

```json
{
  "xclbin-location":"/usr/lib/dpu.xclbin",
  "ivas-library-repo": "/opt/xilinx/lib",
  "element-mode":"inplace",
  "kernels" :[
    {
      "library-name":"libivas_postsegmentation.so",
      "config": {
        "debug_level" : 0,
        "debug_param": 30,
        
        "ffc_txpath":"/home/petalinux/.temp/segresults",

        "enable_info_overlay" : true,
        "font_size" : 2,
        "font" : 5,
        "thickness" : 2,
        "label_color" : { "blue" : 255, "green" : 255, "red" : 255 },
        
        "info_x_offset":100,
        "info_y_offset":1000,
        
        "enable_frame_overlay":true,
        "y_offset_abs":0,
        "x_offset_abs":0,
        "overlay_width":1920,
        "overlay_height":1080,

        "write_file_path":"/home/petalinux/.temp/segres",
        "enable_w2f":true,

        "classes" : [
                {
                "id":0,
                "name" : "road",
                "blue" : 38,
                "green" : 71,
                "red" : 139 
                },
                {
                  "id":11,
                  "name" : "person",
                  "blue" : 128,
                  "green" : 0,
                  "red" : 0 
                  },
                {
                  "id":13,
                  "name" : "car",
                  "blue" : 200,
                  "green" : 255,
                  "red" : 255
                  },
                {
                  "id":10,
                  "name" : "sky",
                  "blue" : 255,
                  "green" : 191,
                  "red" : 0
                  },
                {
                "id":8,
                "name" : "vegetation",
                "blue" : 0,
                "green" : 255,
                "red" : 69
                },
                {
                "id":9,
                "name" : "terrain",
                "blue" : 139,
                "green" : 60,
                "red" : 17
                }]

      }
    }
  ]
}

```



| Key        | value             | description | 
| ---------- | ----------------- | ----------- | 
| ffc_txpath | string | Send data from plugins   |    
| ffc_rxpath | string | Send data to   plugins   |
| enable_info_overlay | true / false   | draw string or not |
| info_x_offset | int | relative offset of the string    |
| info_y_offset | int | relative offset of the string    |
| enable_frame_overlay | bool  | draw segmentation result or not |
| y_offset_abs | int  |  absolute offset of the segmentation overlay |
| x_offset_abs | int  |  absolute offset of the segmentation overlay |
| overlay_width | int  | width of the segmentation overlay |
| overlay_height | int  |  height of the segmentation overlay |
| write_file_path | path  | path of output file (only the classification result) |
| enable_w2f | bool | enable output file or not|
| classes |  | the pixel color of the segmentation overlay. If you leave it empty, nothing will be drawn |





#### libivas_runindicater.so

It is just a UI plugin to indicate if the branch is running.

```json
{
  "xclbin-location":"/usr/lib/dpu.xclbin",
  "ivas-library-repo": "/opt/xilinx/lib",
  "element-mode":"inplace",
  "kernels" :[
    {
      "library-name":"libivas_runindicater.so",
      "config": {
        "debug_level" : 0,
        "debug_param": 30,
        "default_status":1,
        "x_pos":50,
        "y_pos":50,
        "width":100,
        "ffc_rxpath":"/home/petalinux/.temp/runstatus1_rx"
      }
    }
  ]
}

```

| Key        | value             | description | 
| ---------- | ----------------- | ----------- | 
| default_status |  1 / 0  | 1:run, 0:stop|
| x_pos | | |
| y_pos | | |
| width | | diameter or width |
| ffc_rxpath | string | Send data to   plugins   |


#### libivas_sensor.so


```json
{
  "xclbin-location":"/usr/lib/dpu.xclbin",
  "ivas-library-repo": "/opt/xilinx/lib",
  "element-mode":"inplace",
  "kernels" :[
    {
      "library-name":"libivas_sensor.so",
      "config": {
        "debug_level" : 0,
        "debug_param": 30,
        
        "senor_description":"0:LPD_TMEP,1:FPD_TMEP,2:PL_TEMP,3:POWER,4:FPS. 5~6: custom data (long,float) based on path and scale",
        "senor_mode":1,
        "sensor_path":"/sys/class/hwmon/hwmon1/power1_input",
        "sensor_scale":0.000001,

        "enable_fps":true,
        "fps_window_len":30,
        "enable_fifocom":false,
        "ffc_tx":"/home/petalinux/.temp/pf_tx",
        "ffc_rx":"/home/petalinux/.temp/pf_rx",
        "ffc_description":"only work for fps",

        "enable_info_overlay" :true,
        "title":"FPD Temp (C):",
        "font_size" : 1,
        "font" : 5,
        "label_color" : { "blue" : 255, "green" : 255, "red" : 255 },
        
        "enable_chart_overlay":true,
        "enable_analysis_overlay":true,
        "chart_y":512,
        "chart_x":896,
        "chart_width":512,
        "chart_height":128,
        "chart_type":1,
        "chart_perf_optimize":2,
        "line_thickness" : 1,
        "line_color" : { "blue" : 0, "green" : 200, "red" : 200 },

        "sample_interval_ms":500,
        "max_sample_points":32,
        "max_display_value":100,
        "min_display_value":0
      }
    }
  ]
}

```


| Key        | value             | description | 
| ---------- | ----------------- | ----------- | 
| senor_mode | 0 - 6 |0:LPD_TMEP,1:FPD_TMEP,2:PL_TEMP,3:POWER,4:FPS. 5~6: custom data (long, float) based on path and scale |
| sensor_path | path  | Read data (e.g. power and temperature) from file.  Only works when sensor mode is 5 or 6.  Very usefull for reading proc file system in Linux.|
| sensor_scale |float | Scale of the value from the file. For example, if you want do a power unit conversion from microwatt to watt, you can put 0.001 here  |
| | | |
| enable_fps | bool | This plugin can also report fps of the current branch |
| fps_window_len | int  | Number of point for calculating the average fps  |
| enable_fifocom | bool | Use named pipe to report fps |
| ffc_tx | string | File path of the pipe |
| | | |
| enable_info_overlay | bool | Draw tile on frames|
| title | string | Title of the chart
| | |  |
| enable_chart_overlay | bool | Draw chart or not|
| enable_analysis_overlay| bool | Draw realtime data|
| chart_y | int | |
| chart_x | int | |
| chart_width| int  | |
| chart_height| int  | |
| chart_type| 0 / 1  | Support 2 types: 0: filled and 1: line |
| chart_perf_optimize | 0,1,2,3,4 | Different optimization methods  |
||||
| sample_interval_ms | int | |
| max_sample_points | int | |
| max_display_value | float | |
| min_display_value | float | |



### Shell Scripts

#### gst_1080P.sh

Download the source file: [gst_1080P.sh](./shell-scripts/gst_1080P.sh)

***Note:*** To run this shell script, firmware of ***kv260-smartcam*** has to be loaded.

This script can take parameters as inputs, the following table shows the parameters:

| options  | value | description |
| ---------- | ----------------- | ----------- | 
| -i | file / mipi | file is the default input source |
| -f | path  | video path. It is mandatory when the input video source is file |
| -r |reid / openpose / carid / yolo | the main application to run|

 
For example, If you want to run ***Reid*** application with a video file as input. The command should be as follows:

```shell
<script_path>/gst_1080P.sh -i file -f <video_path> -r reid
```

If you want run ***Yolo*** with MIPI camera as input:



```shell
<script_path>/gst_1080P.sh -i mipi -r yolo
```




#### gst_4k.sh

Download the source file: [gst_4k.sh](./shell-scripts/gst_4k.sh)

***Note*** :to run this shell script, firmware of ***kv260-aibox-reid or cmpk4096*** has to be loaded.


This script can take parameters as inputs, the following table shows the parameters:

| options  | value | description |
| ---------- | ----------------- | ----------- | 
| -f | path  | video path.|
| -r | reid / openpose | the application for branch 1.|
| -b | N/A   | display background video for segmentation |
| -s | N/A   | sync the inference branch |
| 

***Note***: due to the driver issues, ***-i*** is not supported in 4k mode. 

For example, if you want to run an application with two branches: 1) Reid for people and 2) Yolo for Adas.


```shell
<script_path>/gst_4k.sh -f <video_path> -r reid 
```

If you don't want to overlay the segmentation results on original videos:


```shell
<script_path>/gst_4k.sh -f <video_path> -r reid -b
```


<!-- 
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

6. FFC & MMSHARE & FILE -->



