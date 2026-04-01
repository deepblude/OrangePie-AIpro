#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 5 ]; then
  echo "Usage: bash convert_to_om.sh <onnx_path> <soc_version> <input_name> <input_shape> <output_prefix>"
  echo "Example: bash convert_to_om.sh /home/HwHiAiUser/best.onnx Ascend310B4 images 1,3,640,640 /home/HwHiAiUser/best"
  exit 1
fi

ONNX_PATH="$1"
SOC_VERSION="$2"
INPUT_NAME="$3"
INPUT_SHAPE="$4"
OUTPUT_PREFIX="$5"

if [[ "$ONNX_PATH" != /* ]]; then
  ONNX_PATH="$(pwd)/${ONNX_PATH}"
fi

if [[ "$OUTPUT_PREFIX" == *.om ]]; then
  OUTPUT_PREFIX="${OUTPUT_PREFIX%.om}"
fi

if [ ! -f "$ONNX_PATH" ]; then
  echo "ONNX file not found: $ONNX_PATH"
  exit 2
fi

set +u
source /usr/local/Ascend/ascend-toolkit/set_env.sh
set -u

if ! command -v atc >/dev/null 2>&1; then
  echo "atc command not found after source set_env.sh"
  exit 3
fi

# Some environments still miss tbe in PYTHONPATH when invoked via non-login ssh.
if ! python3 -c "import tbe" >/dev/null 2>&1; then
  CANN_BASE="/usr/local/Ascend/ascend-toolkit/latest"
  for p in \
    "${CANN_BASE}/python/site-packages" \
    "${CANN_BASE}/toolkit/python/site-packages" \
    "${CANN_BASE}/opp/built-in/op_impl/ai_core/tbe"; do
    if [ -d "$p" ]; then
      export PYTHONPATH="$p:${PYTHONPATH:-}"
    fi
  done
fi

if ! python3 -c "import tbe" >/dev/null 2>&1; then
  echo "Python cannot import tbe after set_env.sh. Please check CANN toolkit installation completeness."
  echo "Try on board: source /usr/local/Ascend/ascend-toolkit/set_env.sh && python3 -c 'import tbe; print(tbe.__file__)'"
  exit 4
fi

atc --framework=5 \
    --model="${ONNX_PATH}" \
    --input_shape="${INPUT_NAME}:${INPUT_SHAPE}" \
    --output="${OUTPUT_PREFIX}" \
    --soc_version="${SOC_VERSION}"

echo "OM generated: ${OUTPUT_PREFIX}.om"
