"""Render real native pill captures. Usage: render-video.py LIGHT_DIR DARK_DIR.
Each directory contains numbered app-window captures and timings.json (milliseconds).
Capture the documentation preview's Cmd-5 window with CUA, in each appearance.
Requires Pillow and ffmpeg. No GUI interaction or guard startup.
"""
import bisect, json, subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parents[2]
personal='--personal' in sys.argv
output=root/('docs/media/agent-guard-x-personal.mp4' if personal else 'docs/media/agent-guard-x.mp4')
fonts='/System/Library/Fonts/SFNS.ttf'
process=subprocess.Popen(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','rawvideo','-pixel_format','rgb24','-video_size','1080x1080','-framerate','30','-i','-','-an','-c:v','libx264','-preset','medium','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(output)],stdin=subprocess.PIPE)
for mode,directory in zip(['Light','Dark'],sys.argv[1:3]):
    directory=Path(directory)
    times=json.loads((directory/'timings.json').read_text())
    for frame in range(90):
        index=min(len(times)-1,bisect.bisect_left(times,times[0]+frame/30*1000))
        im=Image.open(directory/f'{index:04}.png').convert('RGB')
        # Strip only the title bar: the remaining square is the actual native view.
        w,h=im.size
        im=im.crop((0,h-w,w,h)).resize((1080,1080),Image.Resampling.LANCZOS)
        draw=ImageDraw.Draw(im)
        draw.text((540,55),('agent guard' if personal else 'Agent Guard'),font=ImageFont.truetype(fonts,54),fill='white',anchor='mt')
        draw.text((540,127),('made this so my agents can keep going' if personal else 'Step away. Keep agents working.'),font=ImageFont.truetype(fonts,27),fill=(228,229,238),anchor='mt')
        if not personal: draw.text((540,986),mode+' appearance',font=ImageFont.truetype(fonts,25),fill=(235,235,245),anchor='mt')
        if mode=='Light' and frame==30: im.save(root/('docs/media/poster-personal.jpg' if personal else 'docs/media/poster.jpg'),quality=94)
        process.stdin.write(im.tobytes())
process.stdin.close()
if process.wait(): raise SystemExit('ffmpeg failed')
print(output)
