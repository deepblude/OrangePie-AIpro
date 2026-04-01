#!/usr/bin/env bash
set -euo pipefail

MODEL=""
IMAGE=""
OUTPUT=""
DEVICE="0"
IMGSZ="640"
CONF="0.18"
IOU="0.50"
CLASSES=""
SAVE_RAW=""

usage() {
  echo "Usage: bash run_infer.sh --model <best.om> --image <input.jpg> --output <result.jpg> [--device 0] [--imgsz 640] [--conf 0.18] [--iou 0.50] [--classes 0,1,2,3,5,7] [--save-raw /tmp/out.bin]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --device) DEVICE="$2"; shift 2 ;;
    --imgsz) IMGSZ="$2"; shift 2 ;;
    --conf) CONF="$2"; shift 2 ;;
    --iou) IOU="$2"; shift 2 ;;
    --classes) CLASSES="$2"; shift 2 ;;
    --save-raw) SAVE_RAW="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$MODEL" ] || [ -z "$IMAGE" ] || [ -z "$OUTPUT" ]; then
  usage
  exit 1
fi

set +u
source /usr/local/Ascend/ascend-toolkit/set_env.sh
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CMD=(python3 "${SCRIPT_DIR}/infer_image.py"
  --model "$MODEL"
  --image "$IMAGE"
  --output "$OUTPUT"
  --device "$DEVICE"
  --imgsz "$IMGSZ"
  --conf "$CONF"
  --iou "$IOU"
)

if [ -n "$CLASSES" ]; then
  CMD+=(--classes "$CLASSES")
fi
if [ -n "$SAVE_RAW" ]; then
  CMD+=(--save-raw "$SAVE_RAW")
fi

"${CMD[@]}"
