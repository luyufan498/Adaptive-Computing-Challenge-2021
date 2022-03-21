video=/home/petalinux/videos/cars1900.nv12.h264
branch1="reid"

conf_pre_onlyresize="\"/opt/xilinx/share/ivas/cmpk/preprocess/resize_smartcam.json\""
conf_pre_seg="\"/opt/xilinx/share/ivas/cmpk/segmentation/preprocess_seg_smartcam.json\""
conf_pre_seg=$conf_pre_onlyresize
conf_dpu_seg="\"/opt/xilinx/share/ivas/cmpk/segmentation/dpu_seg.json\""
conf_draw_seg="\"/opt/xilinx/share/ivas/cmpk/segmentation/drawSegmentationTR.json\""

while getopts f:br:sh opt
do  
    case $opt in
        f)
            video=$OPTARG
            ;;
        b)
            segback="black"
            ;;
        r)  
            branch1="$OPTARG"
            ;;
        s)
            sync="true"
            echo $sync
            ;;

        :)
            echo "-$OPTARG needs an argument"
            ;;
        h) 
            echo ""
            echo "Help:" 
            echo "-f video file source"
            echo "-b (optional) segmentation use black background"
            echo "-r (optional) model for branch 1  [(reid), openopse]"
            echo ""
            ;;
        *)  
            echo "-$opt not recognized"
            ;;
    esac
done



if [ -f $video ]; then
    echo "find video: $video"
else
    echo "cant find video file: $video"
    exit -1
fi


ivas_xfilter="! queue ! ivas_xfilter kernels-config="

if [ $branch1 == "reid" ]; then
    branch1firstmodel="\"/opt/xilinx/share/ivas/aibox-reid/refinedet.json\""
    branch1crop="\"/opt/xilinx/share/ivas/aibox-reid/crop.json\""
    branch1model="\"/opt/xilinx/share/ivas/cmpk/reid/reid.json\""
    branch1draw="\"/opt/xilinx/share/ivas/cmpk/reid/draw_reid.json\""
    branch1cmd="$ivas_xfilter $branch1firstmodel $ivas_xfilter $branch1crop $ivas_xfilter $branch1model"
    echo "branch 1: use reid"
elif [ $branch1 == "carid" ]; then
    branch1firstmodel="\"/opt/xilinx/share/ivas/smartcam/myapp/dpu_yolo2.json\""
    branch1crop="\"/opt/xilinx/share/ivas/aibox-reid/crop.json\""
    branch1model="\"/opt/xilinx/share/ivas/cmpk/reid/reid.json\""
    branch1draw="\"/opt/xilinx/share/ivas/cmpk/reid/draw_reid.json\""
    branch1cmd="$ivas_xfilter $branch1firstmodel $ivas_xfilter $branch1crop $ivas_xfilter $branch1model"
    echo "branch 1: use reid"
elif [ $branch1 == "openpose" ]; then
    branch1firstmodel="\"/opt/xilinx/share/ivas/aibox-reid/refinedet.json\""
    branch1crop="\"/opt/xilinx/share/ivas/cmpk/openpose/crop.json\""
    branch1model="\"/opt/xilinx/share/ivas/cmpk/openpose/openpose.json\""
    branch1draw="\"/opt/xilinx/share/ivas/cmpk/openpose/draw_pose.json\""
    branch1cmd="$ivas_xfilter $branch1firstmodel $ivas_xfilter $branch1crop $ivas_xfilter $branch1model"
    echo "branch 1: use openopse"
elif [ $branch1 == "yolo" ]; then
    branch1firstmodel="\"/opt/xilinx/share/ivas/smartcam/myapp/dpu_yolo2.json\""
    branch1cmd="$ivas_xfilter $branch1firstmodel"
    branch1draw="\"/opt/xilinx/share/ivas/smartcam/myapp/drawbox.json\""
else
    echo error
    exit -2
fi







gst-launch-1.0 multifilesrc location=\"${video}\" \
! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12, framerate=30/1 \
! tee name=t  \
    ! queue ! ivas_xmultisrc kconfig=$conf_pre_onlyresize  \
    $branch1cmd  \
    ! ima.sink_master ivas_xmetaaffixer name=ima ima.src_master ! fakesink  \
t. \
    ! queue \
    ! ivas_xmultisrc kconfig=$conf_pre_seg  \
    ! queue \
    ! ivas_xfilter kernels-config=$conf_dpu_seg  \
    ! ima2.sink_master ivas_xmetaaffixer name=ima2 ima2.src_master \
    ! fakesink  \
t. \
    ! queue \
    ! ima.sink_slave_0 ima.src_slave_0  \
    ! queue \
    ! ivas_xfilter kernels-config=$branch1draw \
    ! queue  \
    ! ima2.sink_slave_0 ima2.src_slave_0  \
    ! queue ! ivas_xfilter kernels-config=$conf_draw_seg  \
! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawPower.json"  \
! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawTemp.json" \
! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawPerformance.json" \
! queue ! kmssink driver-name=xlnx plane-id=39 sync=false fullscreen-overlay=true 