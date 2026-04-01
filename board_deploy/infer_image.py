import argparse
from pathlib import Path
from typing import List, Optional, Sequence, Tuple

import cv2
import numpy as np
from ais_bench.infer.interface import InferSession


COCO_NAMES = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
    "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
    "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
    "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
    "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
    "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork",
    "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli",
    "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch", "potted plant",
    "bed", "dining table", "toilet", "tv", "laptop", "mouse", "remote", "keyboard",
    "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book",
    "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush",
]


def parse_classes(text: str) -> Optional[List[int]]:
    if not text:
        return None
    items = [x.strip() for x in text.split(",") if x.strip()]
    if not items:
        return None
    return [int(x) for x in items]


def preprocess(image: np.ndarray, imgsz: int) -> np.ndarray:
    img = cv2.resize(image, (imgsz, imgsz))
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
    chw = np.transpose(img, (2, 0, 1))[None, ...]
    return np.ascontiguousarray(chw, dtype=np.float32)


def decode_output(raw: np.ndarray) -> np.ndarray:
    arr = np.asarray(raw, dtype=np.float32)
    if arr.ndim != 3:
        raise ValueError(f"Unexpected output rank: {arr.shape}")
    if arr.shape[1] == 84:
        return arr[0].T
    if arr.shape[2] == 84:
        return arr[0]
    raise ValueError(f"Unexpected output shape: {arr.shape}, expected 1x84x8400 or 1x8400x84")


def postprocess(
    pred: np.ndarray,
    orig_w: int,
    orig_h: int,
    imgsz: int,
    conf_thres: float,
    iou_thres: float,
    class_filter: Optional[Sequence[int]],
) -> List[Tuple[int, int, int, int, int, float]]:
    boxes = pred[:, :4]
    scores = pred[:, 4:]
    cls_ids = np.argmax(scores, axis=1)
    confs = np.max(scores, axis=1)

    keep = confs >= conf_thres
    if class_filter:
        keep &= np.isin(cls_ids, np.array(class_filter, dtype=np.int32))

    boxes = boxes[keep]
    cls_ids = cls_ids[keep]
    confs = confs[keep]
    if len(boxes) == 0:
        return []

    xyxy = np.zeros_like(boxes)
    xyxy[:, 0] = boxes[:, 0] - boxes[:, 2] / 2.0
    xyxy[:, 1] = boxes[:, 1] - boxes[:, 3] / 2.0
    xyxy[:, 2] = boxes[:, 0] + boxes[:, 2] / 2.0
    xyxy[:, 3] = boxes[:, 1] + boxes[:, 3] / 2.0

    xyxy[:, [0, 2]] *= (orig_w / float(imgsz))
    xyxy[:, [1, 3]] *= (orig_h / float(imgsz))

    xyxy[:, [0, 2]] = np.clip(xyxy[:, [0, 2]], 0, orig_w - 1)
    xyxy[:, [1, 3]] = np.clip(xyxy[:, [1, 3]], 0, orig_h - 1)

    nms_boxes = []
    for b in xyxy:
        x1, y1, x2, y2 = b
        nms_boxes.append([float(x1), float(y1), float(x2 - x1), float(y2 - y1)])

    idxs = cv2.dnn.NMSBoxes(nms_boxes, confs.tolist(), conf_thres, iou_thres)
    if len(idxs) == 0:
        return []

    out = []
    for i in np.array(idxs).reshape(-1):
        x1, y1, x2, y2 = xyxy[i].astype(int).tolist()
        out.append((x1, y1, x2, y2, int(cls_ids[i]), float(confs[i])))
    return out


def draw_boxes(image: np.ndarray, detections: Sequence[Tuple[int, int, int, int, int, float]]) -> np.ndarray:
    out = image.copy()
    for x1, y1, x2, y2, cls_id, conf in detections:
        cv2.rectangle(out, (x1, y1), (x2, y2), (0, 255, 0), 2)
        name = COCO_NAMES[cls_id] if 0 <= cls_id < len(COCO_NAMES) else str(cls_id)
        label = f"{name}:{conf:.2f}"
        cv2.putText(out, label, (x1, max(0, y1 - 8)), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 255, 0), 2)
    return out


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="YOLO OM inference with ais_bench Python API")
    parser.add_argument("--model", required=True, help="Path to .om model")
    parser.add_argument("--image", required=True, help="Path to input image")
    parser.add_argument("--output", required=True, help="Path to output image")
    parser.add_argument("--device", type=int, default=0, help="NPU device id")
    parser.add_argument("--imgsz", type=int, default=640, help="Inference image size")
    parser.add_argument("--conf", type=float, default=0.18, help="Confidence threshold")
    parser.add_argument("--iou", type=float, default=0.50, help="NMS IoU threshold")
    parser.add_argument("--classes", default="", help="Class filter, comma-separated, e.g. 0,1,2,3,5,7")
    parser.add_argument("--save-raw", default="", help="Optional path to save raw output tensor .bin")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    image_path = Path(args.image)
    model_path = Path(args.model)
    output_path = Path(args.output)

    if not image_path.exists():
        raise FileNotFoundError(f"image not found: {image_path}")
    if not model_path.exists():
        raise FileNotFoundError(f"model not found: {model_path}")

    image = cv2.imread(str(image_path))
    if image is None:
        raise RuntimeError(f"cv2.imread failed: {image_path}")
    h0, w0 = image.shape[:2]

    inp = preprocess(image, args.imgsz)
    class_filter = parse_classes(args.classes)

    session = InferSession(args.device, str(model_path))
    try:
        pred_raw = session.infer([inp], mode="static")[0]
        pred = decode_output(pred_raw)

        if args.save_raw:
            Path(args.save_raw).parent.mkdir(parents=True, exist_ok=True)
            np.asarray(pred_raw, dtype=np.float32).tofile(args.save_raw)
            print(f"raw output saved: {args.save_raw}")

        detections = postprocess(
            pred=pred,
            orig_w=w0,
            orig_h=h0,
            imgsz=args.imgsz,
            conf_thres=args.conf,
            iou_thres=args.iou,
            class_filter=class_filter,
        )
        rendered = draw_boxes(image, detections)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        cv2.imwrite(str(output_path), rendered)
        print(f"detections: {len(detections)}")
        print(f"saved: {output_path}")
    finally:
        session.free_resource()


if __name__ == "__main__":
    main()
