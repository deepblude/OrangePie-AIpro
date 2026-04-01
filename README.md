# YOLO PC -> OrangePi AIpro (Engineering Edition)

这个版本的目标是：把你已经跑通的学习流程，固化成可重复执行的工程脚本。

## 1. 项目结构

```text
yolo_pc_to_aipro/
├─ project_config.json            # 统一配置（你主要改这个）
├─ project_config.example.json    # 配置模板
├─ scripts/
│  ├─ common.ps1
│  ├─ pc_export_onnx.ps1          # PC: 训练/导出 ONNX（固定 opset=13）
│  ├─ pc_upload_onnx.ps1          # PC: 上传 ONNX 到板端
│  ├─ pc_sync_board_scripts.ps1   # PC: 同步板端脚本并建目录
│  ├─ pc_remote_convert.ps1       # PC: 远程调用板端 ATC 转 OM
│  ├─ pc_remote_infer.ps1         # PC: 远程调用板端真实图片推理
│  ├─ pc_pull_result.ps1          # PC: 拉回 result.jpg
│  └─ run_end2end.ps1             # PC: 一键串联（导出+上传+转换+推理+拉回）
├─ pc_train/
│  └─ train_and_export.py         # 支持 --opset 和 --best-pt
├─ board_convert/
│  └─ convert_to_om.sh
└─ board_deploy/
   ├─ infer_image.py
   └─ run_infer.sh
```

## 2. 首次配置

编辑 `project_config.json`，至少确认这些字段：

- `board.ip`
- `board.user`
- `board.soc_version` (你当前是 `Ascend310B4`)
- `board.workdir` (板端项目目录)
- `board.onnx_path`、`board.om_path`
- `inference.image_path`、`inference.result_path`

## 3. PC 环境准备

在 `pc_train` 虚拟环境安装依赖（你之前已经做过可跳过）：

```powershell
cd .\pc_train
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -U pip
pip install -r requirements.txt
cd ..
```

## 4. 一键执行（推荐）

在项目根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_end2end.ps1
```

如果你已经有 ONNX，不想重新训练导出：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_end2end.ps1 -SkipExport
```

## 5. 分步执行（便于排错）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\pc_export_onnx.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\pc_upload_onnx.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\pc_remote_convert.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\pc_remote_infer.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\pc_pull_result.ps1
```

## 6. 板端手动执行（备用）

```bash
cd /home/HwHiAiUser/yolo_pc_to_aipro
bash board_convert/convert_to_om.sh /home/HwHiAiUser/best.onnx Ascend310B4 images 1,3,640,640 /home/HwHiAiUser/best
bash board_deploy/run_infer.sh --model /home/HwHiAiUser/best.om --image /home/HwHiAiUser/test.jpg --output /home/HwHiAiUser/result.jpg --device 0 --imgsz 640 --conf 0.18 --iou 0.50 --classes 0,1,2,3,5,7
```

## 7. 关键坑位（本项目已规避）

1. ONNX `opset`  
必须用 `opset=13`（已在脚本固化），否则 CANN 可能报不支持的算子版本。

2. `atc` 输入路径  
优先用绝对路径，不要依赖 `~` 缩写。

3. `ais_bench` 入口  
命令不可用时可用 `python3 -m ais_bench`；本工程默认走 Python API `InferSession`，绕过 files 模式的分片/偏移问题。

4. Linux 权限策略  
遇到 security_error 时，检查输入/模型权限，建议：
`chmod 640 <file>`，目录建议 `750`。

5. 命令换行粘贴  
尽量运行脚本文件，不要手敲超长多行命令，避免出现 `>` 挂起和缩进异常。
