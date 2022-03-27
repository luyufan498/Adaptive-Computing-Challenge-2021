#! /bin/sh
video=/home/petalinux
segback="ori"
branch1="reid"
sync="false"
input="file"

conf_pre_onlyresize="\"/opt/xilinx/share/ivas/cmpk/preprocess/resize_reid.json\""
conf_pp1_status="\"/opt/xilinx/share/ivas/cmpk/runstatus/pp1status.json\""
conf_pp2_status="\"/opt/xilinx/share/ivas/cmpk/runstatus/pp2status.json\""
conf_pp1_recordfps="\"/opt/xilinx/share/ivas/branch1/fpsbranch1.json\""
conf_pp2_recordfps="\"/opt/xilinx/share/ivas/branch2/fpsbranch2.json\""
conf_dpu_seg="\"/opt/xilinx/share/ivas/cmpk/segmentation/dpu_seg.json\""
conf_draw_seg="\"/opt/xilinx/share/ivas/cmpk/segmentation/drawSegmentation.json\""

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



if [ $input == "file" ]; then

    if [ -f $video ]; then
        echo "find video: $video"
    else
        echo "cant find video file: $video"
        exit -1
    fi

    input_source="multifilesrc location=\"${video}\" ! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12"
elif [ $input == "mipi" ]; then 
    input_source="mediasrcbin media-device=/dev/media0 v4l2src0::io-mode=dmabuf v4l2src0::stride-align=256 !video/x-raw, width=1920, height=1080, format=NV12, framerate=30/1"
else
    echo "unsupport video source :$source [mipi,file]."
    exit -1
fi


if [ $sync == 'false' ]; then
    videosrc_cmd="multifilesrc location=\"${video}\" ! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12"
    tee1_name="maintee1"
    tee2_name="maintee2"
    teeseg_name="tseg"
    tee1_cmd=$videosrc_cmd"!tee name=$tee1_name"
    tee2_cmd=$videosrc_cmd"!tee name=$tee2_name"
    teeseg_cmd=$videosrc_cmd"!tee name=$teeseg_name"
    echo $tee1_cmd
    echo $tee2_cmd
    echo $teeseg_cmd
else
    echo "sync video pipeline (fps will drops)"
    tee1_name="maintee"
    tee2_name=$tee1_name
    teeseg_name=$tee1_name
    tee1_cmd=$videosrc_cmd"!tee name=$tee1_name"
    tee2_cmd="$tee2_name."
    teeseg_cmd="$teeseg_name."
    echo tee2_cmd
fi


if [ $segback == "black" ]; then
    segbackcmd="multifilesrc location=\"/home/petalinux/videos/black.nv12.h264\" ! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12"
    echo "use black background for segmentation."
else
    segbackcmd="$teeseg_name."
    echo "use original background for segmentation."
fi

if [ $branch1 == "reid" ]; then
    branch1crop="\"/opt/xilinx/share/ivas/aibox-reid/crop.json\""
    branch1model="\"/opt/xilinx/share/ivas/aibox-reid/reid.json\""
    branch1draw="\"/opt/xilinx/share/ivas/aibox-reid/draw_reid.json\""
    echo "branch 1: use reid"
elif [ $branch1 == "openpose" ]; then
    branch1crop="\"/opt/xilinx/share/ivas/cmpk/openpose/crop.json\""
    branch1model="\"/opt/xilinx/share/ivas/cmpk/openpose/openpose.json\""
    branch1draw="\"/opt/xilinx/share/ivas/cmpk/openpose/draw_pose.json\""
    echo "branch 1: use openopse"
else
    echo "branch 1: unsported model: $branch1 [(reid), openpose]"
    exit 2
fi


echo | modetest -M xlnx -D b0000000.v_mix -s 52@40:3840x2160@NV16
gst-launch-1.0 \
    $input_source \
    ! tee name=$tee1_name  \
        ! queue \
        ! ivas_xmultisrc kconfig=$conf_pre_onlyresize  \
        ! queue ! ivas_xfilter name=refinedet kernels-config="/opt/xilinx/share/ivas/aibox-reid/refinedet.json"  \
        ! queue ! ivas_xfilter name=crop kernels-config=$branch1crop  \
        ! queue ! ivas_xfilter kernels-config=$branch1model \
        ! ima.sink_master ivas_xmetaaffixer name=ima ima.src_master ! fakesink  \
    $tee1_name. \
    ! queue \
    ! ima.sink_slave_0 ima.src_slave_0  \
    ! queue ! ivas_xfilter kernels-config=$branch1draw  \
    ! queue ! ivas_xfilter kernels-config=$conf_pp1_status    \
    ! queue ! ivas_xfilter kernels-config=$conf_pp1_recordfps \
    ! queue ! kmssink bus-id=b0000000.v_mix plane-id=34 render-rectangle="<0,1080,1920,1080>" show-preroll-frame=false sync=false \
    \
    $tee2_cmd  \
        ! queue ! ivas_xmultisrc kconfig=$conf_pre_onlyresize  \
        ! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch2/dpu_yolo2.json"  \
        ! imacar.sink_master ivas_xmetaaffixer name=imacar imacar.src_master ! fakesink  \
    $tee2_name. \
        ! queue \
        ! imacar.sink_slave_0 imacar.src_slave_0  \
        ! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch2/drawbox.json"  \
        ! queue ! ivas_xfilter kernels-config=$conf_pp2_status    \
        ! queue ! ivas_xfilter kernels-config=$conf_pp2_recordfps  \
        ! queue ! kmssink bus-id=b0000000.v_mix plane-id=36 render-rectangle="<1920,1080,1920,1080>" show-preroll-frame=false sync=false \
    \
    $teeseg_cmd  \
        ! queue ! ivas_xmultisrc kconfig=$conf_pre_onlyresize  \
        ! queue ! ivas_xfilter kernels-config=$conf_dpu_seg  \
        ! imaseg.sink_master ivas_xmetaaffixer name=imaseg imaseg.src_master ! fakesink  \
    $segbackcmd \
        ! queue \
        ! imaseg.sink_slave_0 imaseg.src_slave_0  \
        ! queue ! ivas_xfilter kernels-config=$conf_draw_seg  \
        ! queue ! kmssink bus-id=b0000000.v_mix plane-id=35 render-rectangle="<0,0,1920,1080>" show-preroll-frame=false sync=false \
    \
    multifilesrc location="/home/petalinux/videos/back_logo.nv12.h264" \
    ! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12 ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/cmpk/analysis/4K/drawPower.json"  ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/cmpk/analysis/4K/drawTemp.json" ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/cmpk/analysis/4K/drawPLTemp.json" ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/cmpk/analysis/4K/drawfpsB1.json" ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/cmpk/analysis/4K/drawfpsB2.json" ! queue \
    ! kmssink bus-id=b0000000.v_mix plane-id=37 render-rectangle="<1920,0,1920,1080>" show-preroll-frame=false sync=false \
    