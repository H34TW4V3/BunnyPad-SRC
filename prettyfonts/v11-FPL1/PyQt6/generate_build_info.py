#!/usr/bin/env python3
"""
Generate _build_info.py with compile-time git state.
Run this before building/packaging BunnyPad.
"""

import subprocess
import sys
import re
from datetime import datetime
from pathlib import Path

def is_git_dirty() -> bool:
    """Check if repo has uncommitted changes outside languages/."""
    try:
        status_cmd = ["git", "--no-optional-locks", "status", "-uno", "--porcelain"]
        status_output = subprocess.check_output(status_cmd, stderr=subprocess.DEVNULL, text=True)
        
        diff_cmd = ["git", "diff-index", "--name-only", "HEAD"]
        diff_output = subprocess.check_output(diff_cmd, stderr=subprocess.DEVNULL, text=True)
        
        combined_lines = status_output.splitlines() + diff_output.splitlines()
        
        if not combined_lines:
            return False

        ignore_pattern = re.compile(r'^(?:.. )?languages/')
        
        for line in combined_lines:
            line = line.strip()
            if not line:
                continue
            if not ignore_pattern.match(line):
                return True
                
        return False
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def get_git_commit() -> str:
    """Get current git commit hash."""
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"],
            stderr=subprocess.DEVNULL, text=True
        ).strip()
    except:
        return "unknown"

def main():
    script_dir = Path(__file__).parent.resolve()
    output_path = script_dir / "_build_info.py"
    
    dirty = is_git_dirty()
    commit = get_git_commit()
    timestamp = datetime.utcnow().isoformat() + "Z"
    
    content = f'''# Auto-generated at build time - DO NOT EDIT
COMPILED_DIRTY = {dirty}
GIT_COMMIT = "{commit}"
COMPILE_TIME = "{timestamp}"
'''
    
    with open(output_path, 'w') as f:
        f.write(content)
    
    print(f"Generated {output_path}")
    print(f"  COMPILED_DIRTY = {dirty}")
    print(f"  GIT_COMMIT = {commit}")
    print(f"  COMPILE_TIME = {timestamp}")

if __name__ == "__main__":
    main()
