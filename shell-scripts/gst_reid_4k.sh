#! /bin/sh
video=${1}
echo "use video:"\"${video}\" 
echo | modetest -M xlnx -D b0000000.v_mix -s 52@40:3840x2160@NV16
gst-launch-1.0 \
    multifilesrc location=\"${video}\" \
    ! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12  \
    ! tee name=maintee1  ! queue \
        ! ivas_xmultisrc kconfig="/opt/xilinx/share/ivas/aibox-reid/ped_pp.json"  \
        ! queue ! ivas_xfilter name=refinedet kernels-config="/opt/xilinx/share/ivas/aibox-reid/refinedet.json"  \
        ! queue ! ivas_xfilter name=crop kernels-config="/opt/xilinx/share/ivas/aibox-reid/crop.json"  \
        ! queue ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/aibox-reid/reid.json" \
        ! ima.sink_master ivas_xmetaaffixer name=ima ima.src_master ! fakesink  \
    maintee1. ! queue max-size-buffers=2 leaky=0 \
    ! ima.sink_slave_0 ima.src_slave_0  \
    ! queue \
            ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/aibox-reid/draw_reid.json"  \
            ! queue \
            ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawPower.json"  \
            ! queue\
            ! kmssink bus-id=b0000000.v_mix plane-id=35 render-rectangle="<0,0,1920,1080>" show-preroll-frame=false sync=false \
