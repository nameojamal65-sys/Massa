import threading
import time
import json
from core.logger import log
from orchestrator.routing import wants_diffusion
from pipelines.code_pipeline import CodePipeline
from pipelines.video_pipeline import VideoPipeline
from pipelines.voice_pipeline import VoicePipeline
from pipelines.automation_pipeline import AutomationPipeline
from orchestrator.cluster_manager import ClusterManager
from core.config import Settings
from commercial.metering import inc


class Scheduler:
    def __init__(self, task_manager):
        self.tm = task_manager
        self._stop = threading.Event()
        self._t = None
        self.code = CodePipeline()
        self.video = VideoPipeline()
        self.voice = VoicePipeline()
        self.auto = AutomationPipeline()
        self.cluster = ClusterManager()
        self.cluster.register("worker1", Settings.WORKER_DEFAULT)

    def start(self):
        if self._t and self._t.is_alive():
            return
        self._stop.clear()
        self._t = threading.Thread(target=self._loop, daemon=True)
        self._t.start()
        log("Scheduler started")

    def _exec_local(self, ttype, payload):
        if ttype == "code":
            return self.code.run(payload)
        if ttype == "video":
            return self.video.run(payload)
        if ttype == "voice":
            return self.voice.run(payload)
        if ttype == "automation":
            return self.auto.run(payload)
        return {"error": "unknown task type"}

    def _loop(self):
        while not self._stop.is_set():
            tasks = self.tm.list()
            for tid, t in tasks.items():
                if t["status"] != "queued":
                    continue
                payload = t["payload"]
                ttype = payload.get("type")
                tenant = payload.get("tenant", "default")
                self.tm.update(tid, status="running")
                try:
                    # Auto-route diffusion video to worker
                    gpu = False
                    if ttype == "video" and Settings.ROLE == "control" and wants_diffusion(
                            payload.get("prompt", "")):
                        res = self.cluster.dispatch(
                            "video", dict(payload, task_id=tid))
                        gpu = True
                    else:
                        res = self._exec_local(ttype, payload)

                    # metering
                    inc(tenant, "gpu" if gpu else "job")

                    self.tm.update(tid, status="done", result=res)
                    log(f"Task done {tid} type={ttype} tenant={tenant} gpu={gpu}")
                except Exception as e:
                    self.tm.update(tid, status="error", error=str(e))
                    log(f"Task error {tid}: {e}", level="ERROR")
            time.sleep(0.25)
