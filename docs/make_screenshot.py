"""Regenerate docs/demo.png (story played to the end) with headless Chrome."""
import pathlib, subprocess, tempfile

root = pathlib.Path(__file__).resolve().parent.parent
chrome = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
profile = pathlib.Path(tempfile.gettempdir()) / "echo_shot_profile"
url = (root / "index.html").as_uri() + "?autoplay"
common = [chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", f"--user-data-dir={profile}",
          "--window-size=1440,1080", "--virtual-time-budget=20000", "--force-prefers-reduced-motion"]
out = root / "docs" / "demo.png"
subprocess.run(common + [f"--screenshot={out}", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("saved" if out.exists() else "failed", out)

# Also dump the final DOM so the story's end state can be checked
dom = subprocess.run(common + ["--dump-dom", url], capture_output=True, text=True, encoding="utf-8").stdout
import re
for key in ("mKb", "mLearned", "mRate", "mOpen"):
    m = re.search(rf'id="{key}">([^<]*)<', dom)
    print(key, m.group(1) if m else "?")
print("learned answer shown to customer #2:", "learned from the team" in dom)
