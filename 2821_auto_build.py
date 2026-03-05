import tarfile, os

print("🚀 PAI6 Autonomous Exporter")

base = "."
archive = "pai6_full_autobuild.tar.gz"

with tarfile.open(archive, "w:gz") as tar:
    tar.add(base, arcname="pai6")

print("✅ Package created:", archive)
