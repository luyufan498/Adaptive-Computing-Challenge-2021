#! /bin/sh
video=${1}
echo "use video:"\"${video}\" 
echo | modetest -M xlnx -D b0000000.v_mix -s 52@40:3840x2160@NV16
gst-launch-1.0 \
    multifilesrc location=\"${video}\" \
    ! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12 ! queue \
    ! tee name=maintee1  ! queue \
        ! ivas_xmultisrc kconfig="/opt/xilinx/share/ivas/aibox-reid/ped_pp.json"  \
        ! queue ! ivas_xfilter name=refinedet kernels-config="/opt/xilinx/share/ivas/aibox-reid/refinedet.json"  \
        ! queue ! ivas_xfilter name=crop kernels-config="/opt/xilinx/share/ivas/aibox-reid/crop.json"  \
        ! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/aibox-reid/reid.json" \
        ! ima.sink_master ivas_xmetaaffixer name=ima ima.src_master ! fakesink  \
    maintee1. ! queue \
    ! ima.sink_slave_0 ima.src_slave_0  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/aibox-reid/draw_reid.json"  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch1/drawPipelinestatus.json"  \
    ! queue\
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch1/fpsbranch1.json"  \
    ! queue \
    ! kmssink bus-id=b0000000.v_mix plane-id=34 render-rectangle="<0,1080,1920,1080>" show-preroll-frame=false sync=false \
    \
    maintee1. \
        ! queue ! ivas_xmultisrc kconfig="/opt/xilinx/share/ivas/aibox-reid/ped_pp.json"  \
        ! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/aibox-reid/dpu_seg.json"  \
        ! imaseg.sink_master ivas_xmetaaffixer name=imaseg imaseg.src_master ! fakesink  \
    maintee1. ! queue   \
        ! imaseg.sink_slave_0 imaseg.src_slave_0  \
        ! queue \
        ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawSegmentation.json"  \
        ! queue\
        ! kmssink bus-id=b0000000.v_mix plane-id=35 render-rectangle="<0,0,1920,1080>" show-preroll-frame=false sync=false \
    \
    maintee1. \
        ! queue ! ivas_xmultisrc kconfig="/opt/xilinx/share/ivas/aibox-reid/ped_pp.json"  \
        ! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch2/dpu_yolo2.json"  \
        ! imacar.sink_master ivas_xmetaaffixer name=imacar imacar.src_master ! fakesink  \
    maintee1. ! queue\
        ! imacar.sink_slave_0 imacar.src_slave_0  \
        ! queue \
        ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch2/drawbox.json"  \
        ! queue\
        ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch2/drawPipelinestatus.json"  \
        ! queue\
        ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch2/fpsbranch2.json"  \
        ! queue\
        ! kmssink bus-id=b0000000.v_mix plane-id=36 render-rectangle="<1920,1080,1920,1080>" show-preroll-frame=false sync=false \
    \
    multifilesrc location="/home/petalinux/videos/bg2.nv12.h264" \
    ! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawPower.json"  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawTemp.json" \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawPLTemp.json" \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/branch1/drawfpsB1.json" \
    ! kmssink bus-id=b0000000.v_mix plane-id=37 render-rectangle="<1920,0,1920,1080>" show-preroll-frame=false sync=false \
    