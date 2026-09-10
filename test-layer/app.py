import subprocess
import json


def run_cmd(cmd):
    """Run a shell command and return stdout, stderr, and return code."""
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    return {
        "command": " ".join(cmd),
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
        "returncode": result.returncode,
        "passed": result.returncode == 0,
    }


def handler(event, context):
    checks = []

    # 1. ffmpeg version
    checks.append(run_cmd(["ffmpeg", "-version"]))

    # 2. ffprobe version
    checks.append(run_cmd(["ffprobe", "-version"]))

    # 3. List supported formats
    checks.append(run_cmd(["ffmpeg", "-formats", "-hide_banner"]))

    # 4. List supported codecs
    checks.append(run_cmd(["ffmpeg", "-codecs", "-hide_banner"]))

    # 5. Generate 1 second of silence and verify output
    checks.append(run_cmd([
        "ffmpeg", "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
        "-t", "1", "-c:a", "pcm_s16le", "/tmp/test_silence.wav",
    ]))

    # 6. Probe the generated file to confirm it's valid
    checks.append(run_cmd([
        "ffprobe", "-v", "quiet", "-print_format", "json",
        "-show_format", "-show_streams", "/tmp/test_silence.wav",
    ]))

    # 7. Generate a 1-second test video (color bars)
    checks.append(run_cmd([
        "ffmpeg", "-y", "-f", "lavfi", "-i",
        "color=c=blue:s=320x240:d=1:r=25",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "/tmp/test_video.mp4",
    ]))

    # 8. Probe the generated video
    checks.append(run_cmd([
        "ffprobe", "-v", "quiet", "-print_format", "json",
        "-show_format", "-show_streams", "/tmp/test_video.mp4",
    ]))

    all_passed = all(c["passed"] for c in checks)
    summary = {
        "all_passed": all_passed,
        "total": len(checks),
        "passed": sum(1 for c in checks if c["passed"]),
        "failed": sum(1 for c in checks if not c["passed"]),
    }

    return {
        "statusCode": 200 if all_passed else 500,
        "body": json.dumps({"summary": summary, "checks": checks}, indent=2),
    }
