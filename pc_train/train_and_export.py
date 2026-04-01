import argparse
from pathlib import Path

from ultralytics import YOLO


def resolve_best_pt(model: YOLO, project: str, name: str) -> Path:
    trainer = getattr(model, "trainer", None)
    if trainer is not None:
        trainer_best = getattr(trainer, "best", None)
        if trainer_best:
            p = Path(str(trainer_best))
            if p.exists():
                return p

        save_dir = getattr(trainer, "save_dir", None)
        if save_dir:
            p = Path(str(save_dir)) / "weights" / "best.pt"
            if p.exists():
                return p

    fallback = Path(project) / name / "weights" / "best.pt"
    if fallback.exists():
        return fallback

    raise FileNotFoundError(
        "best.pt not found. Checked trainer.best, trainer.save_dir/weights/best.pt, "
        f"and fallback path: {fallback}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", default="coco8.yaml")
    parser.add_argument("--model", default="yolov8n.pt")
    parser.add_argument("--imgsz", type=int, default=640)
    parser.add_argument("--epochs", type=int, default=20)
    parser.add_argument("--project", default="runs")
    parser.add_argument("--name", default="learn")
    parser.add_argument("--opset", type=int, default=13)
    parser.add_argument(
        "--best-pt",
        default="",
        help="Skip training and export this best.pt directly if provided",
    )
    return parser.parse_args()


def train_if_needed(args: argparse.Namespace) -> Path:
    if args.best_pt:
        best_pt = Path(args.best_pt)
        if not best_pt.exists():
            raise FileNotFoundError(f"best.pt not found: {best_pt}")
        print(f"Skip train. Use existing best.pt: {best_pt}")
        return best_pt

    model = YOLO(args.model)
    model.train(
        data=args.data,
        imgsz=args.imgsz,
        epochs=args.epochs,
        project=args.project,
        name=args.name,
    )
    return resolve_best_pt(model, args.project, args.name)


def main() -> None:
    args = parse_args()
    best_pt = train_if_needed(args)
    export_model = YOLO(str(best_pt))

    exported = export_model.export(
        format="onnx",
        imgsz=args.imgsz,
        simplify=False,
        opset=args.opset,
    )

    print("Export done.")
    print(f"best.pt: {best_pt}")
    print(f"opset: {args.opset}")
    print(f"onnx: {exported}")


if __name__ == "__main__":
    main()
