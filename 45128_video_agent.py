import os
import subprocess
from PIL import Image, ImageDraw
from core.logger import log


class VideoAgent:
    def __init__(self, base_dir: str):
        self.base_dir = base_dir
        os.makedirs(self.base_dir, exist_ok=True)

    def _ffmpeg(self):
        try:
            subprocess.check_output(
                ["ffmpeg", "-version"], stderr=subprocess.STDOUT, text=True)
            return True
        except Exception:
            return False

    def generate(self, prompt: str, frames: int = 18, fps: int = 6):
        frame_dir = os.path.join(self.base_dir, "frames")
        os.makedirs(frame_dir, exist_ok=True)
        prompt = prompt or "video"
        for i in range(frames):
            img = Image.new("RGB", (640, 360), (0, 0, 0))
            d = ImageDraw.Draw(img)
            d.text((18,
                    18),
                   f"SOVEREIGN CORE\n{i + 1}/{frames}\n{prompt[:120]}",
                   fill=(255,
                         255,
                         255))
            img.save(os.path.join(frame_dir, f"f{i:03d}.png"))
        out_mp4 = os.path.join(self.base_dir, "video.mp4")
        if self._ffmpeg():
            cmd = [
                "ffmpeg",
                "-y",
                "-framerate",
                str(fps),
                "-i",
                os.path.join(
                    frame_dir,
                    "f%03d.png"),
                "-pix_fmt",
                "yuv420p",
                out_mp4]
            log("VideoAgent: rendering mp4 via ffmpeg")
            subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True)
            return {
                "status": "video_generated",
                "output": out_mp4,
                "frames": frames,
                "fps": fps}
        return {
            "status": "frames_generated",
            "frame_dir": frame_dir,
            "frames": frames,
            "fps": fps,
            "hint": "install ffmpeg"}
