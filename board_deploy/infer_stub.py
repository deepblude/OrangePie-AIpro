"""
Deprecated entrypoint.
Use infer_image.py instead:

python3 infer_image.py --model /home/HwHiAiUser/best.om --image /home/HwHiAiUser/test.jpg --output /home/HwHiAiUser/result.jpg
"""

from infer_image import main


if __name__ == "__main__":
    main()
