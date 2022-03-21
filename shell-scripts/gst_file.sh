srcfile=$1
filename=$(basename $srcfile)
filename=${filename%%.*}
outputfold="/home/petalinux/videout/"
extension=".h264"

sinkfile=$outputfold$filename$extension

if [ ! -f "$srcfile" ]; then
  echo "the input video does not exsit!"
  exit 0
fi


if [ ! -d $outputfold ]; then
  mkdir $outputfold
fi



gst-launch-1.0 multifilesrc  location=\"$srcfile\" \
! h264parse ! queue ! omxh264dec ! video/x-raw, format=NV12, framerate=30/1 \
! tee name=t  \
    ! queue \
    ! ivas_xmultisrc kconfig="/opt/xilinx/share/ivas/smartcam/myapp/preprocess.json"  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/dpu_yolo2.json"  \
    ! ima.sink_master ivas_xmetaaffixer name=ima ima.src_master \
    ! fakesink  \
t. \
    ! queue \
    ! ivas_xmultisrc kconfig="/opt/xilinx/share/ivas/smartcam/myapp/preprocess_seg.json"  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/dpu_seg.json"  \
    ! ima2.sink_master ivas_xmetaaffixer name=ima2 ima2.src_master ! fakesink  \
t. \
    ! queue max-size-buffers=1 leaky=0 ! ima.sink_slave_0 ima.src_slave_0  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/facedetect/drawresult.json" \
    ! queue  \
    ! ima2.sink_slave_0 ima2.src_slave_0  \
    ! queue \
    ! ivas_xfilter kernels-config="/opt/xilinx/share/ivas/smartcam/myapp/drawSegmentation.json"  \
    ! queue \
    ! ivas_xroigen roi-type=1 roi-qp-delta=-10 roi-max-num=10 \
    ! queue \
    ! omxh264enc  qp-mode=1 control-rate=low-latency target-bitrate=3000 gop-length=60 gop-mode=low-delay-p gdr-mode=horizontal cpb-size=200 num-slices=8 periodicity-idr=270 initial-delay=100  filler-data=false min-qp=15  max-qp=40  b-frames=0  low-bandwidth=false \
    ! video/x-h264 , alignment=au \
    ! filesink location=\"$sinkfile\" async=false