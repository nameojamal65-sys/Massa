import subprocess, time

def self_heal():
    while True:
        try:
            subprocess.run(["pip","install","--upgrade","pip"],check=True)
            libs = ["requests","beautifulsoup4","lxml","numpy","sqlite-utils","rich","psutil","uvicorn","fastapi","jinja2","aiofiles","torch","torchvision","torchaudio","transformers","accelerate","diffusers"]
            for lib in libs:
                subprocess.run(["pip","install","--upgrade",lib],check=True)
        except:
            pass
        time.sleep(300)

if __name__=="__main__":
    self_heal()
