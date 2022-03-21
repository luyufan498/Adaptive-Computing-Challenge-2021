echo | modetest -M xlnx -D b0000000.v_mix -s 52@40:3840x2160@NV16
gst-launch-1.0 \
    multifilesrc location="/home/petalinux/videos/facedetect.nv12.h264" \
    ! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12 ! queue \
    ! tee name=maintee1  ! queue \
        ! ivas_xmultisrc kconfig="/opt/xilinx/share/ivas/cmpk/preprocess/resize_cmpk.json"  \
        ! queue ! ivas_xfilter name=refinedet kernels-config="/opt/xilinx/share/ivas/aibox-reid/refinedet.json"  \
        ! ima.sink_master ivas_xmetaaffixer name=ima ima.src_master ! fakesink  \
    maintee1. ! queue \
    ! ima.sink_slave_0 ima.src_slave_0  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/aibox-reid/draw_reid.json"  \
    ! queue \
    ! kmssink bus-id=b0000000.v_mix plane-id=34 render-rectangle="<0,1080,1920,1080>" show-preroll-frame=false sync=false 